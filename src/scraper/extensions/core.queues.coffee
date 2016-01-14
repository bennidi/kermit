{Status} = require '../CrawlRequest'
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

  @defaultOpts : () ->
    statistics:
      interval : 2000

  # @nodoc
  constructor: (opts = {}) ->
    super INITIAL : @apply
    @opts = @merge QueueConnector.defaultOpts(), opts

  # Create a queue system and re-expose in context
  initialize: (context) ->
    super context
    @queue = context.queue
    statsLogger = () =>
      try
        @log.debug? "#{JSON.stringify @queue.statistics()}", tags : ['Statistics']
      catch error
        @log.error? "Error during computation of statistics", error:error
    if @opts.statistics.interval > 0
      @log.debug? "Statistics enabled at interval #{@opts.statistics.interval}"
      @stats = setInterval statsLogger, @opts.statistics.interval
      @stats.unref()
    ###
    shutdownWatchdog = () =>
      @context.crawler.shutdown() if not @queue.requestsUnfinished()
    @watchdog =  setInterval shutdownWatchdog, 5000
    ###

  # @nodoc
  shutdown:() ->
    clearInterval @stats
    #clearInterval @watchdog

  updateQueue : (request) =>
    @queue.update(request)

  # Enrich each request with methods that propagate its
  # state transitions to the queue system
  apply: (request) ->
    @queue.insert request
    request.onChange 'status', @updateQueue

# Process requests that have been SPOOLED for fetching.
# Takes care that concurrency and rate limits are met.
class QueueWorker extends Extension

  @defaultOpts = () ->
    limits : [
        pattern : ".*"
        to : 5
        per : 'second'
        max : 5
    ]

  # https://www.npmjs.com/package/simple-rate-limiter
  constructor: (opts = {}) ->
    super SPOOLED : @spool
    @opts = _.merge QueueWorker.defaultOpts(), opts, (a, b) -> b.concat a if _.isArray a

    # 'second', 'minute', 'day', or a number of milliseconds

  initialize: (context) ->
    super context
    @queue = context.queue
    @requests = context.requests
    @limits = new RateLimits @opts.limits, @context.log, @queue
    @spooler = setInterval @processRequests, 1000

  # @private
  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    @spool @requests[request.id] for request in @queue.spooled()

  spool : (request) ->
    @log.debug? "Scheduling #{request.url()}"
    if @limits.isAllowed request.url() , @queue
      request.ready()
    else
      request.stamp Status.SPOOLED

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