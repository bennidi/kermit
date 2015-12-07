{ProcessingException, Extension} = require './Extension'
{ExtensionPointConnector, RequestLookup, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues.coffee'
{RequestStreamer} = require './extensions/core.streaming.coffee'
{RequestFilter, DuplicatesFilter} = require './extensions/core.filter.coffee'
{Status, CrawlRequest, Status} = require './CrawlRequest'
winston = require 'winston'

# Helper method to invoke all extensions for processing of a given request
callExtensions = (extensions, request, context)->
  for extension in extensions
    try
      # An extension may modify the request
      # console.info "Executing #{extension.descriptor.name}"
      if request.isCanceled()
        return false
      else
        extension.apply(request)
    catch error
      context.logger.error "Error in extension #{extension.descriptor.name}. Message: #{error.message}"
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
    for extension in @extensions
      subContext = context.fork()
      extension.initialize(subContext)


  shutdown: () ->
    for extension in @extensions
      try
        extension.shutdown?()
      catch error
        @context.logger.error "Error in extension #{extension.descriptor.name}. Message: #{error.message}"

  apply: (request) ->
    @beforeApply?(request) # Hook for sub-classes to add pre-processing
    result = callExtensions(@extensions, request, @context)
    @afterApply?(request, result) # Hook for sub-classes to add post-processing
    request

# TODO: DOC
class INITIAL extends ExtensionPoint
  @phase = Status.INITIAL
  constructor: () ->
    super Status.INITIAL, "This extension point marks the beginning of a request cycle."

# TODO: DOC
class SPOOLED extends ExtensionPoint
  @phase = Status.SPOOLED
  constructor: () ->
    super Status.SPOOLED, "Extension Point for status #{Status.SPOOLED}"

# TODO: DOC
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING
  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

# TODO: DOC
class READY extends ExtensionPoint
  @phase = Status.READY
  constructor: () ->
    super Status.READY, "Extension Point for status #{Status.READY}"

# TODO: DOC
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING
  constructor: () ->
    super Status.FETCHING, "Extension Point for status #{Status.FETCHING}"

# TODO: DOC
class FETCHED extends ExtensionPoint
  @phase = Status.FETCHED
  constructor: () ->
    super Status.FETCHED, "Extension Point for status #{Status.FETCHED}"

# TODO: DOC
class COMPLETE extends ExtensionPoint
  @phase = Status.COMPLETE
  constructor: () ->
    super Status.COMPLETE, "Extension Point for status #{Status.COMPLETE}"

# TODO: DOC
class ERROR extends ExtensionPoint
  @phase = Status.ERROR
  constructor: () ->
    super Status.ERROR, "Extension Point for status #{Status.ERROR}"

# TODO: DOC
class CANCELED extends ExtensionPoint
  @phase = Status.CANCELED
  constructor: () ->
    super Status.CANCELED, "Extension Point for status #{Status.CANCELED}"

# TODO: DOC
class CrawlerContext

  constructor: (config) ->
    @crawler = config.crawler
    @execute = config.execute
    @logger = config.logger
    @config = config.crawler.config

  fork : () ->
    child = Object.create this
    child.share = (property, value) =>
      @[property] = value
    child


# TODO: DOC
class Crawler

  # The set of all provided extension points. One for each distinct state
  # in the CrawlRequest state diagram.
  # Extensions are added to extension points while initialization (constructor).
  # Core extensions are added automatically, user extensions are specified in the
  # options of the constructor.
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

  fs = require 'fs-extra'

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

  defaultTransports = (basedir) ->
    [
      new (winston.transports.Console)(
        colorize: true
      ),
      new (winston.transports.File)(
        name: 'info-log'
        filename: "#{basedir}/logs/info.log"
        level: 'info'
        json : true
      ),
      new (winston.transports.File)(
        name: 'error-log'
        filename: "#{basedir}/logs/error.log"
        handleExceptions: true
        humanReadableUnhandledException: true
        level: 'error'
        json : true
      )]

  buildLog = (sharedTransports) ->
    new (winston.Logger)({
      transports: sharedTransports})

  @defaultOpts =
    name : "kermit"
    basedir : "/tmp/sloth"
    # Clients can add extensions
    extensions: []
    # Options of each core extension can be customized here
    options:
      Queue : {} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streamer : {} # Options for the [Streamer]
      Filter : {} # Options for request filtering, [RequestFilter],[DuplicatesFilter]
      Logging :
        transports : []

  constructor: (config = {}) ->
    # Build and verify (TODO) options
    # Use default options where no user defined options are given
    @config = Extension.mergeOptions Crawler.defaultOpts, config
    if @config.options.Logging.transports.length is 0
      @config.options.Logging.transports = defaultTransports @basePath()
    fs.mkdirsSync @basePath() + "/logs"
    # Create and add extension points
    @extpoints = {}
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint  for ExtensionPoint in Crawler.extensionPoints
    # Create the root context of this crawler
    @context = new CrawlerContext
        crawler: this
        execute: (phase, request) =>
          execute(@, phase, request)
        logger: buildLog @config.options.Logging.transports
    # Core extensions that need to run BEFORE user extensions
    addExtension this, new RequestFilter @config.options.Filter
    addExtension this, new ExtensionPointConnector
    addExtension this, new RequestLookup
    addExtension this, new QueueConnector @config.options.Queue
    addExtension this, new QueueWorker @config.options.Queue
    addExtension this, new DuplicatesFilter
    addExtension this, new RequestStreamer @config.options.Streamer
    # Add client extensions
    @context.logger.info "Installing user extensions #{(ext.name() for ext in @config.extensions)}"
    addExtensions this, @config.extensions
    # Core extensions that need to run AFTER client extensions
    addExtension this, new Spooler
    addExtension this, new Completer
    addExtension this, new Cleanup
    @extpoints[phase].initialize @context for phase of @extpoints


  basePath: () -> "#{@config.basedir}/#{@config.name}"

  # Call shutdown method on all ExtensionPoint
  shutdown: () ->
    extpoint(this, phase).shutdown() for phase of @extpoints

  # Create a new request and start its processing
  enqueue: (url) ->
    request = new CrawlRequest url, @context
    execute @, INITIAL.phase, request

  toString: () ->
    "Crawler: " # TODO: List extension points and content



module.exports = {
  Crawler
  ExtensionPoint
}