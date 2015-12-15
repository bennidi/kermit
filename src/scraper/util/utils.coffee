{Extension, ExtensionDescriptor} = require '../Extension.coffee'
{Status} = require '../CrawlRequest.coffee'
{QueueManager} = require '../QueueManager.coffee'
through = require 'through2'
stream = require 'stream'

class LogStream extends stream.Writable

  constructor: (@shouldLog = false) -> super

  _write: (chunk, enc, next) ->
    console.log chunk.toString() if @shouldLog
    next()

class ResponseStreamLogger extends Extension

  constructor: (shouldLog = false) ->
    super INITIAL: (request) ->
      request.response.incoming.pipe new LogStream shouldLog


# https://strongloop.com/strongblog/whats-new-io-js-beta-streams3/
# https://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html
# Thanks to http://jeroenpelgrims.com/node-streams-in-coffeescript/
# https://github.com/dominictarr/stream-spec
class CharStream extends stream.Readable
  constructor: (@s) ->
    super

  _read: ->
    for c in @s
      @push c
    @push null

class InmemoryStream extends stream.Writable

  constructor: (@target = []) ->
    super

  _write: (chunk, enc, next) ->
    @target.push chunk
    next()

module.exports = {
  CharStream
  InmemoryStream
  ResponseStreamLogger
}