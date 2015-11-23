cherry = require './cherry.modules'

describe  'Crawler',  ->
  describe 'package', ->

    it '# exports basic classes for construction of crawlers', ->
      expect(cherry.Crawler).not.to.be.null()
      expect(cherry.Extension).not.to.be.null()
      expect(cherry.ExtensionInfo).not.to.be.null()

    it '# extensions are called for specific phases', (done)->
      RequestCounter = new Counter
      expect(RequestCounter).not.to.be.null()
      SimpleCrawler = new cherry.Crawler [RequestCounter]
      expect(SimpleCrawler.extpoint("request-new").extensions).to.contain(RequestCounter)
      npmRequest = SimpleCrawler.enqueue("http://www.npmjs.com")
      githubRequest = SimpleCrawler.enqueue("http://www.github.com")
      expect(RequestCounter.invocations).to.equal(2)
      expect(npmRequest.status()).to.equal('SPOOLED')
      expect(githubRequest.status()).to.equal('SPOOLED')
      process.nextTick () ->
        expect(npmRequest.status()).to.equal('FETCHING')
        expect(githubRequest.status()).to.equal('FETCHING')
        done()

    it '# extensions can prevent a request from being processed', (done)->
      SimpleCrawler = new cherry.Crawler [new RejectingExtension]
      npmRequest = SimpleCrawler.enqueue("http://www.npffdg.com")
      githubRequest = SimpleCrawler.enqueue("http://www.gfdgf.com")
      expect(npmRequest.status()).to.equal('CREATED')
      expect(githubRequest.status()).to.equal('CREATED')
      process.nextTick () ->
        expect(npmRequest.status()).to.equal('CREATED')
        expect(githubRequest.status()).to.equal('CREATED')
        done()


class Counter extends cherry.extensions.Extension

  constructor: ->
    super new cherry.extensions.ExtensionDescriptor "CallCounter", ["request-new"]
    @invocations = 0

  apply: (request) ->
    @invocations++

class RejectingExtension extends cherry.extensions.Extension

  constructor: ->
    super new cherry.extensions.ExtensionDescriptor "Rejecting Extension", ["request-new"]
    @invocations = 0

  apply: (request) ->
    throw new cherry.extensions.ProcessingException
