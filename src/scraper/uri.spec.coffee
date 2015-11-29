URI = require 'urijs'
htmlToJson = require 'html-to-json'

extractLinks = (html) ->
  htmlToJson.batch(html,
    htmlToJson.createParser
      resources: ['link',
        'href':  ($section) -> $section.attr 'href'
      ]
      links: ['a',
        'href':  ($link) -> $link.attr 'href'
      ]).done (results) ->
          console.log JSON.stringify results

describe  'Handling of URIs',  ->
  describe 'with library urijs', ->

    it '# supports absolutizing URIs ', ->
      full = URI "http://example.com/a/path/to/file.html?search=q"
      relative = URI "../some/css/file.css"
      expect(relative.absoluteTo(full).toString()).to.equal("http://example.com/a/path/some/css/file.css")

    it '# parsing of links ', ->
      expect(htmlToJson.batch).to.be.a(Function)
      expect(extractLinks '<a href="fdsfdsfdsfdsf">content</a>').not.to.be.null()
