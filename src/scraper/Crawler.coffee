ProcessingException = require('./Extension').ProcessingException
core = require('./extensions/core')
Request = require './CrawlRequest'
Status = Request.Status
Points = require('./Crawler.Extpoints').Points
ExtensionPoint = require('./Crawler.Extpoints').ExtensionPoint

class CrawlerContext

  constructor: (@crawler) ->

class Crawler

  # The set of extension points provided by any crawler instance.
  # Each extension point is represented by its own class and comes
  # with its own documentation
  #
  @extensionPoints = [
    Points.INITIAL,
    Points.FETCHING,
    Points.SPOOLED,
    Points.READY,
    Points.FETCHING,
    Points.FETCHED,
    Points.COMPLETE,
    Points.ERROR,
    Points.CANCELED
  ]

  # Add an extension to the crawler
  #
  # @example add an extension
  #   crawler.addExtension(new SimpleExtension)
  #
  # @param [Extension] extension the extension to add
  #
  addExtensions = (crawler, extensions = []) ->
    addExtension crawler, extension for extension in extensions

  addExtensionPoint = (crawler, extpoint) ->
    crawler.extpoints[extpoint.phase] = extpoint

  addPlugins = (crawler, context, plugins...) ->
    (addExtension crawler, extension, context for extension in plugin.extensions) for plugin in plugins

  addExtension =    (crawler, extension) ->
    console.info "Adding extension #{extension.descriptor.name}"
    extension.initialize? crawler.context
    crawler.extpoint(point).addExtension(extension) for point in extension.targets()

  initializeExtensionPoints = (crawler) ->
    crawler.extpoints = {}
    addExtensionPoint crawler, new ExtensionPoint for ExtensionPoint in Crawler.extensionPoints

  defaultOpts =
    extensions: []

  constructor: (opts = defaultOpts) ->
    @context = new CrawlerContext this
    initializeExtensionPoints(this)
    # Extensions that need to run BEFORE user extensions
    addExtension this, new core.RequestExtensionPointConnector
    addExtension this, new core.RequestLookup
    addExtension this, new core.QueueConnector
    addExtension this, new core.QueueWorker
    addExtension this, new core.RequestStreamer
    addExtensions this, opts.extensions
    # The spooler needs to be last in its phase
    addExtension this, new core.Spooler
    addExtension this, new core.Completer

  extpoint: (phase) ->
    if !@extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    @extpoints[phase]

  execute: (phase, request) ->
    @extpoint(phase).apply request

  enqueue: (url) ->
    console.info "Enqueuing #{url}"
    request = new Request url, @context
    @execute(Points.INITIAL.phase, request)

module.exports = {
  Crawler
  ExtensionPoint
}