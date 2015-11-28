cherry = require './cherry.modules'
Status = cherry.requests.Status

describe  'Crawler',  ->
  describe 'package', ->

    it '# exports basic classes for construction of crawlers', ->
      expect(cherry.Crawler).not.to.be.null()
      expect(cherry.Extension).not.to.be.null()
      expect(cherry.ExtensionInfo).not.to.be.null()

    it '# extensions are called for specific phases', (done)->
      RequestCounter = new Counter
      expect(RequestCounter).not.to.be.null()
      SimpleCrawler = new cherry.Crawler extensions : [RequestCounter]
      expect(SimpleCrawler.extpoint("INITIAL").extensions).to.contain(RequestCounter)
      npmRequest = SimpleCrawler.enqueue("http://www.npmjs.com")
      githubRequest = SimpleCrawler.enqueue("http://www.github.com")
      expect(RequestCounter.invocations).to.equal(2)
      expect(npmRequest.status()).to.equal(Status.SPOOLED)
      expect(githubRequest.status()).to.equal(Status.SPOOLED)
      process.nextTick () ->
        expect(npmRequest.status()).to.equal(Status.FETCHING)
        expect(githubRequest.status()).to.equal(Status.FETCHING)
        done()


    it '# extensions can prevent a request from being processed', (done)->
      SimpleCrawler = new cherry.Crawler extensions : [new RejectingExtension]
      npmRequest = SimpleCrawler.enqueue("http://www.npm.com")
      githubRequest = SimpleCrawler.enqueue("http://www.github.com")
      expect(npmRequest.status()).to.equal(Status.INITIAL)
      expect(githubRequest.status()).to.equal(Status.INITIAL)
      process.nextTick () ->
        expect(npmRequest.status()).to.equal(Status.INITIAL)
        expect(githubRequest.status()).to.equal(Status.INITIAL)
        done()


    it '# allows to schedule follow-up requests', (done) ->
      SimpleCrawler = new cherry.Crawler
      npmRequest = SimpleCrawler.enqueue("http://www.npm.com")
      browserify = npmRequest.enqueue("package/browserify")
      expect(npmRequest.status()).to.equal(Status.SPOOLED)
      expect(browserify.status()).to.equal(Status.SPOOLED)
      process.nextTick () ->
        expect(npmRequest.status()).to.equal(Status.FETCHING)
        expect(browserify.status()).to.equal(Status.FETCHING)
        done()

class Counter extends cherry.extensions.Extension

  constructor: ->
    super new cherry.extensions.ExtensionDescriptor "CallCounter", ["INITIAL"]
    @invocations = 0

  apply: (request) ->
    @invocations++

class RejectingExtension extends cherry.extensions.Extension

  constructor: ->
    super new cherry.extensions.ExtensionDescriptor "Rejecting Extension", ["INITIAL"]
    @invocations = 0

  apply: (request) ->
    throw new cherry.extensions.ProcessingException
