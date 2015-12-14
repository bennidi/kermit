{HtmlExtractor} = require './Extractor.coffee'

describe  'Html parser',  ->
  describe 'transforms HTML into a JSON object using extractors', ->

    it '# can parse and extract from an html snippet', ->
        testHtml = """
          <div>
            <link href="aLink" />
            <a href="anAnchor">jsand</a>
          </div>
          """
        parser = new HtmlExtractor()
        parser.extract(
          resources: ['link',
            'href':  ($section) -> $section.attr 'href'
          ]
          links: ['a',
            'href':  ($link) -> $link.attr 'href'
          ])
        .then (results) ->
          expect(results.resources.length).to.equal(1)
          expect(results.resources[0].href).to.equal("aLink")
          expect(results.links.length).to.equal(1)
          expect(results.links[0].href).to.equal("anAnchor")
        parser.process testHtml
