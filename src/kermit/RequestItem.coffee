URI = require 'urijs'
{Pipeline} = require './Pipeline'
{obj, uri} = require './util/tools'
_ = require 'lodash'

###

  A {RequestItem} is always in one of the following processing phases.
  Each item starts with phase {ProcessingPhase.INITIAL}
  From phase {INITIAL} it transitions forward while being processed by the {Extension}s
  that handle items of that particular phase. The following diagram illustrate the possible
  phase transitions with the ordinary flow {INITIAL} -> {SPOOLED} -> {READY} -> {FETCHING} -> {FETCHED} -> {COMPLETE}.
  Any item may also end in phases {CANCELED} or {ERROR} depending on the logic of the {Extension}s

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
@see ProcessingPhase and its subclasses for descriptions of
@abstract
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

  constructor: () ->
    @name = constructor.name

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
Process items with phase INITIAL.
This ProcessingPhase runs: Filtering, Connect to {QueueManager Queueing System}, User extensions
###
class INITIAL extends ProcessingPhase

###
Process items with phase "SPOOLED".
Spooled items are waiting in the {QueueManager} for further processing.
This ProcessingPhase runs: User extensions, {QueueManager}
###
class SPOOLED extends ProcessingPhase

###
Process items with phase "READY".
Request with phase "READY" are eligible to be fetched by the {Streamer}.
This ProcessingPhase runs: User extensions.
###
class READY extends ProcessingPhase

###
Process items with phase "FETCHING".
Http(s) call to URL is made and response is being streamed.
This ProcessingPhase runs: {RequestStreamer}, User extensions.
###
class FETCHING extends ProcessingPhase

###
Process items with phase "FETCHED".
All data has been received and the response is ready for further processing.
This ProcessingPhase runs: User extensions.
###
class FETCHED extends ProcessingPhase

###
Process items with phase "COMPLETE".
Response processing is finished. This is the terminal phase of a successfully processed
item. This ProcessingPhase runs: User extensions, {Cleanup}
###
class COMPLETE extends ProcessingPhase

###
Process items with phase "ERROR".
{ExtensionPoint}s will set this phase if an exception occurs during execution of an {Extension}.
This ProcessingPhase runs: User extensions, {Cleanup}
###
class ERROR extends ProcessingPhase

###
Process items with phase "CANCELED".
Any extension might cancel a item. Canceled items are not elligible for further processing
and will be cleaned up. This ProcessingPhase runs: User extensions, {Cleanup}
###
class CANCELED extends ProcessingPhase

###
  The RequestItem is the central object in the processing of a single URL. The {Crawler} will
  funnel each item through the different {ProcessingPhase}s - applying all {Extension}s registered
  for the particular phase.

  During its lifecycle the item is enriched with listeners and properties by the {Extension}s
  that take care of its processing.

  (Meta-)Information necessary for its processing is usually attached to the item in order
  to centralize state.

###
class RequestItem

  # @nodoc
  # @private
  notify = (item, property) ->
    listener(item) for listener in listeners(item, property)
    item
  # @nodoc
  # @private
  listeners = (item, property) ->
    if !item.changeListeners[property]?
      item.changeListeners[property] = []
    item.changeListeners[property]

  # @nodoc
  @stampsToString : (stamps) ->
    _.mapValues stamps, (stamps) ->
      first = "(#{stamps[0]})"
      rest = _.map _.tail(stamps), (value, index) -> (value - stamps[index]) + "ms"
      "#{first}#{rest}"

  # Create a new item for the given url and
  # with the given metadata attached
  constructor: (url, meta , @log) ->
    @changeListeners = {}
    @state =
      id : obj.randomId(20)
      stamps: {} # collect timestamps for tracking of meaningful state changes
      parents : 0
    @state = obj.merge @state, meta
    @phase ProcessingPhase.INITIAL
    @url url

  # Register a listener {Function} to be invoked whenever the
  # specified property value is changed
  # @param property [String] The name of the property to watch
  # @param listener [Function] The handler to be invoked whenever the property
  # changes. The post-change state of the item will be passed to the handler
  # @return [RequestItem] This item
  onChange: (property, listener) ->
    listeners(this, property).push listener; this

  # Get the string representation of the uri
  # @return [String] The URI as string
  url: (url) ->
    if url then @state.url = uri.normalize url else @state.url

  # @return [String] The synthetic id of this item
  id: () -> @state.id

  # Check whether https should be used to fetch this item  
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
      @stamps('COMPLETE')[0] - @stamps('INITIAL')[0]
    catch error
      # This error occurs if a stamp did not exist
      -1

  # Register a change listener for a specific value of the phase property
  # @param phase [String] The phase value that will trigger invocation of the listener
  # @param listener [Function] The listener to be invoked if phase changes
  # @return [RequestItem] This item
  onPhase: (phase, listener) ->
    @onChange 'phase', (item) ->
      listener(item) if item.phase() is phase

  # Change the items phase to SPOOLED
  # @return {RequestItem} This item
  # @throw Error if item does have other phase than INITIAL
  spool: ->
    if @isInitial() then @phase(ProcessingPhase.SPOOLED);this
    else throw new Error "Transition from #{@state.phase} to SPOOLED not allowed"

  # Change the items phase to READY
  # @return {RequestItem} This item
  # @throw Error if item does have other phase than SPOOLED
  ready: ->
    if @isSpooled() then @phase(ProcessingPhase.READY);this
    else throw new Error "Transition from #{@state.phase} to READY not allowed"

  # Change the items phase to FETCHING
  # @return {RequestItem} This item
  # @throw Error if item does have other phase than READY
  fetching: () ->
    if @isReady() then @phase(ProcessingPhase.FETCHING);this
    else throw new Error "Transition from #{@state.phase} to FETCHING not allowed"


  # Change the items phase to FETCHED
  # @return {RequestItem} This item
  # @throw Error if item item does have other phase than FETCHING
  fetched: () ->
    if @isFetching() then @phase(ProcessingPhase.FETCHED);this
    else throw new Error "Transition from #{@state.phase} to FETCHED not allowed"

  # Change the items phase to COMPLETE
  # @return {RequestItem} This item
  # @throw Error if item does have other phase than FETCHED
  complete: ->
    if @isFetched() then @phase(ProcessingPhase.COMPLETE);this
    else throw new Error "Transition from #{@state.phase} to COMPLETE not allowed"

  # Change the items phase to ERROR
  # @return {RequestItem} This item
  error: (error) ->
    @state.phase = ProcessingPhase.ERROR
    @errors ?= [];@errors.push error
    notify this, "phase"

  # Change the items phase to CANCELED
  # @return {RequestItem} This item
  cancel: ->
    @state.phase = ProcessingPhase.CANCELED
    notify this, "phase"

  # Check whether this item has phase INITIAL
  # @return {Boolean} True if phase is INITIAL, false otherwise
  isInitial: () -> @state.phase is ProcessingPhase.INITIAL
  # Check whether this item has phase SPOOLED
  # @return {Boolean} True if phase is SPOOLED, false otherwise
  isSpooled: () -> @state.phase is ProcessingPhase.SPOOLED
  # Check whether this item has phase READY
  # @return {Boolean} True if phase is READY, false otherwise
  isReady: () -> @state.phase is ProcessingPhase.READY
  # Check whether this item has phase FETCHING
  # @return {Boolean} True if phase is FETCHING, false otherwise
  isFetching: () -> @state.phase is ProcessingPhase.FETCHING
  # Check whether this item has phase FETCHED
  # @return {Boolean} True if phase is FETCHED, false otherwise
  isFetched: () -> @state.phase is ProcessingPhase.FETCHED
  # Check whether this item has phase COMPLETE
  # @return {Boolean} True if phase is COMPLETE, false otherwise
  isComplete: () -> @state.phase is ProcessingPhase.COMPLETE
  # Check whether this item has phase CANCELED
  # @return {Boolean} True if phase is CANCELED, false otherwise
  isCanceled: () -> @state.phase is ProcessingPhase.CANCELED
  # Check whether this item has phase ERROR
  # @return {Boolean} True if phase is ERROR, false otherwise
  isError: () -> @state.phase is ProcessingPhase.ERROR

  # Clean all item data that potentially occupies much memory
  cleanup: () ->
    @_pipeline?.cleanup()
    delete @changeListeners

  # Access the {Pipeline} of this item
  pipeline: () ->
    @_pipeline ?= new Pipeline @log, @

  # A item might have been created by another item (its parent).
  # That parent might in turn have been created by another item and so on.
  # @return {Number} The number of parents of this item
  parents: () ->
    @state.parents

  # Generate a human readable representation of this item
  toString: () ->
    pretty = switch @state.phase
        when 'INITIAL','SPOOLED','READY'
          """#{@state.phase} => GET #{@state.url} :#{obj.print RequestItem.stampsToString @state.stamps}"""
        when 'COMPLETE'
          """COMPLETE => GET #{@state.url} (status=#{@_pipeline?.status} duration=#{@timeToComplete()}ms)"""
        else "Unknown phase"

module.exports = {
  RequestItem
  Phase : ProcessingPhase
}