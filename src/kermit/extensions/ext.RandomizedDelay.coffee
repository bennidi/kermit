{Extension} = require '../Extension'

class RandomizedDelay extends Extension

  @defaultOptions: () ->
    ratio: 1/4
    averageDelayInMs: 10000
    interval: 20000

  constructor: (options = {}) ->
    @options = @merge RandomizedDelay.defaultOpts(), opts

  initialize: (context) ->
    super context
    randomizer = () =>
      try
        if Math.random() > 1 - @options.ratio # Delay hit
          for item in @store.items().fetching()

      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @wdog = setInterval watchdog, 5000





module.exports = {RandomizedDelay}