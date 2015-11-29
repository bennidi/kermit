{Status} = require('../CrawlRequest')
{Extension, ExtensionDescriptor} = require '../Extension'

# Adds callbacks to the requests such that each state transition will
# trigger execution of the respective extension point registered with the crawler
class ExtensionPointConnector extends Extension

  constructor: () ->
    super new ExtensionDescriptor "Request Extension Point Connector", [Status.INITIAL]

  apply: (request) ->
    request.onChange 'status', (state) =>
      @crawler.execute state.status, request

  initialize: (context) ->
    super context
    @crawler = context.crawler

# State transition CREATED -> SPOOLED
class Spooler extends Extension

  constructor: ->
    super new ExtensionDescriptor "Spooler", [Status.INITIAL]

  apply: (request) ->
    request.spool()

# State transition FETCHED -> COMPLETED
class Completer extends Extension

  constructor: ->
    super new ExtensionDescriptor "Completer", [Status.FETCHED]

  apply: (request) ->
    request.complete()

# Add capability to lookup a request object by id.
# This is necessary to find the living request object for a given persistent state
# because lokijs does not store the entire JavaScript object
class RequestLookup extends Extension

  constructor: () ->
    super(new ExtensionDescriptor "RequestLookup", [Status.INITIAL])

  initialize: (context) ->
    @requests = {}
    context.requests = @requests

  apply: (request) ->
    @requests[request.state.id] = request


module.exports = {
  ExtensionPointConnector
  RequestLookup
  Spooler
  Completer
}