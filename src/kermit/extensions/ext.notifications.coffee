{Extension} = require '../Extension'
notifier = require 'node-notifier'

###
  Make sure that the Crawler exits as when there are no items left for processing
###
class NotificationCenter extends Extension


  # @nodoc
  initialize: (context) ->
    super context
    context.on 'crawler:start', -> notifier.notify "Crawler started"
    context.on 'crawler:stop', -> notifier.notify "Crawler stopped"


module.exports = {NotificationCenter}
