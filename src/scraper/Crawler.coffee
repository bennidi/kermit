ProcessingException = require('./Extension').ProcessingException
storage = require './QueueManager'
requests = require './CrawlRequest'

class ExtensionPoint

  constructor: (@phase, @description = "Please provide a description") ->
    @extensions = []

  addExtension: (extension) ->
    @extensions.push extension
    this

class RequestCreated extends ExtensionPoint

  @phase = "request-new"

  constructor: () ->
    super RequestCreated.phase, "This extension point marks the beginning of a request cycle."

class CrawlerContext

  constructor: (@crawler) ->



class Crawler

  # The set of extension points provided by any crawler instance.
  # Each extension point is represented by its own class and comes
  # with its own documentation
  #
  @extensionPoints = [
    RequestCreated
  ]

  # Helper method to invoke all extensions for processing of a given request
  callExtensions = (extensions, request)->
    for extension in extensions
      try
        # An extension may modify the request
        console.info "Executing #{extension.descriptor.name}"
        extension.apply(request)
      catch error
        console.log "Error is of type " + error.type
        # or stop its processing by throwing the right exception
        if (error.type is ProcessingException.types.REJECTED)
          return request
    request

  constructor: (extensions) ->
    @queue = new storage.QueueManager
    @extpoints = {}
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint for ExtensionPoint in Crawler.extensionPoints
    @requests = {}
    @addExtension extension for extension in extensions
    @addPlugins require('./plugins/core.plugin')()


  addPlugins: (plugins...) ->
    (@addExtension extension for extension in plugin.extensions) for plugin in plugins

  # Add an extension to the crawler
  #
  # @example add an extension
  #   crawler.addExtension(new SimpleExtension)
  #
  # @param [Extension] extension the extension to add
  #
  addExtension: (extension) ->
    console.info "Adding extension #{extension.descriptor.name}"
    extension.initialize? new CrawlerContext this
    @extpoint(point).addExtension(extension) for point in extension.targets()

  extpoint: (phase) ->
    if !@extpoints[phase]?
      throw new Error "This extension point does not exists"
    @extpoints[phase]

  execute: (phase, request) ->
    callExtensions(@extpoint(phase).extensions, request)

  enqueue: (url) ->
    console.info "Enqueuing #{url}"
    request = new requests.CrawlRequest url
    @execute('request-new', request)

module.exports = {
  Crawler
  ExtensionPoint
}