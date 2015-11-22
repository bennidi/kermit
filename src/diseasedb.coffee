ScraperTree = require('./scraper/scraper').CherryTree
urlparser = require 'url'

tree = new ScraperTree
  PageIndex : ->
    basedir = "/tmp/scraper"
    parsedUrl = urlparser.parse(@request.url)
    path = "/" + parsedUrl.host + parsedUrl.pathname
    fs = require('fs')
    wstream = fs.createWriteStream (basedir + path)
    wstream.on 'finish', ->
      console.log('file has been written')
    wstream.write @content.raw()
    wstream.end()

    @select('#page_specific_content a').each (anchor) ->
      console.log anchor.attr("href")
      @follow "StreamSingle", anchor.attr("href")
  StreamSingle : ->
    basedir = "/tmp/scraper"
    parsedUrl = urlparser.parse(@request.url)
    path = "/" + parsedUrl.host + parsedUrl.pathname
    fs = require('fs')
    wstream = fs.createWriteStream (basedir + path)
    wstream.on 'finish', ->
      console.log('file has been written')
    wstream.write @content.raw()
    wstream.end()

tree.start "http://www.diseasesdatabase.com/disease_index_a.asp", "PageIndex"
