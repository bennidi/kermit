{Status} = require '../CrawlRequest'
storage = require '../QueueManager'
{Extension , ExtensionDescriptor} = require '../Extension'
RateLimiter = require('limiter').RateLimiter

# The Queue Connector establishes a system of queues where each state
# of the CrawlRequest state machine is represented in its own queue.
# It also enriches each request, such that its state transitions
# are propagated to the queuing system automatically.
class QueueConnector extends Extension

  constructor: () ->
    super new ExtensionDescriptor "Queue Connector", [Status.INITIAL]

  # Create a queue system and re-expose in context
  initialize: (context) ->
    super context
    @queue = new storage.QueueManager
    context.queue = @queue

  # Enrich each request with methods that propagate its
  # state transitions to the queue system
  apply: (request) ->
    @queue.trace(request)

# Process requests that have been spooled for fetching.
# Takes care that concurrency and rate limits are met.
class QueueWorker extends Extension

  # https://www.npmjs.com/package/simple-rate-limiter
  constructor: () ->
    super new ExtensionDescriptor "Queue Worker", [Status.SPOOLED]
    # 'second', 'minute', 'day', or a number of milliseconds
    @limiter = new RateLimiter  10 , 'second' # TODO: implement limit per domain

  initialize: (context) ->
    super context
    @queue = context.queue
    @requests = context.requests


  processRequests : () =>
    # Transition SPOOLED requests into READY state unless parallelism threshold is reached
    for request in @queue.spooled()
      if @limitReached()
        break
      else @requests[request.id].ready()
    # Schedule next processing to keep QueueWorker running
    # Otherwise last requests might hang in queue forever
    setTimeout @processRequests, 500 if @queue.requestsRemaining()

  # Schedule request processing for transitioning into READY state
  apply: ->
    process.nextTick @processRequests

  limitReached: () ->
    !@limiter.tryRemoveTokens(1)


# Export a function to create the core plugin with default extensions
module.exports = {
  QueueConnector
  QueueWorker
}