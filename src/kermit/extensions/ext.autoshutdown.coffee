{Extension} = require '../Extension'

class AutoShutdown extends Extension

  initialize: (context) ->
    super context
    @queue = @context.queue
    watchdog = () =>
      try
        @context.crawler.shutdown() unless @queue.urls.count('scheduled') > 0 or @queue.hasUnfinishedItems()
      catch error
        @log.error? "Error during shutdown check", error:error, trace: error.stack
    @wdog = setInterval watchdog, 5000

  shutdown: (context) ->
    clearInterval @wdog

module.exports = {AutoShutdown}