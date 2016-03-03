{Extension} = require '../Extension'
{obj} = require '../util/tools'

###
  Reduce risk of bot detection by introducing random pauses in {RequestItem} execution.
  Pauses are integrated according to configured delays (multiple delays are possible).
###
class RandomizedDelay extends Extension

  @defaultOptions: ->
    delays : [
      # ratio: 1/3 # ~ every third time
      # interval: 20000 # runs every 20 sec, i.e. ~ one pause per minute
      # duration: 10000 # pauses take 10 seconds
    ]

  constructor: (options = {}) ->
    super {}
    @options = @merge RandomizedDelay.defaultOptions(), options
    @randomizers = []

  initialize: (context) ->
    super context
    delayer = (delay) =>
      =>
        if Math.random() > 1 - delay.ratio # Delay hits
          @log.trace? "Delaying all fetching items for #{delay.duration}ms", tags:['RandomDelay']
          for entry in @qs.items().fetching() # Now delay all items ...(a)
            item = @context.items[entry.id]
            continue if item.delayed
            item.delayed = true # Remember that item has already been delayed
            @log.debug? "Delaying #{entry.url} for #{delay.duration}ms"
            oldFetch = item.fetched # ...(a) by replacing the fetch fnt with delayed version
            item.fetched = ->
              @log.debug? "Delayed fetch called for #{entry.url}"
              setTimeout (-> oldFetch.apply item), delay.duration
    @onStart => # schedule all delays
      for delay in @options.delays
        @log.info? "Scheduling delay #{obj.print delay}"
        @randomizers.push setInterval delayer(delay), delay.interval
    @onStop => # delete all delays
      clearInterval randomizerId for randomizerId in @randomizers


module.exports = {RandomizedDelay}