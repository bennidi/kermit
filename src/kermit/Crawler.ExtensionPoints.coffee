{Phase} = require './RequestItem.Phases'
###
 Provide a mechanism to add functionality to the provider of the extension point (=> {Crawler})
 Extension points act as containers for {Extension}s - the primary abstraction for containment
 of processing functionality.
###
class ExtensionPoint

  # Add list of extensions to the given provider
  @addExtensions : (provider, extensions = []) ->
    for extension in extensions
      ExtensionPoint.get(provider, point).add extension for point in extension.targets()
      provider.extensions.push extension
  # Retrieve the {ExtensionPoint} for a given phase from the provider
  @get : (provider, phase) ->
    if !provider.extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    provider.extpoints[phase]
  # Schedule execution of an {ExtensionPoint} for the given item
  @execute : (provider, phase, item) ->
    process.nextTick ExtensionPoint.get(provider, phase).process, item
    item

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

module.exports = {
  ExtensionPoint
}