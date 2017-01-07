Promise = require 'bluebird'

class Lifecycle

  @IDLE = "IDLE"
  @STARTING = "STARTING"
  @RUNNING = "RUNNING"
  @STOPPING = "STOPPING"

  constructor: ->
    @_lcycle =
      status : Lifecycle.IDLE

  onStart:(fnc)->
    @_lcycle.onStart = fnc

  onStop:(fnc)->
    @_lcycle.onStop = fnc

  stop:->
    if @isIdle() or @isStopping() then return Promise.resolve true
    @_lcycle.status = Lifecycle.STOPPING
    new Promise (resolve) => resolve @_lcycle.onStop?()
      .then => @_lcycle.status = Lifecycle.IDLE

  start: ->
    if @isRunning() or @isStarting() then return Promise.resolve true
    @_lcycle.status = Lifecycle.STARTING
    new Promise (resolve) => resolve @_lcycle.onStart?()
      .then => @_lcycle.status = Lifecycle.RUNNING

  isRunning:-> @_lcycle.status is Lifecycle.RUNNING
  isStarting:-> @_lcycle.status is Lifecycle.STARTING
  isStopping:-> @_lcycle.status is Lifecycle.STOPPING
  isIdle:-> @_lcycle.status is Lifecycle.IDLE
  isBusy:-> not @isIdle()


module.exports = {Lifecycle}
