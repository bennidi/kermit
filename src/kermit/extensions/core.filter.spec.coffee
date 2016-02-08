{RequestFilter, ByPattern, MimeTypes} = require './core.filter'
{RequestItem} = require '../RequestItem'
{MockContext} =  require '../util/spec.utils'

describe  'Request filter',  ->
  describe 'is used for flexible filtering of items', ->

    it '# allows filtering by Url patterns', ->
      filter = new RequestFilter
        allow : [ByPattern /.*shouldBeAllowed.*/]
        deny : [
          ByPattern /.*shouldBeDenied.*/g,
          MimeTypes.CSS,
          (item) -> item.predecessors() >= 1 and not WithinDomain(/.*shouldBeAllowed.*/)(item)
        ]
      filter.initialize(new MockContext)

      shouldBeAllowed = new RequestItem "www.shouldBeAllowed.org/some/path/with?query=true", new MockContext
      allowed = [
        shouldBeAllowed
      ]
      denied = [
        new RequestItem "www.shouldBeDenied.org/some/path/with?query=true", new MockContext
        new RequestItem "www.shouldBeDenied.org/some/path/denied.css", new MockContext
      ]

      expect(item.isInitial()).to.be.true() for item in allowed
      expect(item.isInitial()).to.be.true() for item in denied

      filter.apply(item) for item in allowed
      filter.apply(item) for item in denied

      for item in allowed
        expect(item.isInitial()).to.be.true()

      for item in denied
        expect(item.isInitial()).to.be.false()
        expect(item.isCanceled()).to.be.true()




