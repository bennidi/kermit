{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "wikipedia"
  basedir : '/tmp/kermit'
  autostart: false
  extensions : [
    new ResourceDiscovery
    new Monitoring
    #new AutoShutdown
    new Histogrammer
    new RemoteControl
   # new RandomizedDelay
   #   ratio: 1
   #   averageDelayInMs: 5000
   #   interval: 10000
    new OfflineStorage
      basedir: '/tmp/kermit/wikipedia/storage'
    #new OfflineServer
  ]
  options:
    Logging: logconf.detailed
    Streaming:
      agentOptions:
        maxSockets: 15
        keepAlive:true
        maxFreeSockets: 150
        keepAliveMsecs: 1000
    Queueing:
      limits : [
        {
          pattern : /.*en.wikipedia\.org.*/
          to : 5
          per : 'second'
          max : 5
        }
      ]
    Filtering:
      allow : [
        /.*en.wikipedia\.org.*/
      ]
# Anything matcing the whitelist will be visited
      deny : [
        /.*debug=false/
      ]

