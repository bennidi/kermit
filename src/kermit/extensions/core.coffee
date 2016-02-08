{Phase} = require '../CrawlRequest'
{Extension} = require '../Extension'
{ExtensionPoint} = require '../Crawler'

# Adds listeners to the requests such that each phase transition will
# trigger execution of the respective {ExtensionPoint}
class ExtensionPointConnector extends Extension

  # @nodoc
  constructor: () ->
    super INITIAL : (request) =>
      request.context = @context
      request.onChange 'phase', @executePhase

  # @nodoc
  executePhase: (request) =>
    @context.executeRequest request


# Handle phase transition {INITIAL} -> {SPOOLED}
class Spooler extends Extension

  # Create a Spooler
  constructor: ()->
    super INITIAL : (request) -> request.spool()

# Handle phase transition {FETCHED} -> {COMPLETE}
class Completer extends Extension

  # Create a Completer
  constructor: ->
    super FETCHED : (request) -> request.complete()

# Add capability to lookup a request object by its id.
# Note: This is used to find the living request object for a given persistent state
# stored in lokijs.
class RequestLookup extends Extension

  # @nodoc
  constructor: () ->
    super
      INITIAL : (request) => @requests[request.id()] = request

  # Expose a map that allows to lookup a {CrawlRequest} object by id
  initialize: (context) ->
    super context
    @requests = {}
    context.share "requests", @requests


# Run cleanup on all terminal phases
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
    request.cleanup()
    @log.trace? request.toString()

  # Do cleanup work to prevent memory leaks
  error: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    request.cleanup()

  # Do cleanup work to prevent memory leaks
  canceled: (request) ->
    delete @context.requests[request.id()] # Remove from Lookup table to allow GC
    request.cleanup()

module.exports = {
  ExtensionPointConnector
  RequestLookup
  Spooler
  Completer
  Cleanup
}