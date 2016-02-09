{Extension} = require './Extension'
{ExtensionPoint} = require './Crawler.ExtensionPoints'
{ExtensionPointConnector, RequestItemMapper, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues'
{RequestStreamer} = require './extensions/core.streaming'
{QueueManager} = require './QueueManager'
{RequestFilter, UrlFilter} = require './extensions/core.filter'
{INITIAL,SPOOLED,READY,FETCHING,FETCHED,COMPLETE,CANCELED,ERROR, Phase, RequestItem} = require './RequestItem'
{LogHub, LogConfig} = require './Logging'
{obj} = require './util/tools'

_ = require 'lodash'
fse = require 'fs-extra'


###
The Crawler coordinates execution of submitted {RequestItem} by applying all {Extension}s
matching the item's current phase.

All functionality for item handling, such as filtering, queueing, streaming, storing, logging etc.
is implemented as {Extension}s to {ExtensionPoint}s.

Extensions are added to extension points during initialization. Core extensions are added automatically,
user extensions are specified in the options of the Crawler's constructor.

The crawler defines an extension point for each distinct value of {RequestPhase}.
Each ExtensionPoint wraps the processing steps carried out when the item phase changes
to a new value. The phase transitions implicitly define a item flow illustrated in the
diagram below.

@example Configuration Parameters
    name      : "kermit"
    basedir   : "/tmp/sloth"
    extensions: [] # Clients can add extensions
    options   : # Options of each core extension can be customized here
      Logging : LogConfig.detailed
      Queueing   : {} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the [Streamer]
      Filtering  : {} # Options for item filtering, [RequestFilter],[DuplicatesFilter]
      Scheduling : {} # Options for the [Scheduler]
        maxWaiting: 50
        msPerUrl: 50
###
class Crawler

  # Create a new crawler with the given options
  # @param options [Object] The configuration for this crawler.
  # @see CrawlerConfig
  constructor: (options = {}) ->
    # Use default options where no user defined options are given
    @config = new CrawlerConfig options
    @log = new LogHub(@config.options.Logging).logger()
    @log.info? "#{obj.print @config}", tags: ['Config']
    @queue = new QueueManager "#{@config.basePath()}/#{@config.options.Queueing.filename}"
    @scheduler = new Scheduler this, @queue, @config
    # Create the root context of this crawler
    @context = new CrawlerContext
      config : @config
      crawler: @ # re-expose this crawler
      log    : @log
      queue : @queue
      scheduler: @scheduler

    # Create and add extension points
    @extpoints = {}
    @extpoints[phase] = new ExtensionPoint @context, phase for phase in Phase.ALL
    @extensions = []

    # Core extensions that need to run BEFORE user extensions
    ExtensionPoint.addExtensions this, [
      new RequestFilter @config.options.Filtering
      new ExtensionPointConnector
      new RequestItemMapper
      new QueueConnector @config.options.Queueing
      new QueueWorker @config.options.Queueing
      ]
    # Add client extensions
    @log.info? "Installing user extensions #{(ext.name for ext in @config.extensions)}"
    ExtensionPoint.addExtensions this, @config.extensions
    # Core extensions that need to run AFTER client extensions
    ExtensionPoint.addExtensions this, [
      new RequestStreamer @config.options.Streaming
      new Spooler
      new Completer
      new Cleanup]
    @initialize()
    # Usually this handler is considered back practice but in case of processing errors
    # of single items, operation should continue.
    process.on 'uncaughtException', (error) =>
    # TODO: Keep track of error rate (errs/sec) and define threshold that will eventually allow the process to exit
      @log.error? "Severe error! Please check log for details", {tags:['Uncaught'], error:error.toString(), stack:error.stack}


  # Initializes this extension point with the given context. Initialization cascades
  # to all contained extensions
  # @private
  initialize: () ->
    @scheduler.start()
    for extension in @extensions
      extension.initialize(@context.fork())
      extension.verify()
      @log.info? extension.toString(), tags: ['Config']

  # Run shutdown logic on all extensions
  shutdown: () ->
    for extension in _(@extensions).reverse().value()
      try
        @log.info? "Shutdown of #{extension.name}"
        extension.shutdown?()
      catch error
        @log.error? "Shutdown error in #{extension.name}", {error : error.toString() stack: error.stack()}
    @scheduler.shutdown()
    @queue.shutdown()

  # Create a new {RequestItem} and start its processing
  # @return [RequestItem] The created item
  execute: (url, meta) ->
    @log.debug? "Executing #{url}"
    item = new RequestItem url, meta, @log
    ExtensionPoint.execute @, Phase.INITIAL, item

  # Add the url to the {Scheduler}
  schedule: (url, meta) ->
    @scheduler.schedule url, meta

  # Pretty print this crawler
  toString: () ->
    "Crawler: " # TODO: List extension points and content

# A container for properties that need to be shared among all instances of {ExtensionPoint} and {Extension}
# of a given {Crawler}. Each {Crawler} has its own, distinct context that it passes to all its extension points.
#
# Any Extension or ExtensionPoint may modify the context to expose additional functionality
# to other Extensions or ExtensionPoints
class CrawlerContext

  # Construct a new CrawlerContext
  #
  # @param [Object] config The configuration object for this context
  # @option config [Crawler] crawler The crawler that created this context
  # @option config [Function] execute A function handle to execute an extension point
  # @option config [bunyan.Logger] log A logger to handle log messages
  constructor: (config) ->
    @crawler = config.crawler
    @log = config.log
    @config = config.crawler.config
    @queue = config.queue

  # @see [Crawler#schedule]
  schedule : (url, meta) ->
    @crawler.schedule url, meta

  # Access to execution logic of
  # @see [Crawler#execute]
  execute : (url, meta) =>
    @crawler.execute url, meta

  executeRequest : (item) ->
    ExtensionPoint.execute @crawler, item.phase(), item

  # Create a child context that shares all properties with its parent context.
  # The child context exposes a method to share properties with all other child contexts
  # @return [CrawlerContext] A new child context of this context
  fork: () ->
    child = Object.create this
    child.share = (property, value) =>
      @[property] = value
    child

###
  The central object for configuring an instance of {Crawler}.
  @private
###
class CrawlerConfig

  # Create an object containing the default configuration options
  @defaultOpts : () ->
    name      : "kermit"
    basedir   : "/tmp/sloth"
    extensions: [] # Clients can add extensions
    options   : # Options of each core extension can be customized here
      Logging   : LogConfig.detailed
      Queueing   : {filename : "#{obj.randomId()}-queue.json"} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the {Streamer}
      Filtering  : {} # Options for item filtering, [RequestFilter],[DuplicatesFilter]
      Scheduling  : {} # Options for URL scheduling [Scheduler]

  ###
  @param config [Object] The configuration parameters
  @option config [String] name The name of the crawler
  @option config [String] basedir The base directory used for all data (logs, offline storage etc.)
  @option config [Array<Extension>] extensions An array of user {Extension}s to be installed
  @option config.options [Object] Queueing Options for {QueueWorker} and {QueueConnector}
  @option config.options [Object] Streaming Options for {RequestStreamer}
  @option config.options [Object] Filtering Options for {RequestFilter} and {UrlFilter}
  @option config.options [Object] Logging The configuration for the {LogHub}


  ###
  constructor: (config = {}) ->
    config = obj.overlay CrawlerConfig.defaultOpts(), config
    @name = config.name
    @basedir = config.basedir
    @extensions = config.extensions
    @options = config.options
    @options.Logging = switch
      when _.isFunction config.options.Logging then config.options.Logging "#{@basePath()}/logs"
      when _.isObject config.options.Logging then config.options.Logging
      else LogConfig.detailed "#{@basePath()}/logs"

  # @return [String] The configured base path of this crawler
  basePath: () -> "#{@basedir}/#{@name}"

###

  The scheduler acts as a buffer for submitted URLs, which it will feed to the crawler
  according to the crawlers load.
  It receives URLs from clients and applies all configured filters (blacklist/whitelist)
  as well as duplicate prevention.
  The scheduler is an internal class controlled by the {Crawler} and should not be interacted
  with directly. It is exposed indirectly through the {CrawlerContext}.

  @private
###
class Scheduler

  @defaultOptions: () ->
    maxWaiting : 50
    msPerUrl : 50

  # @nodoc
  constructor: (@crawler, @queue, @config) ->
    @log = @crawler.log
    filterOpts =
      allow : _.filter @config.options.Filtering.allow, _.isRegExp
      deny : _.filter @config.options.Filtering.deny, _.isRegExp
    delete filterOpts.allow if _.isEmpty filterOpts.allow
    delete filterOpts.deny if _.isEmpty filterOpts.deny
    @urlFilter = new UrlFilter filterOpts, @log
    @opts = obj.overlay Scheduler.defaultOptions(), @config.options.Scheduling

  # @private
  schedule: (url, meta) ->
    if not @urlFilter.isAllowed(url) or @queue.isKnown url
      return
    if @queue.itemsWaiting().length <  @opts.maxWaiting
      @crawler.execute url, meta
    else
      @log.debug? "Scheduling #{url}"
      @queue.scheduleUrl url, meta

  # Called by Crawler at startup
  # @private
  start: () ->
    pushUrls = () =>
      waiting = @queue.itemsWaiting().length
      if waiting < @opts.maxWaiting
        urls = @queue.nextUrlBatch(@opts.maxWaiting - waiting)
        @crawler.log.debug? "Retrieved url batch of size #{urls.length} for scheduling", tags:['Scheduler']
        @crawler.execute entry.url, entry.meta for entry in urls
    @executor = setInterval pushUrls,  @opts.maxWaiting *  @opts.msPerUrl
    @executor.unref()

  # @nodoc
  # @private
  shutdown: () ->
    clearInterval @executor

module.exports = {
  Crawler
  ExtensionPoint
}