merge = require 'merge'

# An extension adds some functionality to a specific extension point of the crawler.
class Extension

  @mergeOptions : (a,b) ->
    merge.recursive a,b

  constructor: (@name, @extpoints = [],
    @description = "Please provide a description") ->

  # @param [CrawlRequest] request The request to be processed
  apply: (request) ->

  # This method is called by the corresponding {ExtensionPoint}
  # when the crawler is constructed.
  #
  # @param [CrawlerContext] context The context provided by the crawler
  # @throw Error if it does not find the context to be providing what it expects.
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
    @extpoints

  verify: () ->
    if !@context
      throw new Error "An extension requires a context object"

class ExtensionDescriptor

  constructor: () ->


class Plugin

  constructor: (@extensions = [], @description = "Please provide a description for this plugin") ->

  initialize: (context) ->
    if !context
      throw new Error "Initialization of a plugin requires a context object"

module.exports = {
  Extension
  Plugin
}

