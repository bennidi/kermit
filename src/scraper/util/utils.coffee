{Extension} = require '../Extension.coffee'
stream = require 'stream'
_ = require 'lodash'

class LogStream extends stream.Writable

  constructor: (@shouldLog = true) -> super

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

class MemoryStream extends stream.Writable

  constructor: (@target = []) ->
    super

  _write: (chunk, enc, next) ->
    @target.push chunk
    next()

class CountingStream extends stream.Transform

  constructor: (@cnt = 0) -> super

  _transform: (chunk, enc, next) ->
    @cnt++
    @push chunk
    next()


module.exports = {
  CharStream
  MemoryStream
  ResponseStreamLogger
  CountingStream
  LogStream
  objects :
    merge : (a,b) ->
      _.merge a , b , (a,b) -> if _.isArray a then b
  RandomId : (length=8) ->
    id = ""
    id += Math.random().toString(36).substr(2) while id.length < length
    id.substr 0, length
}