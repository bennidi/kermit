sloth = require './scraper/cherry.modules'
{ResponseStreamLogger} = require './scraper/util/testutils.coffee'

# opts: rateLimit, request depth
Crawler = new sloth.Crawler
  name: "testicle"
  extensions : [
    new  ResponseStreamLogger true
  ]
  options:
    Streamer:
      Tor :
        enabled : true

Crawler.enqueue("http://ping.eu/")


