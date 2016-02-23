{Extension} = require '../Extension'

###
  Make sure that the Crawler exits as when there are no items left for processing
###
class AutoShutdown extends Extension

  # @nodoc
  initialize: (context) ->
    super context
    watchdog = =>
      try
        @log.debug "Checking conditions for shutdown"
        if @qs.urls().count('scheduled') is 0 and @qs.items().unfinished().length is 0
          clearInterval @wdog
          @crawler.stop()
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @messenger.subscribe 'commands.start', =>
      @log.info? "Starting Autoshutdown watchdog"
      @wdog = setInterval watchdog, 5000
      @wdog.unref()


module.exports = {AutoShutdown}