{Extension} = require '../Extension'

###
  Make sure that the Crawler exits as when there are no items left for processing
###
class NotificationCenter extends Extension

  constructor:->
    super
      INITIAL: (item) => item.onPhase 'ERROR', => @context.notify "Error:#{item.toString()}"


  # @nodoc
  initialize: (context) ->
    super context
    context.on 'crawler:start', -> context.notify "Crawler stopped"
    context.on 'crawler:stop', -> context.notify "Crawler stopped"


module.exports = {NotificationCenter}
