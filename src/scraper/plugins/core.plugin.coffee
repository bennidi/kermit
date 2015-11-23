crawl = require '../cherry.modules'

class QueueConnector extends crawl.extensions.Extension

  constructor: () ->
    super new crawl.extensions.ExtensionDescriptor "Queue Connector", ["request-new"]

  apply: (request) ->
    @queue.trace(request)

  initialize: (context) ->
    super context
    @queue = context.crawler.queue

class RequestFetcher extends crawl.extensions.Extension

  constructor: () ->
    super new crawl.extensions.ExtensionDescriptor "Queue Worker", ["request-new"]

  initialize: (context) ->
    super context
    @queue = context.crawler.queue
    @requests = context.crawler.requests

  apply: (request) ->
    processRequests = () =>
      @fetch request for request in @queue.spooled() when not @clogged()
      if @requestsRemaining()
        process.nextTick processRequests
    process.nextTick processRequests

  clogged: () -> false # TODO: use criteria related to concurrency levels (->socket)

# Determines whether there are unfetched requests remaining
  requestsRemaining: ->
    remaining = @queue.created().length + @queue.spooled().length
    remaining > 0

  fetch:(request) ->
    @requests[request.id].status crawl.requests.Status.FETCHING

class RequestLookup extends crawl.extensions.Extension

  constructor: () ->
    super(new crawl.extensions.ExtensionDescriptor "RequestLookup", ["request-new"])

  apply: (request) ->
    @requests[request.state.id] = request

  initialize: (context) ->
    @requests = context.crawler.requests

class Spooler extends crawl.extensions.Extension

  constructor: ->
    super new crawl.extensions.ExtensionDescriptor "Spooler", ["request-new"]

  apply: (request, control) ->
    request.status 'SPOOLED'

module.exports = () -> new crawl.extensions.Plugin [ new RequestLookup, new QueueConnector, new Spooler, new RequestFetcher] , "Core plugin"