{Crawler, ext, logconf} = require '../src/kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "reddit"
  basedir: "/tmp/kermit/reddit"
  extensions : [
    new OfflineStorage
      basedir: '/tmp/kermit/reddit'
    new Monitoring
    new ResourceDiscovery
  ]
  options:
    Logging: logconf.detailed

Kermit.schedule("http://www.reddit.com")


