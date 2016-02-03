{Phase} = require '../CrawlRequest'
storage = require '../QueueManager'
{Extension} = require '../Extension'
RateLimiter = require('limiter').RateLimiter
{obj} = require '../util/tools.coffee'
_ = require 'lodash'

# The Queue Connector establishes a system of queues where each state
# of the CrawlRequest state machine is represented in its own queue.
# It also enriches each request, such that its state transitions
# are propagated to the queuing system automatically.
class QueueConnector extends Extension

  # @nodoc
  constructor: () ->
    super INITIAL : @apply

  # Create a queue system and re-expose in context
  initialize: (context) ->
    super context
    @queue = context.queue


  updateQueue : (request) =>
    @queue.update(request)

  # Enrich each request with methods that propagate its
  # state transitions to the queue system
  apply: (request) ->
    @queue.insert request
    request.onChange 'phase', @updateQueue

# Process requests that have been SPOOLED for fetching.
# Takes care that concurrency and rate limits are met.
class QueueWorker extends Extension

  @defaultOpts = () ->
    limits : [
        pattern : /.*/
        to : 5
        per : 'second'
        max : 5
    ]

  # https://www.npmjs.com/package/simple-rate-limiter
  constructor: (opts = {}) ->
    super {}
    @opts = obj.merge QueueWorker.defaultOpts(), opts

    # 'second', 'minute', 'day', or a number of milliseconds

  initialize: (context) ->
    super context
    @queue = context.queue # Request state is fetched from the queue
    @requests = context.requests # Request object is resolved from shared request map
    @limits = new RateLimits @opts.limits, @context.log, @queue # Rate limiting is applied here
    @spooler = setInterval @processRequests, 100 # Request spooling runs regularly
    @batch = [] # Local batch of requests to be put into READY state

  # @private
  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    @proceed @requests[request.id] for request in @localBatch()

  localBatch: () ->
    currentBatch = _.filter @batch, (request) -> request.phase is 'SPOOLED'
    if not _.isEmpty currentBatch then currentBatch else @batch = @queue.spooled(100)

  proceed : (request) ->
    request.ready() if @limits.isAllowed request.url()

  shutdown: ->
    clearInterval @spooler


class RateLimits

  constructor: (limits =[], @log, queue) ->
    @limits = (new Limit limitDef, queue for limitDef in limits)

  isAllowed : (url) ->
    for limit in @limits
      return limit.isAllowed() if limit.matches url
    throw new Error "No limit matched #{url}"

class Limit

  constructor: (@def, @queue) ->
    @regex = @def.pattern
    @limiter = new RateLimiter @def.to , @def.per

  isAllowed: ->
    @limiter.tryRemoveTokens(1) and @queue.requestsProcessing(@regex) < @def.max

  matches: (url) ->
    url.match @regex
# Export a function to create the core plugin with default extensions
module.exports = {
  QueueConnector
  QueueWorker
}