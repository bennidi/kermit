merge = require 'merge'

# {Extension}s are the core abstraction for adding actual request processing functionality
# to the {Crawler}. In fact, **ALL** of the available request processing functionality like filtering,
# queueing, streaming, logging etc. is implemented by means of extensions.
#
# Each extension can expose one handler for request processing by mapping it to
# one of the defined {CrawlRequest.Status} values.
# This mapping implicitly associates each extension with the {ExtensionPoint} that
# corresponds to the mapped {CrawlRequest.Status} value.
# @see {Crawler} for the state diagram modeling the values and transitions of {CrawlRequest.Status}
# and respective {ExtensionPoint}s.
#
# A major motivation of the extension design is to support the principle
# of separations of concern/single responsibility and to encourage the development of relatively
# small, testable and reusable request processing components.
# @abstract
class Extension

  # Merge two objects recursively.
  # This is used to combine user specified options with default options
  @mergeOptions : (a,b) ->
    merge.recursive a,b

  # Construct a new extension. By convention the property "name"
  # will be assigned the class name of this extension
  # @param handlers [Object] A mapping of {CrawlRequest.Status} values
  # to handlers that will be invoked for requests with that status
  constructor: (@handlers = {}) ->
    @name = @constructor.name

  # This method is called by the corresponding {ExtensionPoint}
  # during crawler construction.
  #
  # @param [CrawlerContext] context The context provided by the crawler
  # @throw Error if it does not find the context to be providing what it expects.
  initialize: (context) ->
    @context = context
    @log = context.log
    #TODO: Initialize log from context
    if !context
      throw new Error "Initialization of an extension requires a context object"

  # Run shutdown logic of this extension (if any)
  # @abstract
  destroy : () ->

  # Get all {CrawlRequest.Status} values handled by this extension
  targets: () ->
    (phase for phase of @handlers)

  # Run validity checks of this extension. Called after initialization and before
  # actual request processing starts
  # @throw Error if the configuration is invalid in any way
  verify: () ->
    if !@name
      throw new Error "An extension requires a name"
    if !@context
      throw new Error "An extension requires a context object"


module.exports = {
  Extension

}

