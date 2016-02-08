{Extension} = require '../Extension'
stream = require 'stream'
_ = require 'lodash'
util = require 'util'


class LogStream extends stream.Writable

  constructor: (@shouldLog = true) -> super

  _write: (chunk, enc, next) ->
    console.log chunk.toString() if @shouldLog
    next()


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

class DevNull extends stream.Writable

  _write: (chunk, enc, next) -> next()

class CountingStream extends stream.Transform

  constructor: (@cnt = 0) -> super

  _transform: (chunk, enc, next) ->
    @cnt++
    @push chunk
    next()


module.exports = {
  CharStream
  MemoryStream
  CountingStream
  LogStream
  DevNull
}