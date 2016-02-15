{Extension} = require '../Extension'
stream = require 'stream'
_ = require 'lodash'
util = require 'util'

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


module.exports = {
  CharStream
  MemoryStream
}