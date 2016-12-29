{obj} = require('./util/tools')
{PassThrough} = require 'stream'
_ = require 'lodash'

###
  The pipeline is a convenience abstraction that allows to attach writable streams as destinations
  for the data of the http(s).IncomingMessage.
  Destinations are attached in combination with a selector that defines which types of responses are
  to be piped into the stream. The most common scenario is stream attachment based on response content-type.

  @example
    stream ContentType( [/.*html(.*)/g] ), process.stdout

  @see https://nodejs.org/api/http.html#http_class_http_incomingmessage Incoming Message
  @see https://nodejs.org/api/stream.html#stream_class_stream_writable Writable Stream
###
class Pipeline

  # Create a new Pipeline for the given {RequestItem}
  constructor : (@log, @item) ->
    @incoming = new PassThrough() # stream.PassThrough serves as connector
    @destinations = {} # map destination listeners using regex on mimetype
    @guards = {}

  # Attach a stream as (one of multiple) destination(s). The stream is
  # guarded by a function that defines whether or not the stream will receive
  # the response data from the incoming message.
  # Any stream that has a matching guard function will receive the data from the incoming message.
  # Error handlers will be added to the stream and the item will be transitioned to phase {ERROR}
  # if any streaming error occurs.
  stream: (guard, stream) ->
    throw new Error "Matcher is expected to be of type Function but was #{guard}" unless _.isFunction guard
    id = obj.randomId()
    @guards[id] = guard
    @destinations[id] = stream
    stream.on "error", (error) =>
      @log.error? "Error in downstream #{stream.constructor.name}", {error:error, trace:error.stack}
      @item.error(error)

  # Import the meta data from the incoming message and attach all mapped streams (with matching guards)
  # to the response stream.
  import: (incomingMessage)   ->
    @status = incomingMessage.statusCode
    @headers = incomingMessage.headers
    @log.debug? "Response(#{@status}) from #{@headers['server']} => type=#{@headers['content-type']} length=#{@headers['content-length']}", tags:['Pipeline']
    # Connect all matching destinations
    streams = []
    for id, guard of @guards
      if guard incomingMessage
        @incoming.pipe @destinations[id]
        streams.push @destinations[id].constructor.name
    if _.isEmpty streams # For some responses a matching destination might not be found
      # In that case the item phase is simply set to 'FETCHED' to continue processing
      @log.debug? "No matching destinations found. Skipping.", tags:['Pipeline']
      @item.fetched() unless @item.isError()
    else
      @log.debug? "Streaming #{@item.id()} to #{streams}", tags:['Pipeline']
      incomingMessage
        .on 'error', (error) =>
          @log.error? "Error while streaming #{@item.id()}", {error:error, trace:error.stack, tags:['Pipeline']}
          @item.error(error)
        .on 'end', =>
          @log.debug? "Finished streaming #{@item.id()}", tags:['Pipeline']
          @item.fetched() unless @item.isError()
      # Start streaming
      incomingMessage.pipe @incoming

  # Delete all references to objects that may occupy large amount of memory
  cleanup: ->
    delete @guards
    delete @destinations

  target:-> @_target ?= []

  # @private
  # @nodoc
  data: ->
    @_data ?= if @_target.length > 1 then @_target.join "" else @_target[0]
    @_data


module.exports = {
  Pipeline
  ContentType: (types) ->
    (message) ->
      for type in types
        return true if type.test message.headers['content-type']
      false
}
