cherry =
  requests: {}
  extensions: {}
  storage: {}
cherry.requests.Request = require('./CrawlRequest').CrawlRequest
cherry.requests.Status = require('./CrawlRequest').Status
cherry.storage.Queue = require('./QueueManager').QueueManager
cherry.extensions.Plugin = require('./Extension').Plugin
cherry.extensions.Extension = require('./Extension').Extension
cherry.extensions.ExtensionDescriptor = require('./Extension').ExtensionDescriptor
cherry.extensions.ProcessingException = require('./Extension').ProcessingException
cherry.Crawler = require('./Crawler').Crawler

module.exports = cherry