{RequestFilter, ByUrl, WithinDomain, MimeTypes} = require './core.filter.coffee'
{CrawlRequest} = require '../CrawlRequest.coffee'
{MockContext} =  require '../util/testutils.coffee'

describe  'Request filter',  ->
  describe 'is used for flexible filtering of requests', ->

    it '# allows filtering by Url patterns', ->
      filter = new RequestFilter
        allow : [WithinDomain "shouldBeAllowed"]
        deny : [
          ByUrl /.*shouldBeDenied.*/g,
          MimeTypes.CSS,
          (request) -> request.predecessors() >= 1 and not WithinDomain("shouldBeAllowed")(request)
        ]
      filter.initialize(new MockContext)

      shouldBeAllowed = new CrawlRequest "www.shouldBeAllowed.org/some/path/with?query=true", new MockContext
      allowed = [
        shouldBeAllowed,
        shouldBeAllowed.enqueue "www.shouldBeAllowed.org/some/other/path/with?query=true"
      ]
      denied = [
        new CrawlRequest "www.shouldBeDenied.org/some/path/with?query=true", new MockContext
        new CrawlRequest "www.shouldBeDenied.org/some/path/denied.css", new MockContext
        shouldBeAllowed.enqueue "www.oneLevel.org/some/path/with?query=true"
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




