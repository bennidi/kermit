{ProcessingException, Extension} = require './Extension'
{ExtensionPointConnector, RequestLookup, Spooler, Completer} = require('./extensions/core')
{QueueConnector, QueueWorker} = require('./extensions/core.queues.coffee')
{RequestStreamer} = require('./extensions/core.streaming.coffee')
RequestFilter = require('./extensions/core.filter.coffee')
{Status, CrawlRequest} = require './CrawlRequest'
{Points} = require('./Crawler.Extpoints')
{ExtensionPoint} = require('./Crawler.Extpoints')

class CrawlerContext

  constructor: (@crawler, @execute) ->

class Crawler

  # The set of all provided extension points. One for each distinct state
  # in the CrawlRequest state diagram.
  # Extensions are added to extension points while initialization (constructor).
  # Core extensions are added automatically, user extensions are specified in the
  # options of the contructor.
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

  addPlugins = (crawler, context, plugins...) ->
    (addExtension crawler, extension, context for extension in plugin.extensions) for plugin in plugins

  addExtension =    (crawler, extension) ->
    extpoint(crawler, point).addExtension(extension) for point in extension.targets()


  extpoint = (crawler, phase) ->
    if !crawler.extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    crawler.extpoints[phase]

  @defaultOpts =
    extensions: []
    # each core extension has its place for default opts
    core:
      ExtensionPointConnector : ExtensionPointConnector.defaultOpts
      RequestLookup : RequestLookup.defaultOpts
      QueueConnector : QueueConnector.defaultOpts
      QueueWorker : QueueWorker.defaultOpts
      RequestStreamer : RequestStreamer.defaultOpts
      RequestFilter : RequestFilter.defaultOpts
      Spooler : Spooler.defaultOpts
      Completer : Completer.defaultOpts

  constructor: (@opts = {}) ->
    # Use default options where no user defined options are given
    @opts = Extension.mergeOptions Crawler.defaultOpts, @opts
    @extpoints = {}
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint  for ExtensionPoint in Crawler.extensionPoints
    @context = new CrawlerContext this, (phase, request) =>
      extpoint(this, phase).apply request
    # Core extensions that need to run BEFORE user extensions
    addExtension this, new ExtensionPointConnector @opts.core.ExtensionPointConnector
    addExtension this, new RequestLookup @opts.core.RequestLookup
    addExtension this, new QueueConnector @opts.core.QueueConnector
    addExtension this, new QueueWorker @opts.core.QueueWorker
    addExtension this, new RequestStreamer @opts.core.RequestStreamer
    addExtension this, new RequestFilter @opts.core.RequestFilter
    # Add user extensions
    addExtensions this, @opts.extensions
    # Core extensions that need to run AFTER user extensions
    addExtension this, new Spooler @opts.core.Spooler
    addExtension this, new Completer @opts.core.Completer
    @extpoints[phase].initialize @context for phase of @extpoints


  shutdown: () ->
    extpoint(this, phase).shutdown() for phase of @extpoints

  enqueue: (url) ->
    request = new CrawlRequest url, @context
    extpoint(this, Points.INITIAL.phase).apply request

  toString: () ->
    "Crawler: " # TODO: List extension points and content

module.exports = {
  Crawler
  ExtensionPoint
}