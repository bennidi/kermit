{Status} = require '../CrawlRequest'
storage = require '../QueueManager'
{Extension , ExtensionDescriptor} = require '../Extension'
RateLimiter = require('limiter').RateLimiter
{RandomId} = require '../util/utils.coffee'

# The Queue Connector establishes a system of queues where each state
# of the CrawlRequest state machine is represented in its own queue.
# It also enriches each request, such that its state transitions
# are propagated to the queuing system automatically.
class QueueConnector extends Extension

  @defaultOpts : () ->
    dbfile : "#{RandomId()}-queue.json"

  constructor: (opts = {}) ->
    super INITIAL : @apply
    @opts = Extension.mergeOptions QueueConnector.defaultOpts(), opts

  # Create a queue system and re-expose in context
  initialize: (context) ->
    super context
    @queue = new storage.QueueManager "#{context.config.basePath()}/#{@opts.dbfile}"
    context.share "queue", @queue

  # Enrich each request with methods that propagate its
  # state transitions to the queue system
  apply: (request) ->
    @queue.insert request
    # TODO: Use language embedded auto-update feature if available
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
    super SPOOLED : @apply
    @opts = Extension.mergeOptions QueueWorker.defaultOpts, opts
    # 'second', 'minute', 'day', or a number of milliseconds
    @limits = new RateLimits @opts.limits

  initialize: (context) ->
    super context
    @queue = context.queue
    @requests = context.requests

  # @private
  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    for request in @queue.spooled()
      request = @requests[request.id]
      if @limits.isAllowed request.url()
        request.ready()
      else
        request.state["tsSPOOLED"] = new Date().getTime()
        @queue.update request
    # Schedule next processing to keep QueueWorker running
    # Otherwise last requests might hang in queue forever
    setTimeout @processRequests, 500 if @queue.requestsRemaining()

  # Schedule request processing for transitioning into READY state
  apply: ->
    process.nextTick @processRequests

  limitReached: () ->
    !@limiter.tryRemoveTokens(1)


class RateLimits

  constructor: (limits =[]) ->
    @limits = ({ pattern : new RegExp(limit.domain,"g"), limiter: new RateLimiter  limit.to , limit.per} for limit in limits)

  isAllowed : (url) ->
    for limit in @limits
      if url.match limit.pattern and not limit.limiter.tryRemoveTokens 1
        return false
    true

# Export a function to create the core plugin with default extensions
module.exports = {
  QueueConnector
  QueueWorker
}