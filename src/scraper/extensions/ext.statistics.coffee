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
    @counters = total : {}
    @counters.total[status] = 0 for status in Status.ALL
    @opts = @merge Statistics.defaultOpts(), opts


  initialize: (context) ->
    super context
    @queue = @context.queue
    statsLogger = () =>
      try
        start = new Date().getTime()
        stats =  _.merge {}, @counters, {current: @queue.requestsByStatus(['READY', 'FETCHING'])}
        stats.total.ACCEPTED = stats.total.INITIAL - stats.total.CANCELED
        waiting = @queue.requests.find(status: $in: ['INITIAL', 'SPOOLED']).length
        scheduled = @queue.urls.getDynamicView('scheduled').data().length
        duration = start - new Date().getTime()
        @log.info? "(#{duration}ms) SCHEDULED: #{scheduled}, WAITING: #{waiting}, READY:#{stats.current.READY}, FETCHING:#{stats.current.FETCHING}, COMPLETED:#{stats.total.COMPLETE}", tags : ['Statistics']
      catch error
        @log.error? "Error during computation of statistics", error:error
    if @opts.enabled
      @log.info? "Statistics enabled at interval #{@opts.interval}"
      @stats = setInterval statsLogger, @opts.interval

  shutdown:() ->
    clearInterval @stats

  track: (request) ->
    @counters.total[request.state.status]++

module.exports = {
  Statistics
}