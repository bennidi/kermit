{Pipeline} = require './Pipeline'
{CharStream} = require './util/tools.streams'
through = require 'through2'

describe  'Channels',  ->
  describe 'can be used to connect streams', ->

    it '# can feed an incoming stream to multiple outgoing', (done) ->
      input = new CharStream 'abcd'
      Channels = new Pipeline
      received = []
      Channels.incoming.pipe(through( (chunk, enc, next) ->
        received.push chunk
        this.push(chunk)
        next()
      ))
      Channels.incoming.pipe(through( (chunk, enc, next) ->
        received.push chunk
        this.push(chunk)
        next()
      ))
      input.pipe(Channels.incoming)
      input.on 'end', =>
        expect(received.length).to.equal(8)
        done()



