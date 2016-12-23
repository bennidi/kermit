{Phase} = require './RequestItem.Phases'
###

  Provide a mechanism to add functionality to the provider of the extension point (=> {Crawler})
  Extension are containers for {Extension}s - grouping them by {ProcessingPhase}.

  {Extension}s are invoked as part of the execution of their containing ExtensionPoint.

###
class ExtensionPoint



  # Construct an extension point
  # @param phase [String] The phase that corresponds to the respective value of {ProcessingPhase}
  constructor: (@context, @phase) ->
    throw new Error("Please provide the name of the ProcessingPhase") if !@phase
    throw new Error("Please provide a context") if !@context
    @log = @context.log
    @extensions = []

  # Add an {Extension}s handler for the matching phase
  add: (extension) ->
    @extensions.push extension
    this

  # Helper method to invoke all extensions for processing of a given item
  #
  # @todo Rename to invoke
  # @private
  process : (item) =>
    for extension in @extensions
      try
        # An extension may cancel item processing
        if item.isCanceled()then return item
        else extension.handlers[@phase].call(extension, item)
      catch error
        @log.error? error.toString(), { trace: error.stack, tags: [extension.name]}
        item.error(error)
    item

class ExtensionPointProvider

  constructor: ->
    @extpoints = {}
    @extensions = []

  initializeExtensionPoints: (context) ->
    @extpoints[phase] = new ExtensionPoint context, phase for phase in Phase.ALL

  # Add list of extensions to the given provider
  addExtensions : (extensions = []) ->
    for extension in extensions
      @getExtPoint(phase).add extension for phase in extension.targets()
      @extensions.push extension

  # Retrieve the {ExtensionPoint} for a given phase from the provider
  getExtPoint : (phase) ->
    if !@extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    @extpoints[phase]

  # Schedule execution of an {ExtensionPoint} for the given item
  scheduleExecution : (phase, item) ->
    process.nextTick @getExtPoint(phase).process, item
    item


module.exports = {
  ExtensionPoint
  ExtensionPointProvider
}
