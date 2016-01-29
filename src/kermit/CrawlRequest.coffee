URI = require 'urijs'
{Pipeline} = require './Pipeline.coffee'
{obj, uri} = require './util/tools.coffee'
_ = require 'lodash'


# At any time, each request has a status value equal to one of the values
# defined by this class. Any request starts with status {RequestStatus.INITIAL}
# From status {RequestStatus.INITIAL} it transitions forward while being processed by the {Extension}s
# that handle requests of that particular status.
# See {Crawler} for a complete state diagram of the status transitions
class RequestStatus
  # @property [String] @see INITIAL
  @INITIAL:'INITIAL'
  # @property [String] @see SPOOLED
  @SPOOLED:'SPOOLED'
  # @property [String] @see READY
  @READY:'READY'
  # @property [String] @see FETCHING
  @FETCHING:'FETCHING'
  #@property [String] @see FETCHED
  @FETCHED:'FETCHED'
  # @property [String] @see COMPLETE
  @COMPLETE:'COMPLETE'
  # @property [String] @see ERROR
  @ERROR:'ERROR'
  # @property [String] @see CANCELED
  @CANCELED:'CANCELED'
  # @property [Array<String>] Collection of all defined status'
  @ALL: ['INITIAL', 'SPOOLED','READY','FETCHING','FETCHED','COMPLETE','ERROR','CANCELED']

  # Retrieve the expected succeeding status for the given status
  @follower : (status) ->
    switch status
      when 'INITIAL' then 'SPOOLED'
      when 'SPOOLED' then 'READY'
      when 'READY' then 'FETCHING'
      when 'FETCHING' then 'FETCHED'
      when 'FETCHED' then 'COMPLETE'
      when 'COMPLETE' then 'COMPLETE'
      when 'CANCELED' then 'CANCELED'
      when 'ERROR' then 'ERROR'
      else throw new Error "Unknown status #{status} has no follower"

  # Retrieve the preceeding status for the given status
  @predecessor : (status) ->
    switch status
      when 'INITIAL' then 'INITIAL'
      when 'SPOOLED' then 'INITIAL'
      when 'READY' then 'SPOOLED'
      when 'FETCHING' then 'READY'
      when 'FETCHED' then 'FETCHING'
      when 'COMPLETE' then 'FETCHED'
      when 'CANCELED' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHED']
      when 'ERROR' then ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
      else throw new Error "Unknown status #{status} has no predecessor"

# The crawl request is the central object of processing. It is not to be confused with an Http(s) request
# (which might be created in the lifespan of a crawl request).
# Each crawl request has a lifecycle determined by the state diagram as defined by the {Crawler}
# and its {ExtensionPoint}s.
# During its lifecycle the request is enriched with listeners and properties by the {Extension}s
# that take care of its processing.
# Any information necessary for request processing is usually to the request in order
# to centralize state. Any property added to its internal state {CrawlRequest#state} will be persistent
# after the next status transition.
class CrawlRequest

  notify = (request, property) ->
    listener(request) for listener in listeners(request, property)
    request

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


  constructor: (url, meta = {parents : 0} , @log) ->
    @changeListeners = {}
    @state =
      id : obj.randomId(20)
      stamps: {} # collect timestamps for tracking of meaningful state changes
      meta : meta
    @status RequestStatus.INITIAL
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

  # Change the status and notify subscribed listeners
  # or retrieve the current status value
  # @param status [String] The status value to set
  # @return [String] The current value of status
  # @private
  status: (status) ->
    if status?
      @stamp status
      @state.status = status
      notify this, "status"
    else @state.status

  # Add a new timestamp to the collection of timestamps
  # for the given tag. Timestamps are useful to keep track of processing durations.
  stamp: (tag) ->
    @stamps(tag).push new Date().getTime();this

  # Get all timestamps stored for the given tag  
  stamps : (tag) ->
    @state.stamps[tag] ?= []

  # Compute the duration of a phase
  # @return [Number] The duration of the respective phase in ms or -1 if phase not completed
  durationOf : (status) ->
    follower = RequestStatus.follower status
    try
      @stamps(follower)[0] - @stamps(status)[0]
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

  # Register a change listener for a specific value of the status property
  # @param status [String] The status value that will trigger invocation of the listener
  # @param listener [Function] The listener to be invoked if status changes
  # @return [CrawlRequest] This request
  onStatus: (status, listener) ->
    @onChange 'status', (request) ->
      listener(request) if request.status() is status

  # Change the requests status to SPOOLED
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than INITIAL
  spool: ->
    if @isInitial() then @status(RequestStatus.SPOOLED);this
    else throw new Error "Transition from #{@state.status} to SPOOLED not allowed"

  # Change the requests status to READY
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than SPOOLED
  ready: ->
    if @isSPOOLED() then @status(RequestStatus.READY);this
    else throw new Error "Transition from #{@state.status} to READY not allowed"

  # Change the requests status to FETCHING
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than READY
  fetching: () ->
    if @isReady() then @status(RequestStatus.FETCHING);this
    else throw new Error "Transition from #{@state.status} to FETCHING not allowed"


  # Change the requests status to FETCHED
  # @return {CrawlRequest} This request
  # @throw Error if request request does have other status than FETCHING
  fetched: () ->
    if @isFetching() then @status(RequestStatus.FETCHED);this
    else throw new Error "Transition from #{@state.status} to FETCHED not allowed"

  # Change the requests status to COMPLETE
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than FETCHED
  complete: ->
    if @isFetched() then @status(RequestStatus.COMPLETE);this
    else throw new Error "Transition from #{@state.status} to COMPLETE not allowed"

  # Change the requests status to ERROR
  # @return {CrawlRequest} This request
  error: (error) ->
    @state.status = RequestStatus.ERROR
    @errors ?= [];@errors.push error
    notify this, "status"

  # Change the requests status to CANCELED
  # @return {CrawlRequest} This request
  cancel: ->
    @state.status = RequestStatus.CANCELED
    notify this, "status"

  # Check whether this request has status INITIAL
  # @return {Boolean} True if status is INITIAL, false otherwise
  isInitial: () -> @state.status is RequestStatus.INITIAL
  # Check whether this request has status SPOOLED
  # @return {Boolean} True if status is SPOOLED, false otherwise
  isSPOOLED: () -> @state.status is RequestStatus.SPOOLED
  # Check whether this request has status READY
  # @return {Boolean} True if status is READY, false otherwise
  isReady: () -> @state.status is RequestStatus.READY
  # Check whether this request has status FETCHING
  # @return {Boolean} True if status is FETCHING, false otherwise
  isFetching: () -> @state.status is RequestStatus.FETCHING
  # Check whether this request has status FETCHED
  # @return {Boolean} True if status is FETCHED, false otherwise
  isFetched: () -> @state.status is RequestStatus.FETCHED
  # Check whether this request has status COMPLETE
  # @return {Boolean} True if status is COMPLETE, false otherwise
  isComplete: () -> @state.status is RequestStatus.COMPLETE
  # Check whether this request has status CANCELED
  # @return {Boolean} True if status is CANCELED, false otherwise
  isCanceled: () -> @state.status is RequestStatus.CANCELED
  # Check whether this request has status ERROR
  # @return {Boolean} True if status is ERROR, false otherwise
  isError: () -> @state.status is RequestStatus.ERROR

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
    pretty = switch @state.status
        when 'INITIAL','SPOOLED','READY'
          """#{@state.status} => GET #{@state.url} :#{obj.print CrawlRequest.stampsToString @state.stamps}"""
        when 'COMPLETE'
          """COMPLETE => GET #{@state.url} (status=#{@_pipeline?.status} duration=#{@timeToComplete()}ms)"""
        else "Unknown status"

module.exports = {
  CrawlRequest
  Status : RequestStatus
}