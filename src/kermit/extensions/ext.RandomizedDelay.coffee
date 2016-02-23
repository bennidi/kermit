{Extension} = require '../Extension'

class RandomizedDelay extends Extension

  @defaultOptions: ->
    ratio: 1/3
    averageDelayInMs: 10000
    interval: 20000

  constructor: (options = {}) ->
    super {}
    @options = @merge RandomizedDelay.defaultOptions(), options

  initialize: (context) ->
    super context
    randomizer = =>
      try
        if Math.random() > 1 - @options.ratio # Delay hit
          delay = @options.averageDelayInMs # TODO: make more random
          for entry in @qs.items().fetching()
            item = @context.items[entry.id]
            @log.debug? "Delaying #{entry.url} for #{delay}ms"
            oldFetch = item.fetched
            item.fetched = -> setTimeout oldFetch, delay
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @wdog = setInterval randomizer, @options.interval





module.exports = {RandomizedDelay}