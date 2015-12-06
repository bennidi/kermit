{ExtensionPointConnector, Spooler, Completer, RequestLookup} = require './core.coffee'

describe  'Core extensions',  ->

  describe 'ExtensionPointConnector', ->

    it '# auto-connects requests to the extension points', ->
      expect(ExtensionPointConnector).not.to.be.null()

  describe 'Spooler', ->

    it '# it manages state transitions from INITIAL to SPOOLED', ->
      expect(Spooler).not.to.be.null()

  describe 'Completer', ->

    it '# it manages state transitions from FETCHED to COMPLETED', ->
      expect(Completer).not.to.be.null()


  describe 'RequestLookup', ->

    it '# extends the context with a map to lookup requests by id', ->
      expect(RequestLookup).not.to.be.null()

