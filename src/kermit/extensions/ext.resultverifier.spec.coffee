{UrlFilter, ByPattern, MimeTypes} = require './core.filter'
{RequestItem} = require '../RequestItem'
{MockContext} =  require '../util/spec.utils'

describe  'Request filter',  ->
  describe 'is used for flexible filtering of items', ->

    it '# allows filtering by Url patterns', ->
      filter = new UrlFilter {
        allow : [ByPattern /.*shouldBeAllowed.*/]
        deny : [
          /.*shouldBeDenied.*/
          MimeTypes.CSS
        ]}, new MockContext().log

      allowed = [
        "www.shouldBeAllowed.org/some/path/with?query=true"
      ]
      denied = [
        "www.shouldBeDenied.org/some/path/with?query=true"
        "www.shouldBeDenied.org/some/path/denied.css"
      ]

      expect(filter.isAllowed url).to.be.true() for url in allowed
      expect(filter.isAllowed url).to.be.false() for url in denied




