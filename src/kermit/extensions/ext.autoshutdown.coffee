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
        @context.crawler.shutdown() unless @qs.urls().count('scheduled') > 0 or @qs.items().hasUnfinished()
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @wdog = setInterval watchdog, 5000

# @nodoc
  shutdown: (context) ->
    clearInterval @wdog

module.exports = {AutoShutdown}