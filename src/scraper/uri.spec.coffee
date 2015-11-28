URI = require 'urijs'

describe  'Handling of URIs',  ->
  describe 'with library urijs', ->

    it '# supports absolutizing URIs ', ->
      full = URI "http://example.com/a/path/to/file.html?search=q"
      relative = URI "../some/css/file.css"
      expect(relative.absoluteTo(full).toString()).to.equal("http://example.com/a/path/some/css/file.css")

