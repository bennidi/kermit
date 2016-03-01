{Phase} = require('../RequestItem')
{Extension} = require '../Extension'
{obj} = require '../util/tools'
_ = require 'lodash'

###
  Generate and log runtime statistics on queueing system and
  item processing.
###
class Monitoring extends Extension

  @defaultOpts: ->
    interval : 10000
    enabled : true

  constructor: (opts) ->
    super
      INITIAL : (item) => @count Phase.INITIAL
      SPOOLED : (item) => @durationOf item, Phase.INITIAL, @count Phase.SPOOLED
      READY : (item) => @durationOf item, Phase.SPOOLED, @count Phase.READY
      FETCHING : (item) => @durationOf item, Phase.READY, @count Phase.FETCHING
      FETCHED : (item) => @durationOf item, Phase.FETCHING, @count Phase.FETCHED
      COMPLETE : (item) => @durationOf item, Phase.FETCHED, @count Phase.COMPLETE
      ERROR : (item) => @count Phase.ERROR
      CANCELED : (item) => @count Phase.CANCELED
    @counters =
      items : {}
      durations: {}
    @counters.items[phase] = 0 for phase in Phase.ALL
    @counters.durations[phase] = {total:0,min:100000,max:0,avg:0} for phase in ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
    @opts = @merge Monitoring.defaultOpts(), opts


  # Add stats counter at intervals
  initialize: (context) ->
    super context
    statsLogger = =>
      try
        start = new Date()
        stats =  _.merge {}, @counters, {current: FETCHING: @qs.items().fetching().length}
        stats.items.ACCEPTED = stats.items.INITIAL - stats.items.CANCELED
        waiting = @qs.items().waiting().length
        scheduled = @qs.urls().count 'scheduled'
        duration = new Date() - start
        @log.info? "(#{duration}ms) SCHEDULED:#{scheduled} WAITING:#{waiting} FETCHING:#{stats.current.FETCHING} COMPLETE:#{stats.items.COMPLETE}", tags : ['Stats', 'Count']
        durations = ("#{phase}(#{times.min},#{times.max},#{times.avg})" for phase, times of stats.durations)
        @log.info? "#{durations}", tags : ['Stats', 'Duration']
      catch error
        @log.error? "Error during computation of statistics", error:error, trace: error.stack
    @onStart =>
      if @opts.enabled
        @log.info? "Statistics enabled at interval #{@opts.interval}"
        @stats = setInterval statsLogger, @opts.interval
    @onStop => clearInterval @stats


  # Count the item (phase)
  count : (phase) ->
    @counters.items[phase]++

  # Compute the duration of the item phase and add to item counters
  durationOf: (item, preceedingPhase, count) ->
    duration = item.durationOf preceedingPhase
    if count % 500 is 0 # reset counters to emulate sliding window
      @counters.durations[preceedingPhase].total = duration
      @counters.durations[preceedingPhase].min = duration
      @counters.durations[preceedingPhase].max = duration
      @counters.durations[preceedingPhase].avg = (@counters.durations[preceedingPhase].avg + duration) / 2
    else
      @counters.durations[preceedingPhase].total += duration
      @counters.durations[preceedingPhase].min = Math.min @counters.durations[preceedingPhase].min, duration
      @counters.durations[preceedingPhase].max = Math.max @counters.durations[preceedingPhase].max, duration
      @counters.durations[preceedingPhase].avg = Math.floor(@counters.durations[preceedingPhase].total / @counters.items[preceedingPhase])

module.exports = {
  Monitoring
}