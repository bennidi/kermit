_ = require 'lodash'
util = require 'util'

module.exports =
  obj :
    print : (object, depth = 2, colorize = false) ->
      util.inspect object, false, depth, colorize
    merge : (a,b) ->
      _.merge a , b
    overlay : (a,b) ->
      _.merge a , b , (a,b) -> if _.isArray a then b
    randomId : (length=8) ->
      id = ""
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length
  streams: require './tools.streams.coffee'
