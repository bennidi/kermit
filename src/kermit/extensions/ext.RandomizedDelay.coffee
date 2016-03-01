{Extension} = require '../Extension'

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
    @options = @merge RandomizedDelay.defaultOptions(), options
    @randomizers = []

  initialize: (context) ->
    super context
    delayer = (delay) =>
      =>
        if Math.random() > 1 - delay.ratio # Delay hits
          for entry in @qs.items().fetching() # Now delay all items ...(a)
            item = @context.items[entry.id]
            @log.debug? "Delaying #{entry.url} for #{delay.duration}ms"
            oldFetch = item.fetched # ...(a) by replacing the fetch fnt with delayed version
            item.fetched = -> setTimeout oldFetch, delay.duration
    @onStart => # schedule all delays
      for delay in @options.delays
        @randomizers.push setInterval delayer(delay), delay.interval
    @onStop => # delete all delays
      clearInterval randomizerId for randomizerId in @randomizers


module.exports = {RandomizedDelay}