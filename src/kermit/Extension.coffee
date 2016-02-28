_ = require 'lodash'
{obj} = require './util/tools'
{CrawlerContext, ContextAware} = require './Crawler.Context'

###
{Extension}s are the core abstraction for adding actual item processing functionality
to the {Crawler}. In fact, **all** of the available **item processing functionality** like filtering,
queueing, streaming, logging etc. **is implemented by means of extensions**.

A major motivation of the extension design is to support the principles
of separation of concern as well as single responsibility.
It aims to encourage the development of relatively small, testable and reusable
item processing components.

Each extension can expose handlers for item processing by mapping them to
one of the defined values of {RequestPhase}.
Note:
 -  The mapping implicitly associates each extension with the {ExtensionPoint}
   corresponding to one of {RequestPhase}.ALL
 -  Each extension may expose only one handler per phase value

See {Crawler} for the state diagram modeling the values and transitions of {RequestPhase}
and respective {ExtensionPoint}s.

@abstract
@see Crawler
@see ExtensionPoint
@see RequestItem
  
###
class Extension extends ContextAware

  # Construct a new extension. By convention the property "name"
  # will be assigned the class name of this extension
  # @param handlers [Object] A mapping of {RequestPhase} values
  # to handlers that will be invoked for items with that phase
  constructor: (@handlers = {}) ->
    @name = @constructor.name

  # This method is called by the corresponding {ExtensionPoint}
  # during crawler construction.
  #
  # @param [CrawlerContext] context The context provided by the crawler
  # @throw Error if it does not find the context to be providing what it expects.
  initialize: (context) ->
    @name = @constructor.name
    throw new Error "Initialization of an extension requires a context object" unless context
    # Reexpose most common objects
    @importContext context
    @initialized = true


  # Merge two objects recursively.
  # This is used to combine user specified options with default options
  merge : (a,b) ->
    {obj} = require './util/tools'
    obj.overlay a,b

  # Get all {RequestPhase} values handled by this extension
  targets: ->
    (phase for phase of @handlers)

  # Run validity checks of this extension. Called after initialization and before
  # actual item processing starts
  # @throw Error if the configuration is invalid in any way
  verify: ->
    throw new Error "Extension not properly initialized" unless @initialized
    throw new Error "An extension requires a name" unless @name
    throw new Error "An extension requires a context object" unless @context


  # @return {String} Human readable description of this extension
  toString: ->
    phases = (key for key of @handlers)
    asString = "#{@name} for [#{phases}]"
    asString += if @opts then ". Options:\n#{obj.print @opts}" else ". No options provided."


module.exports = {
  Extension
}

