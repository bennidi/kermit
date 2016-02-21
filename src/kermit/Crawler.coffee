{obj, uri, Synchronizer} = require './util/tools'
{Extension} = require './Extension'
{ExtensionPoint} = require './Crawler.ExtensionPoints'
{CrawlerContext, ContextAware} = require './Crawler.Context'
{ExtensionPointConnector, RequestItemMapper, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues'
{RequestStreamer} = require './extensions/core.streaming'
{QueueSystem} = require './QueueManager'
{UrlFilter} = require './extensions/core.filter'
{Phase} = require './RequestItem.Phases'
{RequestItem} = require './RequestItem'
{LogHub, LogConfig} = require './Logging'
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
    @log.info? "#{obj.print @config, 3}", tags: ['Config']
    @qs = new QueueSystem filename: "#{@config.basePath()}/#{@config.options.Queueing.filename}", log:@log
    # Create the root context of this crawler
    @context = new CrawlerContext
      config : @config
      crawler: @ # re-expose this crawler
      log    : @log
      qs : @qs

    @scheduler = new Scheduler @context, @config
    # Create and add extension points
    @extpoints = {}
    @extpoints[phase] = new ExtensionPoint @context, phase for phase in Phase.ALL
    @extensions = []

    # Core extensions that need to run BEFORE user extensions
    ExtensionPoint.addExtensions this, [
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

    @start() if @config.autostart

  # Initializes this extension point with the given context. Initialization cascades
  # to all contained extensions
  # @private
  initialize: ->
    for extension in @extensions
      extension.initialize(@context.fork())
      extension.verify()
      @log.info? extension.toString(), tags: ['Config']

  start: ->
    @log.info? "Starting Crawler"
    @context.messenger.publish 'commands.start'
    
      
  # Run shutdown logic on all extensions
  stop: ->
    @log.info? "Stopping Crawler"
    # Prevent new work from being submitted
    @context.execute = -> throw new Error "The crawler has been stopped!"
    @context.schedule = -> throw new Error "The crawler has been stopped!"
    # Stop all extensions and Scheduler
    @context.messenger.publish 'commands.stop', {}
    @wdog = setInterval (=>
      notFinished = @qs.items().inPhases [Phase.FETCHING, Phase.FETCHED]
      if notFinished.length is 0
        clearInterval @wdog
        @qs.save()
      ), 500

  shutdown: -> @stop()

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
  toString: ->
    "Crawler: " # TODO: List extension points and content

###
  The central object for configuring an instance of {Crawler}.
  @private
###
class CrawlerConfig



  ###
  @param config [Object] The configuration parameters
  @option config [String] name The name of the crawler
  @option config [Boolean] autostart Whether the start command is issued after initialization
  @option config [String] basedir The base directory used for all data (logs, offline storage etc.)
  @option config [Array<Extension>] extensions An array of user {Extension}s to be installed
  @option config.options [Object] Queueing Options for {QueueWorker} and {QueueConnector}
  @option config.options [Object] Streaming Options for {RequestStreamer}
  @option config.options [Object] Filtering Options for {RequestFilter} and {UrlFilter}
  @option config.options [Object] Logging The configuration for the {LogHub}
  ###
  constructor: (config = {}) ->
    @name      = "kermit"
    @basedir   = "/tmp/sloth"
    @autostart = true
    @extensions = [] # Clients can add extensions
    @options   = # Options of each core extension can be customized here
      Logging   : LogConfig.detailed
      Queueing   :
        filename : "#{obj.randomId()}-queue.json" # Options for the queuing system, see [QueueWorker] and [QueueConnector]
        limits : []
      Streaming: {} # Options for the {Streamer}
      Filtering  : {} # Options for item filtering, [RequestFilter],[DuplicatesFilter]
      Scheduling  : {} # Options for URL scheduling [Scheduler]
    obj.merge @, config
    @options.Logging = switch
      when _.isFunction config.options?.Logging then config.options.Logging "#{@basePath()}/logs"
      when _.isObject config.options?.Logging then config.options.Logging
      else LogConfig.detailed "#{@basePath()}/logs"

  # @return [String] The configured base path of this crawler
  basePath: -> "#{@basedir}/#{@name}"

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
  @include Synchronizer
  @include ContextAware

  @defaultOptions: ->
    maxWaiting : 50
    msPerUrl : 50

  # @nodoc
  constructor: (@context, @config) ->
    @importContext @context
    @urlFilter = new UrlFilter @config.options.Filtering, @log
    @opts = obj.overlay Scheduler.defaultOptions(), @config.options.Scheduling
    @messenger.subscribe 'commands.start', @start
    @messenger.subscribe 'commands.stop', =>
      @log.debug "Stopping Url scheduler #{@feeder}"
      clearInterval @feeder


  # @private
  # @nodoc
  schedule: (url, meta) ->
    @qs.urls().schedule url, meta unless url is null or not @urlFilter.isAllowed url, meta

  # Called by Crawler at startup
  # @private
  start: =>
    pushUrls = =>
      waiting = @qs.items().waiting().length
      if waiting < @opts.maxWaiting
        @synchronized =>
          urls = @qs.urls().scheduled @opts.maxWaiting - waiting
          @log.debug? "Retrieved url batch of size #{urls.length} for scheduling", tags:['Scheduler']
          @crawler.execute entry.url, entry.meta for entry in urls
    @feeder = setInterval pushUrls,  @opts.maxWaiting *  @opts.msPerUrl
    @feeder.unref()


module.exports = {
  Crawler
  ExtensionPoint
}