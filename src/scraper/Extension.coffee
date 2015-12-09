merge = require 'merge'

# {Extension}s are the core abstraction for adding actual request processing functionality
# to the {Crawler}. All of the available request processing functionality, like filtering,
# queueing, streaming, logging etc. is implemented by means of extensions.
#
# {Extension}s are associated with at least one {ExtensionPoint} in order
# to be invoked in the expected stages of the request processing.
# @see {Crawler} for the state diagram that models the request flow and respective
# {ExtensionPoint}s.

# The motivation behind the extension design is that its abstraction
# defines clear boundaries of responsibility and encourages the development of relatively
# small, testable and reusable request processing components.
#
class Extension

  # Merge two objects recursively.
  # This is used to combine user specified options with default options
  @mergeOptions : (a,b) ->
    merge.recursive a,b

  constructor: (@name, @extpoints = [], @description = "Please provide a description") ->

  # Do the request processing that this extension was designed to do.
  # NOTE: Unintended processing errors (like NPEs, calling methods with wrong
  # signature etc.) are handled upwards and will cause the request to end up
  # with status {RequestStatus.Error}
  #
  # @param request {CrawlRequest}  The request to be processed by this extension
  # It will be in one of the status defined by this.extpoints
  # @abstract
  apply: (request) ->

  # This method is called by the corresponding {ExtensionPoint}
  # during crawler construction.
  #
  # @param [CrawlerContext] context The context provided by the crawler
  # @throw Error if it does not find the context to be providing what it expects.
  initialize: (context) ->
    @context = context
    @log = context.log
    @log.debug "Initializing #{@name}"
    #TODO: Initialize log from context
    if !context
      throw new Error "Initialization of an extension requires a context object"

  # Run shutdown logic of this extension (if any)
  # @abstract
  destroy : () ->

  # Get the list of {ExtensionPoint} identifiers handled by this extension.
  targets: () ->
    @extpoints

  # Run validity checks of this extension. Called after initialization and before
  # actual request processing starts
  # @throw Error if the configuration is invalid in any way
  verify: () ->
    if !@context
      throw new Error "An extension requires a context object"

module.exports = {
  Extension
}

