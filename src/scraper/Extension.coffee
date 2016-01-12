_ = require 'lodash'


###
{Extension}s are the core abstraction for adding actual request processing functionality
to the {Crawler}. In fact, **all** of the available **request processing functionality** like filtering,
queueing, streaming, logging etc. **is implemented by means of extensions**.

A major motivation of the extension design is to support the principles
of separation of concern as well as single responsibility.
It aims to encourage the development of relatively small, testable and reusable
request processing components.

Each extension can expose handlers for request processing by mapping them to
one of the defined values of {RequestStatus}.
Note:
 -  The mapping implicitly associates each extension with the {ExtensionPoint}
   corresponding to one of {RequestStatus}.ALL
 -  Each extension may expose only one handler per status value

See {Crawler} for the state diagram modeling the values and transitions of {RequestStatus}
and respective {ExtensionPoint}s.

@abstract
@see Crawler
@see ExtensionPoint
@see CrawlRequest
  
###
class Extension

  # Construct a new extension. By convention the property "name"
  # will be assigned the class name of this extension
  # @param handlers [Object] A mapping of {RequestStatus} values
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

  # Merge two objects recursively.
  # This is used to combine user specified options with default options
  merge : (a,b) ->
    {objects} = require './util/utils.coffee'
    objects.merge a,b

  # Run shutdown logic of this extension (if any)
  # @abstract
  shutdown : () ->

  # Get all {RequestStatus} values handled by this extension
  targets: () ->
    (phase for phase of @handlers)

  # Run validity checks of this extension. Called after initialization and before
  # actual request processing starts
  # @throw Error if the configuration is invalid in any way
  verify: () ->
    @log.debug? "Configuration of #{@name}", @opts
    if !@name
      throw new Error "An extension requires a name"
    if !@context
      throw new Error "An extension requires a context object"


module.exports = {
  Extension
}

