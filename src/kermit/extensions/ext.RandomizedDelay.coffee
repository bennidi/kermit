{Extension} = require '../Extension'

class RandomizedDelay extends Extension

  @defaultOptions: ->
    delays : [
      ratio: 1/3
      interval: 20000
      duration: 10000
    ]

  constructor: (options = {}) ->
    @options = @merge RandomizedDelay.defaultOptions(), options
    @randomizers = []

  initialize: (context) ->
    super context
    randomizer = (delay) =>
      =>
        if Math.random() > 1 - delay.ratio # Delay hits
          for entry in @qs.items().fetching() # Now delay all items ...(a)
            item = @context.items[entry.id]
            @log.debug? "Delaying #{entry.url} for #{delay.duration}ms"
            oldFetch = item.fetched # ...(a) by replacing the fetch fnt with delayed version
            item.fetched = -> setTimeout oldFetch, delay.duration
    for delay in @options.delays
      @randomizers.push setInterval randomizer(delay), delay.interval

module.exports = {RandomizedDelay}