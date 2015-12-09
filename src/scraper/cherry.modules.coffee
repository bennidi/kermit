cherry =
  requests: {}
  extensions: {}
  storage: {}
cherry.requests.Request = require('./CrawlRequest')
cherry.requests.Status = require('./CrawlRequest').Status
cherry.storage.Queue = require('./QueueManager').QueueManager
cherry.extensions.Extension = require('./Extension').Extension
cherry.extensions.OfflineStorage = require('./extensions/plugin.offline.coffee').OfflineStorage
cherry.Crawler = require('./Crawler').Crawler

module.exports = cherry