urijs = require 'urijs'

class CrawlRequest

  uniqueId = (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length

  constructor: (url, id = uniqueId(20)) ->
    @state = { uri: urijs(url), tsLastModified: new Date, status: Status.CREATED, id }
    @changeListeners = {}

  onChange: (property, handler) ->
    @listeners(property).push handler
    @

  status: (status) ->
    if status?
      console.log "Changing status to #{status}"
      @state.status = status
      @notify "status"
    else @state.status

  spool: ->
    if @state.status is Status.CREATED
      @state.status = Status.SPOOLED
      @notify "status"

  notify: (property) ->
    listener(@state) for listener in @listeners(property)


  listeners: (property) ->
    if !@changeListeners[property]?
      @changeListeners[property] = []
    @changeListeners[property]

Status =
  CREATED:'CREATED'
  SPOOLED:'SPOOLED'
  FETCHING:'FETCHING'
  FETCHED:'FETCHED'
  COMPLETE:'COMPLETE'
  ERROR:'ERROR'

module.exports = {
  CrawlRequest
  Status
}