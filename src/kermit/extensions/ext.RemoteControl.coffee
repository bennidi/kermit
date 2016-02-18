{Extension} = require '../Extension'
Koa = require 'koa'
Router = require 'koa-router'
bodyparser = require 'koa-body-parser'

class RemoteControl extends Extension
  
  @defaultOptions: () ->
    port : 8011
  
  constructor: (options = {}) ->
    super {}
    @options = @merge RemoteControl.defaultOptions(), options
  
  initialize: (context) ->
    super context
    app = new Koa()
    $ = @
    commands = new Router prefix: '/commands'
    requests = new Router prefix: '/requests'

    requests.post '/schedule', (next) ->
      $.crawler.schedule @request.body.url, @request.body.meta
      @body = msg: "Scheduled #{@request.body.url}"
      yield next
    commands.post '/start', (next) =>
      $.crawler.start()
      @body = msg: "Received start command"
      yield next
    commands.post '/stop', (next) =>
      $.crawler.stop()
      @body = msg: "Received stop command"
      yield next
    commands.post '/shutdown', (next) =>
      $.crawler.stop()
      @body = msg: "Received stop command"
      yield next
    app.use (next) ->
      $.log.debug? "Received #{JSON.stringify @}"
      yield next
    app.use bodyparser()
    app.use commands.routes()
    app.use requests.routes()
    @rc = app.listen @options.port
    @log.info "RemoteControl available at localhost:#{@options.port}", tags: ['REST API']


module.exports = {RemoteControl}