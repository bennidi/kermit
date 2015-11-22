urijs = require 'urijs'

class CrawlRequest

  constructor: (url) ->
    @state = { uri: urijs(url), tsLastModified: new Date, status: Status.CREATED }
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