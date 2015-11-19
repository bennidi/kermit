ScraperTree = require('./scraper').CherryTree
Fixtures =  new (require('../util/static-server').FixtureServer)
mitm = require('mitm')()

before ->
  mitm.on "request", (req, res) ->
    res.writeHead 301, Location: 'http://localhost:3000/diseasedatabase/index-a.html'
    res.end()
  mitm.on "connect", (socket, opts) ->
    socket.bypass() if opts.host is "localhost"
  Fixtures.start()

after ->
  Fixtures.stop()

describe  'Scraper',  ->
  describe 'Scraping test website with scenario ', ->
    describe 'blub', ->
      tree = new ScraperTree
        PageIndex : ->
          @select('#page_specific_content a').each (anchor) ->
            console.log anchor.attr("href")

      it '# inherits all methods from Invocable', (done) ->
        tree.onComplete ->
          expect(null).to.equal(null)
          done()
        tree.start "http://www.diseasedatabase.com", "PageIndex"
