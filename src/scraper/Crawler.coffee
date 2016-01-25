{Extension} = require './Extension'
{ExtensionPointConnector, RequestLookup, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues.coffee'
{RequestStreamer} = require './extensions/core.streaming.coffee'
{QueueManager} = require './QueueManager.coffee'
{RequestFilter, UrlFilter} = require './extensions/core.filter.coffee'
{Status, CrawlRequest} = require './CrawlRequest'
{LogHub, LogAppender, FileAppender, ConsoleAppender} = require './util/Logging.coffee'
_ = require 'lodash'
{obj} = require './util/tools.coffee'
fse = require 'fs-extra'

# An extension point provides a mechanism to add functionality to the extension point provider.
# Extension points act as containers for {Extension} - the objects providing the actual extension
# code
# @abstract (An extension point should be subclassed)
class ExtensionPoint

  @addExtensions : (crawler, extensions = []) ->
    for extension in extensions
      ExtensionPoint.extpoint(crawler, point).addExtension(extension) for point in extension.targets()
      crawler._extensions.push extension
  @extpoint : (crawler, phase) ->
    if !crawler.extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    crawler.extpoints[phase]
  @execute : (crawler, phase, request) ->
    process.nextTick ExtensionPoint.extpoint(crawler, phase).apply, request
    request

  # Construct an extension point
  # @param phase [String] The phase that corresponds to the respective value of {RequestStatus}
  constructor: (@context) ->
    @phase = @constructor.phase
    throw new Error("Please provide phase and description") if !@constructor.phase
    @log = @context.log
    @extensions = []

  # Add an {Extension}s handler for the matching phase
  addExtension: (extension) ->
    @extensions.push extension
    this

  # Helper method to invoke all extensions for processing of a given request
  # @private
  callExtensions : (request) ->
    for extension in @extensions
      try
        # An extension may cancel request processing
        if request.isCanceled()
          return false
        else
          extension.handlers[@phase].call(extension, request)
      catch error
        @log.error error.toString(), { trace: error.stack, tags: [extension.name]}
        request.error(error)
        return false
    true

  # Execute all extensions for the given request
  # @param request [CrawlRequest] The request to be processed
  apply: (request) =>
    @callExtensions(request)
    request

###
Process requests with status {RequestStatus.INITIAL}.
This ExtensionPoint runs: Filtering, Connect to {QueueManager Queueing System}, User extensions
###
class INITIAL extends ExtensionPoint
  @phase = Status.INITIAL

###
Process requests with status "SPOOLED".
Spooled requests are waiting in the {QueueManager} for further processing.
This ExtensionPoint runs: User extensions, {QueueManager}
###
class SPOOLED extends ExtensionPoint
  @phase = Status.SPOOLED

###
Process requests with status "READY".
Request with status "READY" are eligible to be fetched by the {Streamer}.
This ExtensionPoint runs: User extensions.
###
class READY extends ExtensionPoint
  @phase = Status.READY

###
Process requests with status "FETCHING".
Http(s) call to URL is made and response is being streamed.
This ExtensionPoint runs: {RequestStreamer}, User extensions.
###
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING

###
Process requests with status "FETCHED".
All data has been received and the response is ready for further processing.
This ExtensionPoint runs: User extensions.
###
class FETCHED extends ExtensionPoint
  @phase = Status.FETCHED

###
Process requests with status "COMPLETE".
Response processing is finished. This is the terminal status of a successfully processed
request. This ExtensionPoint runs: User extensions, {Cleanup}
###
class COMPLETE extends ExtensionPoint
  @phase = Status.COMPLETE

###
Process requests with status "ERROR".
{ExtensionPoint}s will set this status if an exception occurs during execution of an {Extension}.
This ExtensionPoint runs: User extensions, {Cleanup}
###
class ERROR extends ExtensionPoint
  @phase = Status.ERROR

###
Process requests with status "CANCELED".
Any extension might cancel a request. Canceled requests are not elligible for further processing
and will be cleaned up. This ExtensionPoint runs: User extensions, {Cleanup}
###
class CANCELED extends ExtensionPoint
  @phase = Status.CANCELED

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

  logconfig = (basedir) ->
    basedir: basedir
    levels : ['trace', 'info', 'error', 'debug', 'warn']
    destinations: [
      {
        appender:
          type : 'console'
        levels : ['trace', 'error', 'info', 'debug', 'warn']
      },
      {
        appender :
          type : 'file'
          filename : "#{basedir}/full.log"
        levels: ['trace', 'error', 'info', 'debug']
      },
      {
        appender :
          type : 'file'
          filename : "#{basedir}/error.log"
        levels: ['error', 'warn']
      },
      {
        appender :
          type : 'file'
          filename : "#{basedir}/debug.log"
        levels: ['debug']
      },
      {
        appender :
          type : 'file'
          filename : "#{basedir}/trace.log"
        levels: ['trace']
      }
    ]


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
      Queueing   : {dbfile : "#{obj.randomId()}-queue.json"} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the [Streamer]
      Filtering  : {} # Options for request filtering, [RequestFilter],[DuplicatesFilter]

  # @param config [Object] The configuration parameters
  # @option config [String] name The name of the crawler
  # @option config [String] basedir The base directory used for all data (logs, offline storage etc.)
  # @option config [Array<Extension>] extensions An array of user {Extension}s to be installed
  # @option config.options [Object] Queue Options for {QueueWorker} and {QueueConnector}
  # @option config.options [Object] Streaming Options for {RequestStreamer}
  # @option config.options [Object] Filtering Options for {RequestFilter} and {DuplicatesFilter}
  constructor: (config = {}) ->
    config = _.merge {}, CrawlerConfig.defaultOpts(), config
    @name = config.name
    @basedir = config.basedir
    @extensions = config.extensions
    @options = config.options
    @options.Logging = logconfig("#{@basePath()}/logs")

  # @return [String] The configured base path of this crawler
  basePath: () -> "#{@basedir}/#{@name}"

###
Overview of all available {ExtensionPoint}s - one for each distinct status
in the {Crawler} state diagram.

Extensions are added to extension points during initialization.

Core extensions are added automatically, user extensions are specified in the
options of the Crawler's constructor.
###
class ExtensionPoints
  # @property [ExtensionPoint]
  # Process requests in state INITIAL. See {INITIAL}
  @INITIAL : INITIAL
  # @property [ExtensionPoint]
  # Process requests in state SPOOLED. See {SPOOLED}
  @SPOOLED : SPOOLED
  # @property [ExtensionPoint]
  # Process requests in state READY. See {READY}
  @READY : READY
  # @property [ExtensionPoint]
  # Process requests in state FETCHING. See {FETCHING}
  @FETCHING : FETCHING
  # @property [ExtensionPoint]
  # Process requests in state FETCHED. See {FETCHED}
  @FETCHED : FETCHED
  # @property [ExtensionPoint]
  # Process requests in state COMPLETE. See {COMPLETE}
  @COMPLETE : COMPLETE
  # @property [ExtensionPoint]
  # Process requests in state ERROR. See {ERROR}
  @ERROR : ERROR
  # @property [ExtensionPoint]
  # Process requests in state CANCELED. See {CANCELED}
  @CANCELED : CANCELED

###
The Crawler coordinates execution of submitted {CrawlRequest} by applying all {Extension}s
matching the request's current status.

All functionality for request handling, such as filtering, queueing, streaming, storing, logging etc.
is implemented as {Extension}s to {ExtensionPoint}s.

The crawler defines an ExtensionPoint for each distinct value of {RequestStatus}.
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
 |  SPOOLED    |      |--------------------|      | COMPLETED |
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
  # @param config [Object] The configuration for this crawler. See {CrawlerConfig}
  # @see CrawlerConfig.defaultOpts
  constructor: (config = {}) ->
    # Use default options where no user defined options are given
    @config = new CrawlerConfig config
    @log = new LogHub(@config.options.Logging).logger()
    @queue = new QueueManager "#{@config.basePath()}/#{@config.options.Queueing.dbfile}"
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
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint @context for name, ExtensionPoint of ExtensionPoints
    @_extensions = []

    # Core extensions that need to run BEFORE user extensions
    ExtensionPoint.addExtensions this, [
      new RequestFilter @config.options.Filtering
      new ExtensionPointConnector
      new RequestLookup
      new QueueConnector @config.options.Queueing
      new QueueWorker @config.options.Queueing
      new RequestStreamer @config.options.Streaming]
    # Add client extensions
    @log.info? "Installing user extensions #{(ext.name for ext in @config.extensions)}"
    ExtensionPoint.addExtensions this, @config.extensions
    # Core extensions that need to run AFTER client extensions
    ExtensionPoint.addExtensions this, [new Spooler, new Completer, new Cleanup]
    @initialize()
    # Usually this handler is considered back practice but in case of processing errors
    # of single requests, operation should continue.
    process.on 'uncaughtException', (error) =>
      @log.error? "Severe error! Please check log for details", {tags:['Uncaught'], error:error.toString(), stack:error.stack}


  # Initializes this extension point with the given context. Initialization cascades
  # to all contained extensions
  # @private
  initialize: () ->
    @scheduler.start()
    for extension in @_extensions
      extension.initialize(@context.fork())
      extension.verify()
      @log.info? extension.toString(), tags: ['Configuration']

  # Run shutdown logic on all extensions
  shutdown: () ->
    @scheduler.shutdown()
    for extension in _(@_extensions).reverse().value()
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


class Scheduler

  threshold = 200

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
      if @queue.requests.find(status: $in: ['INITIAL', 'SPOOLED']).length < threshold
        urls = @queue.nextUrlBatch()
        @crawler.log.debug? "Retrieved url batch of size #{urls.length} for scheduling", tags:['Scheduler']
        @crawler.execute entry.url, entry.meta for entry in urls
    @executor = setInterval pushUrls, 5000
    @executor.unref()

  shutdown: () ->
    clearInterval @executor

module.exports = {
  Crawler
  ExtensionPoint
}