{obj, uri, Synchronizer} = require './util/tools'
{Extension} = require './Extension'
{ExtensionPoint} = require './Crawler.ExtensionPoints'
{CrawlerContext, ContextAware} = require './Crawler.Context'
{ExtensionPointConnector, RequestItemMapper, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues'
{RequestStreamer} = require './extensions/core.streaming'
{QueueSystem} = require './QueueSystem'
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
  @include Synchronizer

  # Create a new crawler with the given options
  # @param options [Object] The configuration for this crawler.
  # @see CrawlerConfig
  constructor: (options = {}) ->
    # Use default options where no user defined options are given
    @running = false
    @commandQueue =  []
    @config = new CrawlerConfig options
    @log = new LogHub(@config.options.Logging).logger()
    @qs = new QueueSystem
      filename: "#{@config.basePath()}/#{@config.options.Queueing.filename}",
      log:@log
    # Create the root context of this crawler
    @context = new CrawlerContext
      config : @config
      crawler: @ # re-expose this crawler
      log    : @log
      qs : @qs
    @scheduler = new Scheduler @context, @config

    addExtensionPoints = =>
      @extpoints = {}
      @extpoints[phase] = new ExtensionPoint @context, phase for phase in Phase.ALL
      @extensions = []

    addExtensions = =>
      # Core extensions that need to run BEFORE user extensions
      ExtensionPoint.addExtensions this, [
        new ExtensionPointConnector
        new RequestItemMapper
        new QueueConnector @config.options.Queueing
        new QueueWorker @config.options.Queueing
        ]
      # Add client extensions
      @log.debug? "Installing user extensions #{(ext.name for ext in @config.extensions)}", tags:['Crawler']
      ExtensionPoint.addExtensions this, @config.extensions
      # Core extensions that need to run AFTER client extensions
      ExtensionPoint.addExtensions this, [
        new RequestStreamer @config.options.Streaming
        new Spooler
        new Completer
        new Cleanup]

    initializeExtensions = =>
      for extension in @extensions
        extension.initialize(@context.fork())
        extension.verify()




    addExtensionPoints()
    addExtensions()

    @qs.initialize =>
      # TODO: Move all commands on queue for execution as soon as crawler is initialized
      initializeExtensions()
      @start() if @config.autostart
    @log.info? @toString(), tags:['Crawler']

    # Usually this handler is considered back practice but in case of unhandled errors
    # of single items (in not so well behaved extensions :) general operation should continue.
    process.on 'uncaughtException', (error) =>
      # TODO: Keep track of error rate (errs/sec) and define threshold that will eventually start emergency exit
      @log.error? "Severe error! Please check log for details", {tags:['Uncaught'], error:error.toString(), stack:error.stack}

  # Start crawling. All queued commands will be executed after "commands.start" message
  # was sent to all listeners.
  start: ->
    @running = true
    @log.info? "Starting", tags: ['Crawler']
    @context.messenger.publish 'commands.start'
    command() for command in @commandQueue
    @commandQueue = []

    
  # Stop crawling. Unfinished {RequestItem}s will be brought into terminal phase {COMPLETE}, {CANCELED}, {ERROR}
  # with normal operation. {UrlScheduler} and {QueueWorker} and all other extensions will receive the "commands.stop" message.
  # {QueueSystem} will be persisted, then the optional callback will be invoked.
  stop: (done)->
    return if not @running
    @running = false
    @log.info? "Stopping", tags: ['Crawler']
    # Stop all extensions and Scheduler
    @context.messenger.publish 'commands.stop', {}
    @wdog = setInterval (=>
      unfinished = @qs.items().inPhases [Phase.FETCHING, Phase.FETCHED]
      if _.isEmpty unfinished
        clearInterval @wdog
        @qs.save()
        done?()
      ), 500

  # Stops the crawler then exits.
  shutdown: ->
    @stop -> process.exit()


  # Create a new {RequestItem} and start its processing
  # @return [RequestItem] The created item
  execute: (url, meta) ->
    if not @running
      cmd = => @execute url,meta
      @commandQueue.push cmd
      @log.debug? "Queued execution of #{url}. The queued command is transient and executed when start() is called"
    else
      @log.debug? "Executing #{url}"
      item = new RequestItem url, meta, @log
      ExtensionPoint.execute @, Phase.INITIAL, item

  # Add the url to the {Scheduler}
  schedule: (url, meta) ->
    if not @running
      cmd = => @execute url,meta
      @commandQueue.push cmd
      @log.debug? "Queued scheduling of #{url}. The queued command is transient and executed when start() is called"
    else
      @scheduler.schedule url, meta

  # Pretty print this crawler
  toString: ->
    asString = "Crawler with #{obj.print @config, 3}. Extensions =>"
    for extension in @extensions
      asString += "\n#{extension.toString()}"
    asString

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
        filename : "#{obj.randomId()}-queue" # Options for the queuing system, see [QueueWorker] and [QueueConnector]
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
    interval : 500

  # @nodoc
  constructor: (@context, @config) ->
    @importContext @context
    @nextUrls = []
    @urlFilter = new UrlFilter @config.options.Filtering, @log
    @opts = obj.overlay Scheduler.defaultOptions(), @config.options.Scheduling
    @messenger.subscribe 'commands.start', @start
    @messenger.subscribe 'commands.stop', =>
      @log.debug "Stopping", tags: ['Scheduler']
      clearInterval @scheduler


  # @private
  # @nodoc
  schedule: (url, meta) ->
    @qs.urls().schedule url, meta unless url is null or not @urlFilter.isAllowed url, meta

  # Called by Crawler at startup
  # @nodoc
  start: =>
    pushUrls = =>
      waiting = @qs.items().waiting().length
      missing = @opts.maxWaiting - waiting
      if missing > 0
        @synchronized =>
          if _.isEmpty @nextUrls
            @nextUrls = @nextUrls.concat @qs.urls().scheduled 500
          available = Math.min @nextUrls.length, missing
          for i in [1..available]
            next = @nextUrls.pop()
            @crawler.execute next.url, next.meta unless next is undefined
    @scheduler = setInterval pushUrls,  @opts.interval # run regularly to feed new URLs


module.exports = {
  Crawler
  ExtensionPoint
}