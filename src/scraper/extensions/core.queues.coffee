{Status} = require '../CrawlRequest'
storage = require '../QueueManager'
{Extension} = require '../Extension'
RateLimiter = require('limiter').RateLimiter
{RandomId} = require '../util/utils.coffee'

# The Queue Connector establishes a system of queues where each state
# of the CrawlRequest state machine is represented in its own queue.
# It also enriches each request, such that its state transitions
# are propagated to the queuing system automatically.
class QueueConnector extends Extension

  @defaultOpts : () ->
    dbfile : "#{RandomId()}-queue.json"
    statistics:
      interval : 2000

  # @nodoc
  constructor: (opts = {}) ->
    super INITIAL : @apply
    @opts = @merge QueueConnector.defaultOpts(), opts

  # Create a queue system and re-expose in context
  initialize: (context) ->
    super context
    @queue = new storage.QueueManager "#{context.config.basePath()}/#{@opts.dbfile}"
    context.share "queue", @queue
    @stats = setInterval @logStats, @opts.statistics.interval

  shutdown:() ->
    clearInterval @stats

  logStats: =>
    try
      @log.debug? "#{JSON.stringify @queue.statistics()}", tags : ['Statistics']
    catch error
      @log.error? "Error during computation of statistics #{error}"

  # Enrich each request with methods that propagate its
  # state transitions to the queue system
  apply: (request) ->
    @queue.insert request
    request.onChange 'status', (request) =>
      @queue.update(request)

# Process requests that have been SPOOLED for fetching.
# Takes care that concurrency and rate limits are met.
class QueueWorker extends Extension

  @defaultOpts =
    limits : [
        domain : ".*"
        to : 5
        per : 'second'
    ]

  # https://www.npmjs.com/package/simple-rate-limiter
  constructor: (opts = {}) ->
    super SPOOLED : @spool
    @opts = @merge QueueWorker.defaultOpts, opts
    # 'second', 'minute', 'day', or a number of milliseconds

  initialize: (context) ->
    super context
    @queue = context.queue
    @requests = context.requests
    @limits = new RateLimits @opts.limits, @context.log
    @spooler = setInterval @processRequests, 1000

  # @private
  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    @spool @requests[request.id] for request in @queue.spooled()


  spool : (request) ->
    @log.debug? "Scheduling #{request.url()}"
    if @limits.isAllowed request.url()
      request.ready()
    else
      request.state["tsSPOOLED"] = new Date().getTime()

  shutdown: ->
    clearInterval @spooler


class RateLimits

  constructor: (limits =[], @log) ->
    @limits = ({
      pattern : new RegExp(limit.domain,"g")
      limiter: new RateLimiter(limit.to , limit.per)
      to: limit.to
      per:limit.per} for limit in limits)

  isAllowed : (url) ->
    for limit in @limits
      if url.match limit.pattern
        #@log.debug? "#{url} has limit of #{limit.to} per #{limit.per}, #{limit.limiter.getTokensRemaining()} remaining"
        return limit.limiter.tryRemoveTokens 1
    true

# Export a function to create the core plugin with default extensions
module.exports = {
  QueueConnector
  QueueWorker
}