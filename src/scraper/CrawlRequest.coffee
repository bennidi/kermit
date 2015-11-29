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
      status: CrawlRequest.Status.INITIAL
      id : uniqueId(20)
      depth : depth
    @changeListeners = {}
    @context = context

  onChange: (property, handler) ->
    listeners(this, property).push handler
    this

  uri: () -> @state.uri
  url: () -> @uri().toString()  

  # Change the status and call subscribed listeners
  status: (status) ->
    if status?
      console.log "Changing status to #{status}"
      @state.status = status
      notify this, "status"
    else @state.status

  spool: ->
    if @state.status is CrawlRequest.Status.INITIAL
      @state.status = CrawlRequest.Status.SPOOLED
      notify this, "status"
    else throw new Error "Transition from #{@state} to SPOOLED not allowed"

  ready: ->
    if @state.status is CrawlRequest.Status.SPOOLED
      @state.status = CrawlRequest.Status.READY
      notify this, "status"
    else throw new Error "Transition from #{@state} to READY not allowed"

  fetching: ->
    if @state.status is CrawlRequest.Status.READY
      @state.status = CrawlRequest.Status.FETCHING
      notify this, "status"
    else throw new Error "Transition from #{@state} to FETCHING not allowed"

  fetched: (body, response) ->
    if @state.status is CrawlRequest.Status.FETCHING
      @body = body
      @respone = response
      @state.status = CrawlRequest.Status.FETCHED
      notify this, "status"
    else throw new Error "Transition from #{@state} to FETCHED not allowed"

  complete: ->
    if @state.status is CrawlRequest.Status.FETCHED
      @state.status = CrawlRequest.Status.COMPLETE
      notify this, "status"
    else throw new Error "Transition from #{@state} to COMPLETE not allowed"

  error: (error) ->
    @state.status = CrawlRequest.Status.ERROR
    notify this, "status"

  cancel: (reason) ->
    @state.status = CrawlRequest.Status.CANCELED
    notify this, "status"
    throw new Exceptions Exceptions.REJECTED, reason, this

  enqueue: (url) ->
    console.log "Subrequest to #{url}"
    @context.crawler.execute CrawlRequest.Status.INITIAL, @subrequest url

  subrequest: (url) ->
    new CrawlRequest url, @context, @state.depth + 1

  depth: () -> @state.depth

module.exports = {
  CrawlRequest
  Status : status
}