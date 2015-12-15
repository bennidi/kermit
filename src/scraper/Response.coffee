through = require 'through2'
{PassThrough} = require 'stream'
{HtmlExtractor} = require './Extractor.coffee'


stream = require 'stream'

class InmemoryStream extends stream.Writable

  constructor: (@target = []) ->
    super

  _write: (chunk, enc, next) ->
    @target.push chunk
    next()

class Response

  constructor : () ->
    @incoming = new PassThrough() # stream.PassThrough serves as connector
    @data = []

  parser: () ->
    if !@extractor
      @extractor = new HtmlExtractor
      @incoming
        .pipe new InmemoryStream @data
      @incoming.on 'end', =>
        @extractor.process @content()
    @extractor

  content : ->
    @data.join()

module.exports = {
  Response
}