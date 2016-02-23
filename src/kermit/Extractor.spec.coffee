{HtmlExtractor} = require './Extractor'
htmlToJson = require 'html-to-json'

process = (extractor, input) ->
  try
    htmlToJson.batch input, extractor.parser, (error,results) -> extractor.onResult results.filter unless error
  catch error
    console.log error

describe  'Html parser',  ->
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
        process parser, testHtml
