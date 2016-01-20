through = require 'through2'
{PassThrough} = require 'stream'
{HtmlExtractor} = require './Extractor.coffee'
{MemoryStream} = require './util/tools.coffee'
_ = require 'lodash'
{obj} = require('./util/tools.coffee')


class Pipeline

  constructor : (@log) ->
    @incoming = new PassThrough() # stream.PassThrough serves as connector
    @downstreams = {} # map downstream listeners using regex on mimetype
    @matchers = {}

  stream: (matcher, stream) ->
    throw new Error "Matcher is expected to be of type Function but was #{matcher}" unless _.isFunction matcher
    id = obj.randomId()
    @matchers[id] = matcher
    @downstreams[id] = stream

  import: (incomingMessage)   ->
    @status = incomingMessage.statusCode
    @headers = incomingMessage.headers
    @log.debug? "Received #{@status} #{obj.print @headers}"
    # Connect downstreams
    for id, matcher of @matchers
      @incoming.pipe @downstreams[id] if matcher incomingMessage
      @log.debug? "Attaching #{@downstreams[id].constructor.name}", tags:['Pipeline']
    # Start streaming
    incomingMessage.pipe @incoming

  cleanup: () ->
    delete @matchers
    delete @downstreams
    delete @data

module.exports = {
  Pipeline
  Mimetypes: (types) ->
    (message) ->
      for type in types
        return true if type.test message.headers['content-type']
      false
}