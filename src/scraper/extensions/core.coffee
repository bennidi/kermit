{Status} = require('../CrawlRequest')
{Extension} = require '../Extension'

# Adds listeners to the requests such that each status transition will
# trigger execution of the respective {ExtensionPoint}
class ExtensionPointConnector extends Extension

  constructor: () ->
    super "Request Extension Point Connector", [Status.INITIAL]

  apply: (request) ->
    request.context = @context
    request.onChange 'status', (request) ->
      request.context.execute request.status(), request

# Handle status transition CREATED -> SPOOLED
class Spooler extends Extension

  constructor: ->
    super "Spooler", [Status.INITIAL]

  # Handle status transition CREATED -> SPOOLED
  # @return [CrawlRequest] The processed request
  apply: (request) ->
    request["tsLastSpool"] = new Date().getTime()
    request.spool()

# Handle status transition FETCHED -> COMPLETED
class Completer extends Extension

  constructor: ->
    super "Completer", [Status.FETCHED]

  # Handle status transition FETCHED -> COMPLETED
  # @return [CrawlRequest] The processed request
  apply: (request) ->
    request.complete()

# Add capability to lookup a request object by its id.
# This is necessary to find the living request object for a given persistent state
# because lokijs does not store the entire JavaScript object
class RequestLookup extends Extension

  constructor: () ->
    super "RequestLookup", [Status.INITIAL]

  initialize: (context) ->
    super context
    @requests = {}
    context.share "requests", @requests

  apply: (request) ->
    @requests[request.id()] = request


# Run cleanup on all terminal states
class Cleanup extends Extension

  constructor: () ->
    super "RequestLookup", [Status.COMPLETE, Status.CANCELED, Status.ERROR]

  apply: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    @context.queue.completed(request) # Remove from


module.exports = {
  ExtensionPointConnector
  RequestLookup
  Spooler
  Completer
  Cleanup
}