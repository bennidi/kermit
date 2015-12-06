{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'

# Adds callbacks to the requests such that each state transition will
# trigger execution of the respective extension point registered with the crawler
class ExtensionPointConnector extends Extension

  constructor: () ->
    super new ExtensionDescriptor "Request Extension Point Connector", [Status.INITIAL]

  apply: (request) ->
    request.context = @context
    request.onChange 'status', (request) ->
      request.context.execute request.status(), request

# State transition CREATED -> SPOOLED
class Spooler extends Extension

  constructor: ->
    super new ExtensionDescriptor "Spooler", [Status.INITIAL]

  apply: (request) ->
    request["tsLastSpool"] = new Date().getTime()
    request.spool()

# State transition FETCHED -> COMPLETED
class Completer extends Extension

  constructor: ->
    super new ExtensionDescriptor "Completer", [Status.FETCHED]

  apply: (request) ->
    request.complete()

# Add capability to lookup a request object by its id.
# This is necessary to find the living request object for a given persistent state
# because lokijs does not store the entire JavaScript object
class RequestLookup extends Extension

  constructor: () ->
    super(new ExtensionDescriptor "RequestLookup", [Status.INITIAL])

  initialize: (context) ->
    super context
    @requests = {}
    context.share "requests", @requests

  apply: (request) ->
    @requests[request.id()] = request


# Run cleanup on all terminal states
class Cleanup extends Extension

  @defaultOpts =
    queue: true #TODO: implement removal from storage

  constructor: () ->
    super(new ExtensionDescriptor "RequestLookup", [Status.COMPLETE, Status.CANCELED, Status.ERROR])

  apply: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC

module.exports = {
  ExtensionPointConnector
  RequestLookup
  Spooler
  Completer
  Cleanup
}