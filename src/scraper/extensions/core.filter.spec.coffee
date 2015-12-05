{RequestFilter, ByUrl, WithinDomain, MimeTypes} = require './core.filter.coffee'
{CrawlRequest} = require '../CrawlRequest.coffee'

dummyContext = {
  execute: (state, request) -> request
  queue: contains: () -> false
  crawler : {
    enqueue: (request) -> request
  }
}

describe  'Request filter',  ->
  describe 'is used for flexible filtering of requests', ->

    it '# allows filtering by Url patterns', ->
      filter = new RequestFilter
        allow : [WithinDomain "shouldBeAllowed"]
        deny : [
          ByUrl /.*shouldBeDenied.*/g,
          MimeTypes.CSS,
          (request) -> request.depth() >= 1 and not WithinDomain("shouldBeAllowed")(request)
        ]
      filter.initialize(dummyContext)

      shouldBeAllowed = new CrawlRequest "www.shouldBeAllowed.org/some/path/with?query=true", dummyContext
      allowed = [
        shouldBeAllowed,
        shouldBeAllowed.enqueue "www.shouldBeAllowed.org/some/other/path/with?query=true"
      ]
      denied = [
        new CrawlRequest "www.shouldBeDenied.org/some/path/with?query=true",
        new CrawlRequest "www.shouldBeDenied.org/some/path/denied.css",
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




