{Extension} = require './Extension'
{INITIAL,SPOOLED,READY,FETCHING,FETCHED,COMPLETE,CANCELED,ERROR, ExtensionPoint} = require './Crawler.ExtensionPoints.coffee'
{ExtensionPointConnector, RequestLookup, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues.coffee'
{RequestStreamer} = require './extensions/core.streaming.coffee'
{QueueManager} = require './QueueManager.coffee'
{RequestFilter, UrlFilter} = require './extensions/core.filter.coffee'
{Status, CrawlRequest} = require './CrawlRequest'
{LogHub, LogConfig} = require './Logging.coffee'
{obj} = require './util/tools.coffee'

_ = require 'lodash'
fse = require 'fs-extra'


###
The Crawler coordinates execution of submitted {CrawlRequest} by applying all {Extension}s
matching the request's current status.

All functionality for request handling, such as filtering, queueing, streaming, storing, logging etc.
is implemented as {Extension}s to {ExtensionPoint}s.

Extensions are added to extension points during initialization. Core extensions are added automatically,
user extensions are specified in the options of the Crawler's constructor.

The crawler defines an extension point for each distinct value of {RequestStatus}.
Each ExtensionPoint wraps the processing steps carried out when the request status changes
to a new value. The status transitions implicitly define a request flow illustrated in the
diagram below.

```txt

  .-------------.
 |   INITIAL   |
 |-------------|
 | Unprocessed |
 |             |
 '-------------'   \
        |           \
        |            \
        |             v
        v             .--------------------.
 .-------------.      |  ERROR | CANCELED  |      .-----------.
 |  SPOOLED    |      |--------------------|      | COMPLETE  |
 |-------------|  --->| - Error            |      |-----------|
 | Waiting for |      | - Duplicate        |      | Done!     |
 | free slot   |      | - Blacklisted etc. |      |           |
 '-------------'      '--------------------'      '-----------'
        |             ^         ^          ^            ^
        |            /          |           \           |
        |           /           |            \          |
        v          /                          \         |
 .-------------.         .-------------.          .-----------.
 |    READY    |         |  FETCHING   |          |  FETCHED  |
 |-------------|         |-------------|          |-----------|
 | Ready for   |-------->| Request     |--------->| Content   |
 | fetching    |         | streaming   |          | received  |
 '-------------'         '-------------'          '-----------'


```
###
class Crawler

  # Create a new crawler with the given options
  # @param config [Object] The configuration for this crawler.
  # @see CrawlerConfig
  constructor: (config = {}) ->
# Use default options where no user defined options are given
    @config = new CrawlerConfig config
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
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint @context for ExtensionPoint in [INITIAL,SPOOLED,READY,FETCHING,FETCHED,COMPLETE,CANCELED,ERROR]
    @extensions = []

    # Core extensions that need to run BEFORE user extensions
    ExtensionPoint.addExtensions this, [
      new RequestFilter @config.options.Filtering
      new ExtensionPointConnector
      new RequestLookup
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
    # of single requests, operation should continue.
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
    @scheduler.shutdown()
    for extension in _(@extensions).reverse().value()
      try
        @log.info? "Calling shutdown on #{extension.name}"
        extension.shutdown?()
      catch error
        @log.error? "Error shutdown in extension #{extension.name}", {error : error.toString() stack: error.stack()}

# Create a new {CrawlRequest} and start its processing
# @return [CrawlRequest] The created request
  execute: (url, meta) ->
    @log.debug? "Executing #{url}"
    request = new CrawlRequest url, meta, @log
    ExtensionPoint.execute @, INITIAL.phase, request

  schedule: (url, meta) ->
    @log.debug? "Scheduling #{url}"
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

  # Create a new request and schedule its processing.
  # The new request is considered a successor of this request
  # @param url [String] The url for the new request
  # @return {CrawlRequest} The newly created request
  schedule : (url, meta) ->
    @crawler.schedule url, meta

  execute : (url, meta) =>
    @crawler.execute url, meta

  executeRequest : (request) ->
    ExtensionPoint.execute @crawler, request.status(), request

  # Create a child context that shares all properties with its parent context.
  # The child context exposes a method to share properties with all other child contexts
  # @return [CrawlerContext] A new child context of this context
  fork: () ->
    child = Object.create this
    child.share = (property, value) =>
      @[property] = value
    child

# The central object for configuring an instance of {Crawler}
class CrawlerConfig

  ###
  @example The default configuration
    name      : "kermit"
    basedir   : "/tmp/sloth"
    extensions: [] # Clients can add extensions
    options   : # Options of each core extension can be customized here
      Queue   : {} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the [Streamer]
      Filter  : {} # Options for request filtering, [RequestFilter],[DuplicatesFilter]
  ###
  @defaultOpts : () ->
    name      : "kermit"
    basedir   : "/tmp/sloth"
    extensions: [] # Clients can add extensions
    options   : # Options of each core extension can be customized here
      Logging   : LogConfig.detailed
      Queueing   : {filename : "#{obj.randomId()}-queue.json"} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the {Streamer}
      Filtering  : {} # Options for request filtering, [RequestFilter],[DuplicatesFilter]

  # @param config [Object] The configuration parameters
  # @option config [String] name The name of the crawler
  # @option config [String] basedir The base directory used for all data (logs, offline storage etc.)
  # @option config [Array<Extension>] extensions An array of user {Extension}s to be installed
  # @option config.options [Object] Queue Options for {QueueWorker} and {QueueConnector}
  # @option config.options [Object] Streaming Options for {RequestStreamer}
  # @option config.options [Object] Filtering Options for {RequestFilter} and {UrlFilter}
  # @option config.options [Object] Logging Options for {LogHub}
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

class Scheduler

  threshold = 50
  timePerUrl = 50

  constructor: (@crawler, @queue, @config) ->
    filterOpts =
      allow : _.filter @config.options.Filtering.allow, _.isRegExp
      deny : _.filter @config.options.Filtering.deny, _.isRegExp
    delete filterOpts.allow if _.isEmpty filterOpts.allow
    delete filterOpts.deny if _.isEmpty filterOpts.deny
    @urlFilter = new UrlFilter filterOpts, @crawler.log

  schedule: (url, meta) ->
    return if not @urlFilter.isAllowed(url) or @queue.isKnown url
    if @queue.requests.find(status: $in: ['INITIAL', 'SPOOLED']).length < threshold
      @crawler.execute url, meta
    else
      @queue.schedule url, meta

  start: () ->
    pushUrls = () =>
      waiting = @queue.requests.find(status: $in: ['INITIAL', 'SPOOLED']).length
      if waiting < threshold
        urls = @queue.nextUrlBatch(threshold - waiting)
        @crawler.log.debug? "Retrieved url batch of size #{urls.length} for scheduling", tags:['Scheduler']
        @crawler.execute entry.url, entry.meta for entry in urls
    @executor = setInterval pushUrls, threshold * timePerUrl
    @executor.unref()

  shutdown: () ->
    clearInterval @executor

module.exports = {
  Crawler
  ExtensionPoint
}