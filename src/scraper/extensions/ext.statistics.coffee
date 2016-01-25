{Status} = require('../CrawlRequest')
{Extension} = require '../Extension'
{obj} = require '../util/tools.coffee'
_ = require 'lodash'

###
  Generate and log runtime statistics on queueing system and
  request processing.
###
class Statistics extends Extension

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
    @counters.requests[status] = 0 for status in Status.ALL
    @counters.durations[status] = {total:0,min:100000,max:0,avg:0} for status in ['INITIAL', 'SPOOLED', 'READY', 'FETCHING', 'FETCHED']
    @opts = @merge Statistics.defaultOpts(), opts


  initialize: (context) ->
    super context
    @queue = @context.queue
    statsLogger = () =>
      try
        start = new Date()
        stats =  _.merge {}, @counters, {current: @queue.requestsByStatus(['READY', 'FETCHING'])}
        stats.requests.ACCEPTED = stats.requests.INITIAL - stats.requests.CANCELED
        waiting = @queue.requests.find(status: $in: ['INITIAL', 'SPOOLED']).length
        scheduled = @queue.urls.getDynamicView('scheduled').data().length
        duration = new Date() - start
        @log.info? "(#{duration}ms) SCHEDULED:#{scheduled} WAITING:#{waiting} READY:#{stats.current.READY} FETCHING:#{stats.current.FETCHING} COMPLETE:#{stats.requests.COMPLETE}", tags : ['Stats', 'Count']
        durations = ("#{status}(#{times.min},#{times.max},#{times.avg})" for status,times of stats.durations)
        @log.info? "Status(min,max,avg): #{durations}", tags : ['Stats', 'Duration']
      catch error
        @log.error? "Error during computation of statistics", error:error, trace: error.stack
    if @opts.enabled
      @log.info? "Statistics enabled at interval #{@opts.interval}"
      @stats = setInterval statsLogger, @opts.interval

  shutdown:() ->
    clearInterval @stats

  track: (request) ->
    @counters.requests[request.status()]++
    if not (request.isInitial() or request.isError() or request.isCanceled())
      preceedingStatus = Status.predecessor request.status()
      @counters.durations[preceedingStatus].total += request.durationOf preceedingStatus
      @counters.durations[preceedingStatus].min = Math.min @counters.durations[preceedingStatus].min, request.durationOf preceedingStatus
      @counters.durations[preceedingStatus].max = Math.max @counters.durations[preceedingStatus].max, request.durationOf preceedingStatus
      @counters.durations[preceedingStatus].avg = Math.floor(@counters.durations[preceedingStatus].total / @counters.requests[preceedingStatus])

module.exports = {
  Statistics
}