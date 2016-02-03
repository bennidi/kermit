through = require 'through2'
{PassThrough} = require 'stream'
{HtmlExtractor} = require './Extractor.coffee'
{DevNull} = require './util/tools.streams.coffee'
_ = require 'lodash'
{obj} = require('./util/tools.coffee')

###
  The pipeline is a convenience abstraction that allows to attach writable streams as destinations
  for the data of the http(s).IncomingMessage.
  Destinations are attached in combination with a selector that defines which types of responses are
  to be piped into the stream. The most common scenario is stream attachment based on mimetypes.


  @example
    stream Mimetypes( [/.*html(.*)/g] ), process.stdout

  @see https://nodejs.org/api/http.html#http_class_http_incomingmessage Incoming Message
  @see https://nodejs.org/api/stream.html#stream_class_stream_writable Writable Stream
###
class Pipeline

  constructor : (@log, @crawlRequest) ->
    @incoming = new PassThrough() # stream.PassThrough serves as connector
    @downstreams = {} # map downstream listeners using regex on mimetype
    @matchers = {}

  stream: (matcher, stream) ->
    throw new Error "Matcher is expected to be of type Function but was #{matcher}" unless _.isFunction matcher
    id = obj.randomId()
    @matchers[id] = matcher
    @downstreams[id] = stream

  import: (incomingMessage)   ->
    @phase = incomingMessage.phaseCode
    @headers = incomingMessage.headers
    @log.debug? "Received #{@phase} type=#{@headers['content-type']} length=#{@headers['content-length']} server=#{@headers['server']}", tags:['Pipeline']
    # Connect all matching downstreams
    streams = []
    for id, matcher of @matchers
      if matcher incomingMessage
        @incoming.pipe @downstreams[id]
        streams.push @downstreams[id].constructor.name
    if _.isEmpty streams # For some responses a matching downstream might not be found
      # In that case the request phase is simply set to 'FETCHED' to continue processing
      @log.debug? "No matching downstreams found. Skipping.", tags:['Pipeline']
      @crawlRequest.fetched()
    else
      @log.debug? "Attached #{streams}", tags:['Pipeline']
      incomingMessage
        .on 'error', (error) =>
          @log.error? "Error while streaming", error:error
          @crawlRequest.error(error)
        .on 'end', =>
          @crawlRequest.fetched()
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