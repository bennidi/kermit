merge = require 'merge'

# An extension adds some functionality to a specific extension point of the crawler.
class Extension

  @mergeOptions : (a,b) ->
    merge.recursive a,b

  @defaultOpts = {}

  # @param [ExtensionDescriptor] descriptor The descriptor for this extension
  constructor: (@descriptor) ->
    if !@descriptor
      throw new Error "Any extension needs a descriptor"


  # @param [CrawlRequest] request The request to be processed
  # @throws ProcessingException if the request processing should be stopped
  apply: (request) ->

  # This method is called before the extension is registered at the crawler.
  #
  # It might throw an error if it does not find the context to be providing what it expects.
  #
  # @param [Context] context The context provided by the crawler
  #
  initialize: (context) ->
    @context = context
    @log = context.log
    #TODO: Initialize log from context
    if !context
      throw new Error "Initialization of an extension requires a context object"

  # Run shutdown logic of extension (if any)
  destroy : () ->

  targets: () ->
    @descriptor.extpoints

  name : () -> @descriptor.name

  verify: () ->
    if !@context
      throw new Error "An extension requires a context object"

class ExtensionDescriptor

  constructor: (@name,
                @extpoints = [],
                @description = "Please provide a description") ->


class Plugin

  constructor: (@extensions = [], @description = "Please provide a description for this plugin") ->

  initialize: (context) ->
    if !context
      throw new Error "Initialization of a plugin requires a context object"

module.exports = {
  Extension
  ExtensionDescriptor
  Plugin
}

