#
# Credits go to Christopher Giffard
# https://github.com/cgiffard/node-simplecrawler
#
# Copyright (c) 2011-2015, Christopher Giffard

Status = require('../CrawlRequest').Status
extensions = require '../Extension'
URI = require 'urijs'
validUrl = require 'valid-url'
_ = require 'lodash'

# State transition CREATED -> SPOOLED
class ResourceDiscovery extends extensions.Extension

  # http://elijahmanor.com/regular-expressions-in-coffeescript-are-awesome/
  # https://coffeescript-cookbook.github.io/chapters/regular_expressions/searching-for-substrings
  # http://stackoverflow.com/questions/1500260/detect-urls-in-text-with-javascript
  @opts =
    regex: [
      /\s?(?:href|src)\s?=\s?(["']).*?\1/ig,
      /\s?(?:href|src)\s?=\s?[^"'][^\s>]+/ig,
      #/\s?url\((["']).*?\1\)/ig,
      #/\s?url\([^"'].*?\)/ig,
      /http(s)?\:\/\/[^?\s><\'\"]+/ig]


  constructor: (@opts = ResourceDiscovery.opts) ->
    super new extensions.ExtensionDescriptor "ResourceDiscovery", [Status.FETCHED]

  apply: (request) ->
    #console.log request.body.match /r?or?/g
    # matches = (request.body.match regex)
    matches = (request.body.match regex for regex in @opts.regex)
    cleaned = _.flatten (_.reject(matches, _.isNull))
    #console.log cleaned
    links = (match.replace /(src|href)\s*=/, "" for match in cleaned)
    request.enqueue link for link in links

module.exports = ResourceDiscovery