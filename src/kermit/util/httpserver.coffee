serve = require 'koa-static'
Koa = require 'koa'
fs = require 'fs'
{obj} = require './tools.coffee'

class LocalHttpServer

  constructor: (@port = 3000, @basedir = "./fixtures") ->

  start: ->
    app = new Koa()
    app.use (next) ->
      @set 'server', 'LocalHttpServer(localhost)' # set header entry "server"
      @set 'set-cookie', "rid=#{obj.randomId()}" # set cookie rid
      yield next
    app.use serve @basedir
    @server = app.listen @port
    console.log "LocalStorageServer listening on port #{@port} and basedir #{@basedir}"

  stop: ->
    @server.close()
    console.log "LocalHttpServer closed"
  

module.exports = {LocalHttpServer}


