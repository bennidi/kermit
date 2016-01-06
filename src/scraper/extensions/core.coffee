{Status} = require('../CrawlRequest')
{Extension} = require '../Extension'

# Adds listeners to the requests such that each status transition will
# trigger execution of the respective {ExtensionPoint}
class ExtensionPointConnector extends Extension

  # @nodoc
  constructor: (@context) ->
    super INITIAL : @apply , @context

  # Add listener to the request such that status change will trigger
  # execution of corresponding {ExtensionPoint}
  apply: (request) ->
    request.context = @context
    request.onChange 'status', (request) ->
      request.context.execute request.status(), request

# Handle status transition CREATED -> SPOOLED
class Spooler extends Extension

  # Create a Spooler
  constructor: ()->
    super INITIAL : @apply

  # Handle status transition CREATED -> SPOOLED
  # @return [CrawlRequest] The processed request
  apply: (request) ->
    request["tsLastSpool"] = new Date().getTime()
    request.spool()

# Handle status transition FETCHED -> COMPLETE
class Completer extends Extension

  # Create a Completer
  constructor: ->
    super FETCHED : @apply

  # Handle status transition FETCHED -> COMPLETE
  # @return [CrawlRequest] The processed request
  apply: (request) ->
    request.complete()

# Add capability to lookup a request object by its id.
# This is necessary to find the living request object for a given persistent state
# because lokijs does not store the entire JavaScript object
class RequestLookup extends Extension

  # @nodoc
  constructor: () ->
    super
      INITIAL : @apply

  # Expose a map that allows to lookup a {CrawlRequest} object by id
  initialize: (context) ->
    super context
    @requests = {}
    context.share "requests", @requests

  # Associated the requests id with the request object itself
  apply: (request) ->
    @requests[request.id()] = request


# Run cleanup on all terminal states
class Cleanup extends Extension

  # @nodoc
  constructor: () ->
    super
      COMPLETE : @complete
      CANCELED : @canceled
      ERROR : @error

  # Do cleanup work to prevent memory leaks
  complete: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    @context.queue.completed(request) # Remove from
    delete request.response

  # Do cleanup work to prevent memory leaks
  error: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    delete request.response

  # Do cleanup work to prevent memory leaks
  canceled: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    delete request.response

module.exports = {
  ExtensionPointConnector
  RequestLookup
  Spooler
  Completer
  Cleanup
}