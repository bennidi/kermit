

class Lifecycle

  @IDLE = "IDLE"
  @STARTING = "STARTING"
  @RUNNING = "RUNNING"
  @STOPPING = "STOPPING"

  constructor: (opts={})->
    @_lcycle =
      status : Lifecycle.IDLE
      onStart: opts.onStart?.bind(@) or =>
      onStop: opts.onStop?.bind(@) or =>

  stop:(callback)->
    if @isIdle() or @isStopping() then return
    @_lcycle.status = Lifecycle.STOPPING
    @_lcycle.onStop? =>
      @_lcycle.status = Lifecycle.IDLE
      callback?()

  start: (callback)->
    if @isRunning() or @isStarting() then return
    @_lcycle.status = Lifecycle.STARTING
    @_lcycle.onStart? =>
      @_lcycle.status = Lifecycle.RUNNING
      callback?()

  isRunning:-> @_lcycle.status is Lifecycle.RUNNING
  isStarting:-> @_lcycle.status is Lifecycle.STARTING
  isStopping:-> @_lcycle.status is Lifecycle.STOPPING
  isIdle:-> @_lcycle.status is Lifecycle.IDLE
  isBusy:-> not @isIdle()


module.exports = {Lifecycle}
