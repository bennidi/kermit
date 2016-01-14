{Status} = require('../CrawlRequest')
{Extension} = require '../Extension'

###
  Generate and log runtime statistics on queueing system and
  request processing.
###
class Statistics extends Extension

  # @nodoc
  constructor: ()->
    super INITIAL : @apply

  initialize: (context) ->
    statsLogger = () =>
      try
        @log.debug? "#{JSON.stringify @queue.statistics()}", tags : ['Statistics']
      catch error
        @log.error? "Error during computation of statistics", error:error
    if @opts.statistics.interval > 0
      @log.debug? "Statistics enabled at interval #{@opts.statistics.interval}"
      @stats = setInterval statsLogger, @opts.statistics.interval
      @stats.unref()