URI = require 'urijs'
{Response} = require './Response.coffee'
{RandomId} = require './util/utils.coffee'


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

# The crawl request is the central object of processing. It is not to be confused with an Http(s) request
# (which might be created during the processing of its corresponding crawl request).
# Each crawl request has a lifecycle determined by the state diagram as defined by the {Crawler}
# and its {ExtensionPoint}s.
# A crawl request encapsulates all of the state associated with the processing of a single request.
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

  constructor: (url, context, predecessors = 0) ->
    @_uri = URI(url)
    @state =
      url:  @_uri.toString()
      tsLastModified: new Date().getTime()
      id : RandomId(20)
      predecessors : predecessors
    @changeListeners = {}
    @context = context
    @log = context.log
    @response = new Response
    @status RequestStatus.INITIAL


  # Register a listener {Function} to be invoked whenever the
  # specified property value is changed
  # @param property [String] The name of the property to watch
  # @param listener [Function] The handler to be invoked whenever the property
  # changes. The post-change state of the request will be passed to the handler
  # @return [CrawlRequest] This request
  onChange: (property, listener) ->
    listeners(this, property).push listener; this

  # Get or set the URI of this request
  # @param uri [String] The uri to set or null if current value is to be read
  # @return {URI} The current value of this requests uri
  uri: (uri) ->
    if uri
      @_uri = URI(uri)
      @state.url = @_uri.toString()
    @_uri

  # Get the string representation of the uri
  # @return [String] The URI as string
  url: () -> @state.url

  # @return [String] The synthetic id of this request
  id: () -> @state.id

  # Check whether https should be used to fetch this request  
  useSSL: () ->
    @uri().protocol() is "https"

  # Change the status and notify subscribed listeners
  # or retrieve the current status value
  # @param status [String] The status value to set
  # @return [String] The current value of status
  # @private
  status: (status) ->
    if status?
      @log.trace? "#{status} [#{@url()}]"
      @state.status = status
      notify this, "status"
    else @state.status

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
    if @isInitial()
      @status(RequestStatus.SPOOLED);this
    else throw new Error "Transition from #{@state.status} to SPOOLED not allowed"

  # Change the requests status to READY
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than SPOOLED
  ready: ->
    if @isSPOOLED()
      @status(RequestStatus.READY);this
    else throw new Error "Transition from #{@state.status} to READY not allowed"

  # Change the requests status to FETCHING
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than READY
  fetching: (incomingMessage) ->
    if @isReady() then @status(RequestStatus.FETCHING)
    else throw new Error "Transition from #{@state.status} to FETCHING not allowed"
    @response.import incomingMessage
    incomingMessage
      .on 'error', (error) =>
        @log.error "Error while streaming", error:error
        @error(error)
      .on 'end', =>
        @fetched()
      .pipe @response.incoming
    this



  # Change the requests status to FETCHED
  # @return {CrawlRequest} This request
  # @throw Error if request request does have other status than FETCHING
  fetched: () ->
    if @isFetching()
      @status(RequestStatus.FETCHED);this
    else throw new Error "Transition from #{@state.status} to FETCHED not allowed"

  # Change the requests status to COMPLETE
  # @return {CrawlRequest} This request
  # @throw Error if request does have other status than FETCHED
  complete: ->
    if @isFetched()
      @status(RequestStatus.COMPLETE);this
    else throw new Error "Transition from #{@state.status} to COMPLETE not allowed"

  # Change the requests status to ERROR
  # @return {CrawlRequest} This request
  error: ->
    @state.status = RequestStatus.ERROR
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
  isCompleted: () -> @state.status is RequestStatus.COMPLETE
  # Check whether this request has status CANCELED
  # @return {Boolean} True if status is CANCELED, false otherwise
  isCanceled: () -> @state.status is RequestStatus.CANCELED
  # Check whether this request has status ERROR
  # @return {Boolean} True if status is ERROR, false otherwise
  isError: () -> @state.status is RequestStatus.ERROR


  enqueue: (url) ->
    @context.execute RequestStatus.INITIAL, @subrequest url

  # Create a new request
  # The new request is considered a successor of this request
  # @param url [String] The url for the new request
  # @return {CrawlRequest} The newly created request
  subrequest: (url) ->
    new CrawlRequest url, @context, @state.predecessors + 1

  # A request might have been created by another request (its predecessor).
  # That predecessor might in turn have been created by another request and so on.
  # @return {Number} The number of predecessors of this request
  predecessors: () -> @state.predecessors

module.exports = {
  CrawlRequest
  Status : RequestStatus
}