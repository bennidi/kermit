{RequestFilter, ByPattern, MimeTypes} = require './core.filter.coffee'
{CrawlRequest} = require '../CrawlRequest.coffee'
{MockContext} =  require '../util/spec.utils.coffee'

describe  'Request filter',  ->
  describe 'is used for flexible filtering of requests', ->

    it '# allows filtering by Url patterns', ->
      filter = new RequestFilter
        allow : [ByPattern /.*shouldBeAllowed.*/]
        deny : [
          ByPattern /.*shouldBeDenied.*/g,
          MimeTypes.CSS,
          (request) -> request.predecessors() >= 1 and not WithinDomain(/.*shouldBeAllowed.*/)(request)
        ]
      filter.initialize(new MockContext)

      shouldBeAllowed = new CrawlRequest "www.shouldBeAllowed.org/some/path/with?query=true", new MockContext
      allowed = [
        shouldBeAllowed
      ]
      denied = [
        new CrawlRequest "www.shouldBeDenied.org/some/path/with?query=true", new MockContext
        new CrawlRequest "www.shouldBeDenied.org/some/path/denied.css", new MockContext
      ]

      expect(request.isInitial()).to.be.true() for request in allowed
      expect(request.isInitial()).to.be.true() for request in denied

      filter.apply(request) for request in allowed
      filter.apply(request) for request in denied

      for request in allowed
        expect(request.isInitial()).to.be.true()

      for request in denied
        expect(request.isInitial()).to.be.false()
        expect(request.isCanceled()).to.be.true()




