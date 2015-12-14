{Response} = require './Pipeline.coffee'
{CharStream} = require './util/testutils.coffee'
through = require 'through2'

describe  'Pipeline',  ->
  describe 'can be used to connect streams', ->

    it '# can feed an incoming stream to multiple outgoing', (done) ->
      input = new CharStream 'abcd'
      response = new Response
      received = []
      response.incoming.pipe(through( (chunk, enc, next) ->
        received.push chunk
        this.push(chunk)
        next()
      ))
      response.incoming.pipe(through( (chunk, enc, next) ->
        received.push chunk
        this.push(chunk)
        next()
      ))
      input.pipe(response.incoming)
      input.on 'end', =>
        expect(received.length).to.equal(8)
        done()



