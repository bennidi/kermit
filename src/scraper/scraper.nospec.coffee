ScraperTree = require('./scraper').CherryTree
Fixtures =  new (require('../util/static-server').FixtureServer)
mitm = require('mitm')()
urlparser = require 'url'

before ->
  ###
  mitm.on "request", (req, res) ->
    res.writeHead 301, Location: 'http://localhost:3000/diseasedatabase/index-a.html'
    res.end()
  mitm.on "connect", (socket, opts) ->
    socket.bypass() if opts.host is "localhost" ###
  Fixtures.start()

after ->
  Fixtures.stop()

describe  'Scraper',  ->
  describe 'Scraping test website with scenario ', ->
    describe 'local site', ->
      tree = new ScraperTree
        PageIndex : ->
          @select('#page_specific_content a').each (anchor) ->
            @follow anchor.attr("href")
            basedir = "/tmp/scraper"
            path = urlparser.parse(@request.url).pathname
            fs = require('fs')
            wstream = fs.createWriteStream (basedir + path)
            wstream.on 'finish', ->
              console.log('file has been written')
            wstream.write @content.raw()
            wstream.end();

      it '# crawls the index page', (done) ->
        tree.onComplete ->
          expect(null).to.equal(null)
          done()
        tree.start "http://www.diseasedatabase.com", "PageIndex"