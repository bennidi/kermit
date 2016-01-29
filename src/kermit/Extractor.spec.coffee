{HtmlExtractor} = require './Extractor.coffee'
{LocalHttpServer} = require './util/httpserver'

describe  'Html parser',  ->
  fixtures = new LocalHttpServer
  before ->
    fixtures.start()
  after ->
    fixtures.stop()
  describe 'transforms HTML into a JSON object using extractors', ->

    it '# can parse and extract from an html snippet', ->
        testHtml = """
          <div>
            <link href="aLink" />
            <a href="anAnchor">jsand</a>
          </div>
          """
        parser = new HtmlExtractor
          name : "test1"
          select :
            resources: ['link',
              'href':  ($section) -> $section.attr 'href'
            ]
            links: ['a',
              'href':  ($link) -> $link.attr 'href'
              'text':  ($link) -> $link.text()
            ]
          onResult: (results) ->
            expect(results.resources.length).to.equal 1
            expect(results.resources[0].href).to.equal "aLink"
            expect(results.links.length).to.equal 1
            expect(results.links[0].href).to.equal "anAnchor"
            expect(results.links[0].text).to.equal "jsand"
        parser.process testHtml
