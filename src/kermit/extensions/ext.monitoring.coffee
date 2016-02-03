{Phase} = require('../CrawlRequest')
{Extension} = require '../Extension'
{obj} = require '../util/tools.coffee'
_ = require 'lodash'

###
  Generate and log runtime statistics on queueing system and
  request processing.
###
class Monitoring extends Extension

  @defaultOpts: () ->
    interval : 10000
    enabled : true

  constructor: (opts) ->
    super
      INITIAL : @track
      SPOOLED : @track
      READY : @track
      FETCHING : @track
      FETCHED : @track
      COMPLETE : @track
      ERROR : @track
      CANCELED : @track
    @counters =
      requests : {}
      durations: {}
    @counters.requests[phase] = 0 for phase in Phase.ALL
    @counters.durations[phase] = {total:0,min:100000,max:0,avg:0} for phase in ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
    @opts = @merge Monitoring.defaultOpts(), opts


  initialize: (context) ->
    super context
    @queue = @context.queue
    statsLogger = () =>
      try
        start = new Date()
        stats =  _.merge {}, @counters, {current: FETCHING: @queue.requests.getDynamicView('FETCHING').data().length}
        stats.requests.ACCEPTED = stats.requests.INITIAL - stats.requests.CANCELED
        waiting = @queue.requests.find(phase: $in: ['INITIAL', 'SPOOLED']).length
        scheduled = @queue.urls.getDynamicView('scheduled').data().length
        duration = new Date() - start
        @log.info? "(#{duration}ms) SCHEDULED:#{scheduled} WAITING:#{waiting} FETCHING:#{stats.current.FETCHING} COMPLETE:#{stats.requests.COMPLETE}", tags : ['Stats', 'Count']
        durations = ("#{phase}(#{times.min},#{times.max},#{times.avg})" for phase,times of stats.durations)
        @log.info? "#{durations}", tags : ['Stats', 'Duration']
      catch error
        @log.error? "Error during computation of statistics", error:error, trace: error.stack
    if @opts.enabled
      @log.info? "Statistics enabled at interval #{@opts.interval}"
      @stats = setInterval statsLogger, @opts.interval

  shutdown:() ->
    clearInterval @stats

  track: (request) ->
    count = @counters.requests[request.phase()]++
    if not (request.isInitial() or request.isError() or request.isCanceled())
      preceedingPhase = Phase.predecessor request.phase()
      duration = request.durationOf preceedingPhase
      if count % 500 is 0 # reset counters to emulate sliding window
        @counters.durations[preceedingPhase].total = duration
        @counters.durations[preceedingPhase].min = duration
        @counters.durations[preceedingPhase].max = duration
        @counters.durations[preceedingPhase].avg = (@counters.durations[preceedingPhase].avg + duration) / 2
      else
        @counters.durations[preceedingPhase].total += duration
        @counters.durations[preceedingPhase].min = Math.min @counters.durations[preceedingPhase].min, duration
        @counters.durations[preceedingPhase].max = Math.max @counters.durations[preceedingPhase].max, duration
        @counters.durations[preceedingPhase].avg = Math.floor(@counters.durations[preceedingPhase].total / @counters.requests[preceedingPhase])

module.exports = {
  Monitoring
}