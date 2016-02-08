{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{ExtensionPoint} = require '../Crawler'

# Adds listeners to the items such that each phase transition will
# trigger execution of the respective {ExtensionPoint}
class ExtensionPointConnector extends Extension

  # @nodoc
  constructor: () ->
    super INITIAL : (item) =>
      item.context = @context
      item.onChange 'phase', @executePhase

  # @nodoc
  executePhase: (item) =>
    @context.executeRequest item


# Handle phase transition {INITIAL} -> {SPOOLED}
class Spooler extends Extension

  # Create a Spooler
  constructor: ()->
    super INITIAL : (item) -> item.spool()

# Handle phase transition {FETCHED} -> {COMPLETE}
class Completer extends Extension

  # Create a Completer
  constructor: ->
    super FETCHED : (item) -> item.complete()

# Add capability to lookup a item object by its id.
# Note: This is used to find the living item object for a given persistent state
# stored in lokijs.
class RequestItemMapper extends Extension

  # @nodoc
  constructor: () ->
    super
      INITIAL : (item) => @items[item.id()] = item

  # Expose a map that allows to lookup a {RequestItem} object by id
  initialize: (context) ->
    super context
    @items = {}
    context.share "items", @items


# Run cleanup on all terminal phases
class Cleanup extends Extension

  # @nodoc
  constructor: () ->
    super
      COMPLETE : @complete
      CANCELED : @canceled
      ERROR : @error

  # Do cleanup work to prevent memory leaks
  complete: (item) ->
    delete @context.items[item.id()] # Remove from Lookup table to allow GC
    @context.queue.completed(item) # Remove from
    item.cleanup()
    @log.trace? item.toString()

  # Do cleanup work to prevent memory leaks
  error: (item) ->
    delete @context.items[item.id()] # Remove from Lookup table to allow GC
    item.cleanup()

  # Do cleanup work to prevent memory leaks
  canceled: (item) ->
    delete @context.items[item.id()] # Remove from Lookup table to allow GC
    item.cleanup()

module.exports = {
  ExtensionPointConnector
  RequestItemMapper
  Spooler
  Completer
  Cleanup
}