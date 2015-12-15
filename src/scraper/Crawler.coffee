{Extension} = require './Extension'
{ExtensionPointConnector, RequestLookup, Spooler, Completer, Cleanup} = require './extensions/core'
{QueueConnector, QueueWorker} = require './extensions/core.queues.coffee'
{RequestStreamer} = require './extensions/core.streaming.coffee'
{RequestFilter, DuplicatesFilter} = require './extensions/core.filter.coffee'
{Status, CrawlRequest, Status} = require './CrawlRequest'
bunyan = require 'bunyan'


# An extension point provides a mechanism to add functionality to the extension point provider.
# Extension points act as containers for {Extension} - the objects providing the actual extension
# code
# @abstract (An extension point should be subclassed)
class ExtensionPoint

  # Construct an extension point
  # @param phase [String] The phase that corresponds to the respective value of {RequestStatus}
  constructor: (@phase, @context) ->
    throw new Error("Please provide phase and description") if !@phase
    @extensions = []

  # Add an {Extension}s handler for the matching phase
  addExtension: (extension) ->
    @extensions.push extension
    this

  # Helper method to invoke all extensions for processing of a given request
  # @private
  callExtensions : (request)->
    for extension in @extensions
      try
        # An extension may cancel request processing
        if request.isCanceled()
          return false
        else
          extension.handlers[@phase].call(extension, request)
      catch error
        @context.log.error error, "Error in extension #{extension.name}"
        request.error(error)
        return false
    true

  # Execute all extensions for the given request
  # @param request [CrawlRequest] The request to be processed
  apply: (request) ->
    @callExtensions(request)
    request

# Extension point for extensions that process requests with status {RequestStatus.INITIAL}
#   * Filtering
#   * Connect to {QueueManager Queueing System}
#   * User extensions
class INITIAL extends ExtensionPoint
  @phase = Status.INITIAL
  # @nodoc
  constructor: (@context) ->
    super Status.INITIAL, @context

# Extension point for extensions that process requests with status "SPOOLED"
class SPOOLED extends ExtensionPoint
  @phase = Status.SPOOLED
  # @nodoc
  constructor: (@context) ->
    super Status.SPOOLED, @context

# Extension point for extensions that process requests with status "FETCHING"
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING
  # @nodoc
  constructor: (@context) ->
    super Status.FETCHING, @context

# Extension point for extensions that process requests with status "READY"
class READY extends ExtensionPoint
  @phase = Status.READY
  # @nodoc
  constructor: (@context) ->
    super Status.READY, @context

# Extension point for extensions that process requests with status "FETCHING"
class FETCHING extends ExtensionPoint
  @phase = Status.FETCHING
  # @nodoc
  constructor: (@context) ->
    super Status.FETCHING, @context

# Extension point for extensions that process requests with status "FETCHED"
class FETCHED extends ExtensionPoint
  @phase = Status.FETCHED
  # @nodoc
  constructor: (@context) ->
    super Status.FETCHED, @context

# Extension point for extensions that process requests with status "COMPLETE"
class COMPLETE extends ExtensionPoint
  @phase = Status.COMPLETE
  # @nodoc
  constructor: (@context) ->
    super Status.COMPLETE, @context

# Extension point for extensions that process requests with status "ERROR"
class ERROR extends ExtensionPoint
  @phase = Status.ERROR
  constructor: (@context) ->
    super Status.ERROR, @context

# Extension point for extensions that process requests with status "CANCELED"
class CANCELED extends ExtensionPoint
  @phase = Status.CANCELED
  # @nodoc
  constructor: (@context) ->
    super Status.CANCELED, @context

# A container for properties that need to be shared among all instances of {ExtensionPoint} and {Extension}
# of a given {Crawler}. Each {Crawler} has its own, distinct context that it passes to all its extension points.
#
# Any instance of {Extension} or {ExtensionPoint} may modify the context to expose additional functionality
# to other extensions or extension points
class CrawlerContext

  # Construct a new CrawlerContext
  #
  # @param [Object] config The configuration object for this context
  # @option config [Crawler] crawler The crawler that created this context
  # @option config [Function] execute A function handle to execute an extension point
  # @option config [bunyan.Logger] log A logger to handle log messages
  constructor: (config) ->
    @crawler = config.crawler
    @execute = config.execute
    @log = config.log
    @config = config.crawler.config

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

  # @nodoc
  defaultOpts : {
    name      : "kermit"
    basedir   : "/tmp/sloth"
    extensions: [] # Clients can add extensions
    options   : # Options of each core extension can be customized here
      Queue   : {} # Options for the queuing system, see [QueueWorker] and [QueueConnector]
      Streaming: {} # Options for the [Streamer]
      Filter  : {} # Options for request filtering, [RequestFilter],[DuplicatesFilter]
      Logging :
        Streams: []
  }

  # @param config [Object] The configuration parameters
  # @option config [String] name The name of the crawler
  # @option config [String] basedir The base directory used for all data (logs, offline storage etc.)
  # @option config [Array<Extension>] extensions An array of user {Extension}s to be installed
  # @option config.options [Object] Queue Options for {QueueWorker} and {QueueConnector}
  # @option config.options [Object] Streaming Options for {RequestStreamer}
  # @option config.options [Object] Filtering Options for {RequestFilter} and {DuplicatesFilter}
  constructor: (config = {}) ->
    config = Extension.mergeOptions @defaultOpts, config
    @name = config.name
    @basedir = config.basedir
    @extensions = config.extensions
    @options = config.options

# Overview of all available {ExtensionPoint}s - one for each distinct status
# in the {C} state diagram.
#
# Extensions are added to extension points during initialization.
#
# Core extensions are added automatically, user extensions are specified in the
# options of the constructor.
class ExtensionPoints
  # @property [ExtensionPoint]
  # Process requests in state INITIAL. See {INITIAL}
  @INITIAL : INITIAL
  # @property [ExtensionPoint]
  # Process requests in state FETCHING. See {FETCHING}
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
The Crawler coordinates execution of submitted {CrawlRequest} by applying all {Extension}s of
the {ExtensionPoint} that matches the request's current status.

All functionality for request handling, such as filtering, queueing, streaming, storing, logging etc.
is implemented as {Extension}s to {ExtensionPoint}s.

The crawler defines exactly one {ExtensionPoint} for each distinct value of {RequestStatus}.
Each extension point contains the processing steps carried out when the request changes its status
to the respective phase.

The processing of a request follows the {RequestStatus} transitions which are defined by the
{CrawlRequest}.

```txt

       Steps INITIAL
    --------------------
    - Filtering
    - Connect Queue     .-------------.       .------------.            Steps
    - User extensions   |   INITIAL   |       |  CANCELED  |          CANCELED
                        |-------------|       |------------|            ERROR
                        | Unprocessed |------>| Filtered   |          COMPLETED
                        |             |       | Duplicate  |     -------------------
                        '-------------'       |            |     - User extensions
       Steps SPOOLED          |               '------------'     - Cleanup
    --------------------      |
    - User extensions         v
                        .-------------.       .------------.           .-----------.
                        |   SPOOLED   |       |   ERROR    |           | COMPLETED |
                        |-------------|       |------------|           |-----------|
                        | Waiting for |------>| Processing |           | Done!     |
                        | free slot   |       | Error      |           |           |
                        '-------------'       '------------'           '-----------'
        Steps READY            |                     ^                       ^
    --------------------       |                     |                       |
    + User extensions          v                     |                       |
                        .-------------.       .-------------.          .-----------.
                        |    READY    |       |  FETCHING   |          |  FETCHED  |
                        |-------------|       |-------------|          |-----------|
                        | Ready for   |------>| Request     |--------->| Content   |
                        | fetching    |       | streaming   |          | received  |
                        '-------------'       '-------------'          '-----------'
                                              Steps FETCHING          Steps FETCHED
                                             ---------------------   -------------------
                                           + Request Streaming     + User extensions
                                           + User extensions

```
###
class Crawler

  fse = require 'fs-extra'

  addExtensions = (crawler, extensions = []) ->
    for extension in extensions
      extpoint(crawler, point).addExtension(extension) for point in extension.targets()
      crawler._extensions.push extension
  extpoint = (crawler, phase) ->
    if !crawler.extpoints[phase]?
      throw new Error "Extension point #{phase} does not exists"
    crawler.extpoints[phase]
  execute = (crawler, phase, request) ->
    process.nextTick ->
      extpoint(crawler, phase).apply request
    request

  defaultStreams = (basedir) ->
    [
      {
        stream: process.stdout
        level : 'trace'
      },
      {
        path : "#{basedir}/logs/full.log"
        level: 'trace'
      },
      {
        path : "#{basedir}/logs/error.log"
        level: 'error'
      },
      {
        path : "#{basedir}/logs/info.log"
        level: 'info'
      }
    ]

  buildLog = (streams) ->
    bunyan.createLogger
      name   : 'log',
      streams: streams

  # Create a new crawler with the given options
  # @param config [Object] The configuration for this crawler. See {CrawlerConfig}
  # @see {CrawlerConfig.defaultOpts}
  constructor: (config = {}) ->
    # Build and verify (TODO) options
    # Use default options where no user defined options are given
    @config = new CrawlerConfig config
    if @config.options.Logging.Streams.length is 0
      @config.options.Logging.Streams = defaultStreams @basePath()
    fse.mkdirsSync "#{@basePath()}/logs"

    # Create the root context of this crawler
    @context = new CrawlerContext
      crawler: this # re-expose this crawler
      execute: (phase, request) =>
        execute(@, phase, request)
      log    : buildLog @config.options.Logging.Streams, @basePath()

    # Create and add extension points
    @extpoints = {}
    @extpoints[ExtensionPoint.phase] = new ExtensionPoint @context for name, ExtensionPoint of ExtensionPoints
    @_extensions = []

    # Core extensions that need to run BEFORE user extensions
    addExtensions this, [
      new RequestFilter @config.options.Filter
      new ExtensionPointConnector
      new RequestLookup
      new QueueConnector @config.options.Queue
      new QueueWorker @config.options.Queue
      new DuplicatesFilter
      new RequestStreamer @config.options.Streamer]
    # Add client extensions
    @context.log.info "Installing user extensions #{(ext.name for ext in @config.extensions)}"
    addExtensions this, @config.extensions
    # Core extensions that need to run AFTER client extensions
    addExtensions this, [new Spooler, new Completer, new Cleanup]
    @initialize()


  # Initializes this extension point with the given context. Initialization cascades
  # to all contained extensions
  # @private
  initialize: () ->
    for extension in @_extensions
      subContext = @context.fork() # Each extension has its own context scope
      extension.initialize(subContext)
      extension.verify()

  # Run shutdown logic on all extensions
  shutdown: () ->
    @context.log.info 'Received shutdown signal'
    for extension in @_extensions
      try
        extension.shutdown?()
      catch error
        @context.log.error "Error in extension #{extension.name}. Message: #{error.message}"

  # @return [String] The configured base path of this crawler
  basePath: () -> "#{@config.basedir}/#{@config.name}"

  # Create a new {CrawlRequest} and start its processing
  # @return [CrawlRequest] The created request
  enqueue: (url) ->
    request = new CrawlRequest url, @context
    execute @, INITIAL.phase, request

  # Pretty print this crawler
  toString: () ->
    "Crawler: " # TODO: List extension points and content

module.exports = {
  Crawler
  ExtensionPoint
}