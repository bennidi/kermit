URI = require 'urijs'
extensions = require './Extension'
Exceptions = extensions.ProcessingException

status =
  INITIAL:'INITIAL'
  SPOOLED:'SPOOLED'
  READY:'READY'
  FETCHING:'FETCHING'
  FETCHED:'FETCHED'
  COMPLETE:'COMPLETED'
  ERROR:'ERROR'
  CANCELED:'CANCELED'
  ALL: ['INITIAL', 'SPOOLED','READY','FETCHING','FETCHED','COMPLETED','ERROR','CANCELED']

class CrawlRequest

  @Status = status

  notify = (request, property) ->
    listener(request) for listener in listeners(request, property)
    request

  listeners = (request, property) ->
    if !request.changeListeners[property]?
      request.changeListeners[property] = []
    request.changeListeners[property]  

  uniqueId = (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  constructor: (url, context, depth = 0) ->
    @_uri = URI(url)
    @state =
      url:  @_uri.toString()
      tsLastModified: new Date().getTime()
      status: status.INITIAL
      id : uniqueId(20)
      depth : depth
    @changeListeners = {}
    @context = context


  onChange: (property, handler) ->
    listeners(this, property).push handler; this

  uri: (uri) ->
    if uri
      @_uri = URI(uri)
      @state.url = @_uri.toString()
    @_uri

  url: () -> @state.url

  id: () -> @state.id

  # Change the status and call subscribed listeners
  status: (status) ->
    if status?
      @context.logger.info "#{@state.status}->#{status} [#{@url()}]"
      @state.status = status
      notify this, "status"
    else @state.status

  onStatus: (status, callback) ->
    @onChange 'status', (request) ->
      callback(request) if request.status() is status

  spool: ->
    if @isInitial()
      @status(status.SPOOLED)
    else throw new Error "Transition from #{@state} to SPOOLED not allowed"

  ready: ->
    if @isSpooled()
      @status(status.READY)
    else throw new Error "Transition from #{@state} to READY not allowed"

  fetching: ->
    if @isReady()
      @status(status.FETCHING)
    else throw new Error "Transition from #{@state} to FETCHING not allowed"

  fetched: (body, response) ->
    if @isFetching()
      @body = body
      @respone = response
      @status(status.FETCHED)
    else throw new Error "Transition from #{@state} to FETCHED not allowed"

  complete: ->
    if @isFetched()
      @status(status.COMPLETE)
    else throw new Error "Transition from #{@state} to COMPLETE not allowed"

  isInitial: () -> @state.status is status.INITIAL    
  isSpooled: () -> @state.status is status.SPOOLED    
  isReady: () -> @state.status is status.READY    
  isFetching: () -> @state.status is status.FETCHING    
  isFetched: () -> @state.status is status.FETCHED    
  isCompleted: () -> @state.status is status.COMPLETE    
  isCanceled: () -> @state.status is status.CANCELED    
  isError: () -> @state.status is status.ERROR    
      
  error: (error) ->
    @state.status = status.ERROR
    notify this, "status"

  cancel: (reason) ->
    @context.logger.info "CANCELED: #{reason}"
    @state.status = status.CANCELED
    notify this, "status"

  isCanceled: () ->
    @state.status is status.CANCELED
    
  enqueue: (url) ->
    @context.logger.info "Subrequest to #{url}"
    @context.execute status.INITIAL, @subrequest url

  subrequest: (url) ->
    new CrawlRequest url, @context, @state.depth + 1

  depth: () -> @state.depth

module.exports = {
  CrawlRequest
  Status : status
}