{Crawler, ext, logconf} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage, OfflineServer, AutoShutdown, Histogrammer, RandomizedDelay} = ext
{RemoteControl} = ext

# opts: rateLimit, item depth
Kermit = new Crawler
  name: "testrepo"
  basedir : '/tmp/kermit'
  autostart: true
  extensions : [
    new ResourceDiscovery
    #new Monitoring
    new AutoShutdown
    #new Histogrammer
   # new RemoteControl
   # new RandomizedDelay
   #   ratio: 1
   #   averageDelayInMs: 5000
   #   interval: 10000
    new OfflineStorage
      basedir: '/tmp/kermit/roundtrip'
    new OfflineServer
      basedir : '/ext/dev/workspace/webcherries/testing/repo-coffeescript'
  ]
  options:
    Logging: logconf.detailed
    Streaming:
      agentOptions:
        maxSockets: 15
        keepAlive:false
        maxFreeSockets: 150
        keepAliveMsecs: 1000
    Queueing:
      limits : [
        {
          pattern : /.*coffeescript\.org.*/
          to : 100
          per : 'second'
          max : 50
        }
      ]
    Filtering:
      allow : [
        /.*coffeescript\.org.*/
      ]
# Anything matching the whitelist will be visited
      deny : [
      ]

Kermit.execute "http://coffeescript.org"