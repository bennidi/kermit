{obj} = require './util/tools.coffee'
kermit = require './Crawler'
kermit = obj.merge kermit, require './CrawlRequest'
kermit = obj.merge kermit, require './Extension'
kermit = obj.merge kermit, require './Crawler.ExtensionPoints.coffee'
kermit.filters = require './extensions/core.filter.coffee'
kermit.ext = obj.merge {}, require './extensions/ext.discovery.coffee'
kermit.ext = obj.merge kermit.ext, require './extensions/ext.htmlprocessor.coffee'
kermit.ext = obj.merge kermit.ext, require './extensions/ext.offline.coffee'
kermit.ext = obj.merge kermit.ext, require './extensions/ext.monitoring.coffee'

module.exports = kermit