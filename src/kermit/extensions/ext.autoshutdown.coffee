{Extension} = require '../Extension'

###
  Make sure that the Crawler exits as when there are no items left for processing
###
class AutoShutdown extends Extension

  # @nodoc
  initialize: (context) ->
    super context
    watchdog = () =>
      try
        @log.debug "Checking conditions for shutdown"
        @crawler.stop() unless @qs.urls().count('scheduled') > 0 or @qs.items().hasUnfinished()
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @messenger.subscribe 'commands.start', =>
      @log.info? "Starting Autoshutdown watchdog"
      @wdog = setInterval watchdog, 5000
      @wdog.unref()


module.exports = {AutoShutdown}