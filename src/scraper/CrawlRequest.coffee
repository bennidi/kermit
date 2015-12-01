URI = require 'urijs'
extensions = require './Extension'
Exceptions = extensions.ProcessingException

status =
  INITIAL:'INITIAL'
  SPOOLED:'SPOOLED'
  READY:'READY'
  FETCHING:'FETCHING'
  FETCHED:'FETCHED'
  COMPLETE:'COMPLETE'
  ERROR:'ERROR'
  CANCELED:'CANCELED'

class CrawlRequest

  @Status = status

  notify = (request, property) ->
    listener(request.state) for listener in listeners(request, property)

  listeners = (request, property) ->
    if !request.changeListeners[property]?
      request.changeListeners[property] = []
    request.changeListeners[property]  

  uniqueId = (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  constructor: (url, context, depth = 0) ->
    @state =
      uri:  URI(url)
      tsLastModified: new Date
      status: status.INITIAL
      id : uniqueId(20)
      depth : depth
    @changeListeners = {}
    @context = context

  onChange: (property, handler) ->
    listeners(this, property).push handler; this

  uri: (uri) ->
    if uri
      @state.uri = URI(uri)
    @state.uri

  url: () -> @uri().toString()

  
  # Change the status and call subscribed listeners
  status: (status) ->
    if status?
      console.log "Changing status to #{status}"
      @state.status = status
      notify this, "status"
    else @state.status

  spool: ->
    if @state.status is status.INITIAL
      @state.status = status.SPOOLED
      notify this, "status"
    else throw new Error "Transition from #{@state} to SPOOLED not allowed"

  ready: ->
    if @state.status is status.SPOOLED
      @state.status = status.READY
      notify this, "status"
    else throw new Error "Transition from #{@state} to READY not allowed"

  fetching: ->
    if @state.status is status.READY
      @state.status = status.FETCHING
      notify this, "status"
    else throw new Error "Transition from #{@state} to FETCHING not allowed"

  fetched: (body, response) ->
    if @state.status is status.FETCHING
      @body = body
      @respone = response
      @state.status = status.FETCHED
      notify this, "status"
    else throw new Error "Transition from #{@state} to FETCHED not allowed"

  complete: ->
    if @state.status is status.FETCHED
      @state.status = status.COMPLETE
      notify this, "status"
    else throw new Error "Transition from #{@state} to COMPLETE not allowed"

  error: (error) ->
    @state.status = status.ERROR
    notify this, "status"

  cancel: (reason) ->
    @state.status = status.CANCELED
    notify this, "status"

  isCanceled: () ->
    @state.status is status.CANCELED
    
  enqueue: (url) ->
    console.log "Subrequest to #{url}"
    @context.execute status.INITIAL, @subrequest url

  subrequest: (url) ->
    new CrawlRequest url, @context, @state.depth + 1

  depth: () -> @state.depth

module.exports = {
  CrawlRequest
  Status : status
}