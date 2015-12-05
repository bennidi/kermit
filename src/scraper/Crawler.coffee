{ProcessingException, Extension} = require './Extension'
{ExtensionPointConnector, RequestLookup, Spooler, Completer, Cleanup} = require('./extensions/core')
{QueueConnector, QueueWorker} = require('./extensions/core.queues.coffee')
{RequestStreamer} = require('./extensions/core.streaming.coffee')
{RequestFilter} = require('./extensions/core.filter.coffee')
{Status, CrawlRequest, Status} = require './CrawlRequest'
{Points} = require('./Crawler.Extpoints')
{ExtensionPoint} = require('./Crawler.Extpoints')


# Helper method to invoke all extensions for processing of a given request
callExtensions = (extensions, request)->
  for extension in extensions
    try
# An extension may modify the request
#console.info "Executing #{extension.descriptor.name}"
      if request.isCanceled()
        return false
      else
        extension.apply(request)
    catch error
      console.log "Error in extension #{extension.descriptor.name}. Message: #{error.message}"
      request.error(error)
      return false
  true

class ExtensionPoint

  constructor: (@phase, @description = "Extension Point has no description") ->
    @extensions = []

  addExtension: (extension) ->
    @extensions.push extension
    this

  initialize: (context) ->
    @context = context
    extension.initialize(context) for extension in @extensions

  shutdown: () ->
    for extension in @extensions
      try
        extension.shutdown?()
      catch error
        console.log "Error in extension #{extension.descriptor.name}. Message: #{error.message}"

  apply: (request) ->
    @beforeApply?(request) # Hook for sub-classes to add pre-processing
    result = callExtensions(@extensions, request)
    @afterApply?(request, result) # Hook for sub-classes to add post-processing
    request

class INITIAL extends ExtensionPoint

  @phase = Status.INITIAL

  constructor: () ->
    super Status.INITIAL, "This extension point marks the beginning of a request cycle."


class SPOOLED extends ExtensionPoint

  @phase = Status.SPOOLED

  constructor: () ->
    super Status.SPOOLED, "Extension Point for status #{Status.SPOOLED}"

class FETCHING extends ExtensionPoint

  @phase = Status.FETCHING

  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

class READY extends ExtensionPoint

  @phase = Status.READY

  constructor: () ->
    super Status.READY, "Extension Point for status #{Status.READY}"

class FETCHING extends ExtensionPoint

  @phase = Status.FETCHING

  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

class FETCHED extends ExtensionPoint

  @phase = Status.FETCHED

  constructor: () ->
    super Status.FETCHED, "Extension Point for status #{Status.FETCHED}"

class COMPLETE extends ExtensionPoint

  @phase = Status.COMPLETE

  constructor: () ->
    super Status.COMPLETE, "Extension Point for status #{Status.COMPLETE}"

class ERROR extends ExtensionPoint

  @phase = Status.ERROR

  constructor: () ->
    super Status.ERROR, "Extension Point for status #{Status.ERROR}"

class CANCELED extends ExtensionPoint

  @phase = Status.CANCELED

  constructor: () ->
    super Status.CANCELED, "Extension Point for status #{Status.CANCELED}"

class CrawlerContext

  constructor: (@crawler, @execute) ->

class Crawler

  # The set of all provided extension points. One for each distinct state
  # in the CrawlRequest state diagram.
  # Extensions are added to extension points while initialization (constructor).
  # Core extensions are added automatically, user extensions are specified in the
  # options of the contructor.
  @extensionPoints = [
    INITIAL,
    FETCHING,
    SPOOLED,
    READY,
    FETCHING,
    FETCHED,
    COMPLETE,
    ERROR,
    CANCELED
  ]

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

  execute = (crawler, phase, request) ->
    process.nextTick ->
      extpoint(crawler, phase).apply request
    request

  @defaultOpts =
    # Clients can add extensions
    extensions: []
    # Options of each core extension can be customized
    options:
      QueueConnector : QueueConnector.defaultOpts
      QueueWorker : QueueWorker.defaultOpts
      Streamer : RequestStreamer.defaultOpts
      Filter : RequestFilter.defaultOpts

  constructor: (@config = {}) ->
    # Use default options where no user defined options are given
    @config = Extension.mergeOptions Crawler.defaultOpts, @config
    @extpoints = {}
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint  for ExtensionPoint in Crawler.extensionPoints
    @context = new CrawlerContext this, (phase, request) =>
      execute(@, phase, request)
    # Core extensions that need to run BEFORE user extensions
    addExtension this, new ExtensionPointConnector
    addExtension this, new RequestLookup
    addExtension this, new QueueConnector @config.options.QueueConnector
    addExtension this, new QueueWorker @config.options.QueueWorker
    addExtension this, new RequestStreamer @config.options.Streamer
    addExtension this, new RequestFilter @config.options.Filter
    # Add client extensions
    addExtensions this, @config.extensions
    # Core extensions that need to run AFTER client extensions
    addExtension this, new Spooler
    addExtension this, new Completer
    addExtension this, new Cleanup
    @extpoints[phase].initialize @context for phase of @extpoints


  # Call shutdown method on all extensions
  shutdown: () ->
    extpoint(this, phase).shutdown() for phase of @extpoints

  # Create a new request and start its processing
  enqueue: (url) ->
    request = new CrawlRequest url, @context
    execute @, Points.INITIAL.phase, request

  toString: () ->
    "Crawler: " # TODO: List extension points and content



module.exports = {
  Crawler
  ExtensionPoint
}