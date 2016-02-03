URI = require 'urijs'
{Pipeline} = require './Pipeline.coffee'
{obj, uri} = require './util/tools.coffee'
_ = require 'lodash'

###

  A {CrawlRequest} is always in one of the following processing phases.
  Each request starts with phase {ProcessingPhase.INITIAL}
  From phase {INITIAL} it transitions forward while being processed by the {Extension}s
  that handle requests of that particular phase. The following diagram illustrate the possible
  phase transitions with the ordinary flow {INITIAL} -> {SPOOLED} -> {READY} -> {FETCHING} -> {FETCHED} -> {COMPLETE}.
  Any request may also end in phases {CANCELED} or {ERROR} depending on the logic of the {Extension}s

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

@see Crawler for a list of core extensions applied at each phase
@see ExtensionPoint and its subclasses for descriptions of

###
class ProcessingPhase
  # @property [String] See {INITIAL}
  @INITIAL:'INITIAL'
  # @property [String] See {SPOOLED}
  @SPOOLED:'SPOOLED'
  # @property [String] See {READY}
  @READY:'READY'
  # @property [String] See {FETCHING}
  @FETCHING:'FETCHING'
  #@property [String] See {FETCHED}
  @FETCHED:'FETCHED'
  # @property [String] See {COMPLETE}
  @COMPLETE:'COMPLETE'
  # @property [String] See {ERROR}
  @ERROR:'ERROR'
  # @property [String] See {CANCELED}
  @CANCELED:'CANCELED'
  # @property [Array<String>] Collection of all defined phase
  @ALL: ['INITIAL', 'SPOOLED','READY','FETCHING','FETCHED','COMPLETE','ERROR','CANCELED']

  # Retrieve the expected succeeding phase for the given phase
  @follower : (phase) ->
    switch phase
      when 'INITIAL' then 'SPOOLED'
      when 'SPOOLED' then 'READY'
      when 'READY' then 'FETCHING'
      when 'FETCHING' then 'FETCHED'
      when 'FETCHED' then 'COMPLETE'
      when 'COMPLETE' then 'COMPLETE'
      when 'CANCELED' then 'CANCELED'
      when 'ERROR' then 'ERROR'
      else throw new Error "Unknown phase #{phase} has no follower"

  # Retrieve the preceeding phase for the given phase
  @predecessor : (phase) ->
    switch phase
      when 'INITIAL' then 'INITIAL'
      when 'SPOOLED' then 'INITIAL'
      when 'READY' then 'SPOOLED'
      when 'FETCHING' then 'READY'
      when 'FETCHED' then 'FETCHING'
      when 'COMPLETE' then 'FETCHED'
      when 'CANCELED' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHED']
      when 'ERROR' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
      else throw new Error "Unknown phase #{phase} has no predecessor"

###
  The crawl request is the central object in the process of fetching a single URL. The {Crawler} will
  funnel each request through the different processing phases - applying all {Extension}s registered
  for the particular phase.
  During its lifecycle the request is enriched with listeners and properties by the {Extension}s
  that take care of its processing.
  Any information necessary for request processing is usually to the request in order
  to centralize state. Any property added to its internal state {CrawlRequest#state} will be persistent
  after the next phase transition.

  > NOTE: It is not to be confused with an Http(s) request (which might be created in the lifespan of a crawl request).
###
class CrawlRequest

  # @nodoc
  # @private
  notify = (request, property) ->
    listener(request) for listener in listeners(request, property)
    request
  # @nodoc
  # @private
  listeners = (request, property) ->
    if !request.changeListeners[property]?
      request.changeListeners[property] = []
    request.changeListeners[property]

  # @nodoc
  @stampsToString : (stamps) ->
    _.mapValues stamps, (stamps) ->
      first = "(#{stamps[0]})"
      rest = _.map _.tail(stamps), (value, index) -> (value - stamps[index]) + "ms"
      "#{first}#{rest}"

  # Create a new request for the given url and
  # with the given metadata attached
  constructor: (url, meta = {parents : 0} , @log) ->
    @changeListeners = {}
    @state =
      id : obj.randomId(20)
      stamps: {} # collect timestamps for tracking of meaningful state changes
      meta : meta
    @phase ProcessingPhase.INITIAL
    @url url

  # Register a listener {Function} to be invoked whenever the
  # specified property value is changed
  # @param property [String] The name of the property to watch
  # @param listener [Function] The handler to be invoked whenever the property
  # changes. The post-change state of the request will be passed to the handler
  # @return [CrawlRequest] This request
  onChange: (property, listener) ->
    listeners(this, property).push listener; this

  # Get the string representation of the uri
  # @return [String] The URI as string
  url: (url) ->
    if url then @state.url = uri.normalize url else @state.url

  # @return [String] The synthetic id of this request
  id: () -> @state.id

  # Check whether https should be used to fetch this request  
  useSSL: () ->
    @url().startsWith 'https'

  # Change the phase and notify subscribed listeners
  # or retrieve the current phase value
  # @param phase [String] The phase value to set
  # @return [String] The current value of phase
  # @private
  phase: (phase) ->
    if phase?
      @stamp phase
      @state.phase = phase
      notify this, "phase"
    else @state.phase

  # Add a new timestamp to the collection of timestamps
  # for the given tag. Timestamps are useful to keep track of processing durations.
  stamp: (tag) ->
    @stamps(tag).push new Date().getTime();this

  # Get all timestamps stored for the given tag  
  stamps : (tag) ->
    @state.stamps[tag] ?= []

  # Compute the duration of a phase
  # @return [Number] The duration of the respective phase in ms or -1 if phase not completed
  durationOf : (phase) ->
    follower = ProcessingPhase.follower phase
    try
      @stamps(follower)[0] - @stamps(phase)[0]
    catch error
      # This error occurs if a stamp did not exist
      -1

  # Calculate processing time from INITIAL to COMPLETE
  timeToComplete : () ->
    return -1 if not @isComplete()
    try
      @stamps('INITIAL')[0] - @stamps('COMPLETE')[0]
    catch error
      # This error occurs if a stamp did not exist
      -1

  # Register a change listener for a specific value of the phase property
  # @param phase [String] The phase value that will trigger invocation of the listener
  # @param listener [Function] The listener to be invoked if phase changes
  # @return [CrawlRequest] This request
  onPhase: (phase, listener) ->
    @onChange 'phase', (request) ->
      listener(request) if request.phase() is phase

  # Change the requests phase to SPOOLED
  # @return {CrawlRequest} This request
  # @throw Error if request does have other phase than INITIAL
  spool: ->
    if @isInitial() then @phase(ProcessingPhase.SPOOLED);this
    else throw new Error "Transition from #{@state.phase} to SPOOLED not allowed"

  # Change the requests phase to READY
  # @return {CrawlRequest} This request
  # @throw Error if request does have other phase than SPOOLED
  ready: ->
    if @isSPOOLED() then @phase(ProcessingPhase.READY);this
    else throw new Error "Transition from #{@state.phase} to READY not allowed"

  # Change the requests phase to FETCHING
  # @return {CrawlRequest} This request
  # @throw Error if request does have other phase than READY
  fetching: () ->
    if @isReady() then @phase(ProcessingPhase.FETCHING);this
    else throw new Error "Transition from #{@state.phase} to FETCHING not allowed"


  # Change the requests phase to FETCHED
  # @return {CrawlRequest} This request
  # @throw Error if request request does have other phase than FETCHING
  fetched: () ->
    if @isFetching() then @phase(ProcessingPhase.FETCHED);this
    else throw new Error "Transition from #{@state.phase} to FETCHED not allowed"

  # Change the requests phase to COMPLETE
  # @return {CrawlRequest} This request
  # @throw Error if request does have other phase than FETCHED
  complete: ->
    if @isFetched() then @phase(ProcessingPhase.COMPLETE);this
    else throw new Error "Transition from #{@state.phase} to COMPLETE not allowed"

  # Change the requests phase to ERROR
  # @return {CrawlRequest} This request
  error: (error) ->
    @state.phase = ProcessingPhase.ERROR
    @errors ?= [];@errors.push error
    notify this, "phase"

  # Change the requests phase to CANCELED
  # @return {CrawlRequest} This request
  cancel: ->
    @state.phase = ProcessingPhase.CANCELED
    notify this, "phase"

  # Check whether this request has phase INITIAL
  # @return {Boolean} True if phase is INITIAL, false otherwise
  isInitial: () -> @state.phase is ProcessingPhase.INITIAL
  # Check whether this request has phase SPOOLED
  # @return {Boolean} True if phase is SPOOLED, false otherwise
  isSPOOLED: () -> @state.phase is ProcessingPhase.SPOOLED
  # Check whether this request has phase READY
  # @return {Boolean} True if phase is READY, false otherwise
  isReady: () -> @state.phase is ProcessingPhase.READY
  # Check whether this request has phase FETCHING
  # @return {Boolean} True if phase is FETCHING, false otherwise
  isFetching: () -> @state.phase is ProcessingPhase.FETCHING
  # Check whether this request has phase FETCHED
  # @return {Boolean} True if phase is FETCHED, false otherwise
  isFetched: () -> @state.phase is ProcessingPhase.FETCHED
  # Check whether this request has phase COMPLETE
  # @return {Boolean} True if phase is COMPLETE, false otherwise
  isComplete: () -> @state.phase is ProcessingPhase.COMPLETE
  # Check whether this request has phase CANCELED
  # @return {Boolean} True if phase is CANCELED, false otherwise
  isCanceled: () -> @state.phase is ProcessingPhase.CANCELED
  # Check whether this request has phase ERROR
  # @return {Boolean} True if phase is ERROR, false otherwise
  isError: () -> @state.phase is ProcessingPhase.ERROR

  # Clean all request data that potentially occupies much memory
  cleanup: () ->
    @_pipeline?.cleanup()
    delete @changeListeners

  # Access the {Pipeline} of this request
  pipeline: () ->
    @_pipeline ?= new Pipeline @log, @

  # A request might have been created by another request (its parent).
  # That parent might in turn have been created by another request and so on.
  # @return {Number} The number of parents of this request
  parents: () -> 0

  # Generate a human readable representation of this request
  toString: () ->
    pretty = switch @state.phase
        when 'INITIAL','SPOOLED','READY'
          """#{@state.phase} => GET #{@state.url} :#{obj.print CrawlRequest.stampsToString @state.stamps}"""
        when 'COMPLETE'
          """COMPLETE => GET #{@state.url} (phase=#{@_pipeline?.phase} duration=#{@timeToComplete()}ms)"""
        else "Unknown phase"

module.exports = {
  CrawlRequest
  Phase : ProcessingPhase
}