crawlino = require('./crawlino')

describe  'Crawlino',  ->
  describe 'package', ->

    it '# exports basic classes for construction of crawlers', ->
      expect(crawlino.Crawler).not.to.be.null()
      expect(crawlino.Extension).not.to.be.null()
      expect(crawlino.ExtensionInfo).not.to.be.null()

    it '# hooks are called for specific phases', ->
      expect(Counter).not.to.be.null()
      RequestCounter = new Counter
      expect(RequestCounter).to.be.an.instanceOf(Counter)

      SimpleCrawler = new crawlino.Crawler [RequestCounter]
      expect(SimpleCrawler.extensions("NewRequest")).to.contain(RequestCounter)
      SimpleCrawler.crawl("http://www.npmjs.com")
      expect(RequestCounter.invocations).to.equal(1)



class Counter extends crawlino.Extension

  constructor: ->
    super new crawlino.ExtensionDescriptor "CallCounter", ["NewRequest"]
    @invocations = 0

  apply: (request, control) ->
    @invocations++
