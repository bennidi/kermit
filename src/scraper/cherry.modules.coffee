cherry =
  requests: {}
  extensions: {}
  storage: {}
cherry.requests.Request = require('./CrawlRequest')
cherry.requests.Status = require('./CrawlRequest').Status
cherry.storage.Queue = require('./QueueManager').QueueManager
cherry.extensions.Plugin = require('./Extension').Plugin
cherry.extensions.Extension = require('./Extension').Extension
cherry.extensions.ExtensionDescriptor = require('./Extension').ExtensionDescriptor
cherry.extensions.ProcessingException = require('./Extension').ProcessingException
cherry.extensions.Filter = require('./extensions/requestfilter.coffee')
cherry.extensions.ResourceDiscovery = require('./extensions/discover.resources.coffee')
cherry.extensions.OfflineStorage = require('./extensions/OfflineStorage.coffee')
cherry.Crawler = require('./Crawler').Crawler

module.exports = cherry