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
        queuesAreEmpty = => @qs.urls().count('scheduled') is 0 and @qs.items().unfinished().length is 0
        @log.debug? "Checking conditions for shutdown", tags:['AutoShutdown']
        if queuesAreEmpty()
          process.nextTick =>
            if queuesAreEmpty() # double check because scheduling is async
              clearInterval @wdog
              @crawler.stop()
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @onStart =>
      @log.info? "Starting Autoshutdown watchdog", tags:['AutoShutdown']
      @wdog = setInterval watchdog, 5000
      @wdog.unref()


module.exports = {AutoShutdown}