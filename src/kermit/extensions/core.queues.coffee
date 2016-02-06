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

  # @nodoc
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

  # @nodoc
  initialize: (context) ->
    super context
    @queue = context.queue # Request state is fetched from the queue
    @requests = context.requests # Request object is resolved from shared request map
    @limits = new RateLimits @opts.limits, @context.log, @queue # Rate limiting is applied here
    @spooler = setInterval @processRequests, 100 # Request spooling runs regularly
    @batch = [] # Local batch of requests to be put into READY state

  # This is run at intervals to process waiting requests
  # @private
  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    @proceed @requests[request.id] for request in @localBatch()

  # @nodoc
  localBatch: () ->
    currentBatch = _.filter @batch, (request) -> request.phase is 'SPOOLED'
    if not _.isEmpty currentBatch then currentBatch else @batch = @queue.spooled(100)

  # @nodoc
  proceed : (request) ->
    request.ready() if @limits.isAllowed request.url()

  # Stop the continuous execution of request spooling
  shutdown: ->
    clearInterval @spooler


###
  Wrapper for rate limit configurations passed as options to the {QueueWorker}
  @private
  @nodoc
###
class RateLimits

  constructor: (limits =[], @log, queue) ->
    @limits = (new Limit limitDef, queue for limitDef in limits)

  # Check whether applicable rate limits allow this URL to pass
  isAllowed : (url) ->
    for limit in @limits
      return limit.isAllowed() if limit.matches url
    throw new Error "No limit matched #{url}"

###
  @nodoc
  @private
###
class Limit

  # @nodoc
  constructor: (@def, @queue) ->
    @regex = @def.pattern
    @limiter = new RateLimiter @def.to , @def.per

  # @nodoc
  isAllowed: ->
    @limiter.tryRemoveTokens(1) and @queue.requestsProcessing(@regex) < @def.max

  # @nodoc
  matches: (url) ->
    url.match @regex

module.exports = {
  QueueConnector
  QueueWorker
}