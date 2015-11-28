Status = require('../CrawlRequest').Status
storage = require '../QueueManager'
extensions = require '../Extension'
Extension = extensions.Extension
ExtensionDescriptor = extensions.ExtensionDescriptor
httpRequest = require 'request'
RateLimiter = require('limiter').RateLimiter

# Adds callbacks to the requests such that each state transition will
# trigger execution of the respective extension point
class RequestExtensionPointConnector extends Extension

  constructor: () ->
    super new ExtensionDescriptor "Request Extension Point Connector", [Status.INITIAL]

  apply: (request) ->
    request.onChange 'status', (state) =>
      @crawler.execute state.status, request

  initialize: (context) ->
    super context
    @crawler = context.crawler

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
    @limiter = new RateLimiter( 10 , 'second');

  initialize: (context) ->
    super context
    @queue = context.queue
    @requests = context.requests

  processRequests : () =>
    for request in @queue.spooled()
      @requests[request.id].ready() if not @limitReached()
    setTimeout @processRequests, 25 if @queue.requestsRemaining()

  # Transition SPOOLED requests into ready state unless parallelism threshold is reached
  # Then wait for next tick and retry
  apply: (request) ->
    process.nextTick @processRequests

  limitReached: () ->
    !@limiter.tryRemoveTokens(1)



# Execute the request and retrieve the result for further processing
class RequestStreamer extends Extension

  @opts =
    userAgent : "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

  constructor: () ->
    super new ExtensionDescriptor "Request Streamer", [Status.READY]

  initialize: (context) ->
    super context

  apply: (crawlRequest) ->
    url = crawlRequest.uri().toString()
    console.log "Scheduled: #{url}"
    crawlRequest.fetching()
    process.nextTick ->
      console.log "Fetching: #{url}"
      httpRequest url, (error, response, body) ->
        if not error and response.statusCode is 200
          crawlRequest.fetched(body, response)
        if error
          crawlRequest.error(error)


# State transition CREATED -> SPOOLED
class Spooler extends Extension

  constructor: ->
    super new ExtensionDescriptor "Spooler", [Status.INITIAL]

  apply: (request) ->
    request.spool()

# Marks requests as completed when the phase processes without error
# State transition FETCHED -> COMPLETED
class Completer extends Extension

  constructor: ->
    super new ExtensionDescriptor "Completer", [Status.FETCHED]

  apply: (request) ->
    request.complete()

# Add capability to lookup a request object by id
# This is necessary to find the living request object for a given persistent state
# because lokijs does not store the entire javascript object
class RequestLookup extends Extension

  constructor: () ->
    super(new ExtensionDescriptor "RequestLookup", [Status.INITIAL])

  initialize: (context) ->
    @requests = {}
    context.requests = @requests

  apply: (request) ->
    @requests[request.state.id] = request



# Export a function to create the core plugin with default extensions
module.exports = {
  RequestExtensionPointConnector
  RequestLookup
  Spooler
  QueueConnector
  QueueWorker
  RequestStreamer
  Completer
}