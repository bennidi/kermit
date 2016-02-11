_ = require 'lodash'
util = require 'util'
URI = require 'urijs'

module.exports =
  uri:
    normalize: (url) -> URI(url).normalize().toString()
    create: (url) -> URI(url)
  obj :
    addProperty: (name, value, object) ->
      object ?= {}
      object[name] ?= value
      object
    print : (object, depth = 2, colorize = false) ->
      util.inspect object, false, depth, colorize
    merge : (a,b) ->
      _.merge a , b , (a,b) -> if _.isArray b then b.concat a
    overlay : (a,b) ->
      _.merge a , b , (a,b) -> if _.isArray a then b
    randomId : (length=8) ->
      # Taken from: https://coffeescript-cookbook.github.io/chapters/strings/generating-a-unique-id
      id = ""
      id += Math.random().toString(36).substr(2) while id.length < length
      id.substr 0, length
  streams: require './tools.streams'
