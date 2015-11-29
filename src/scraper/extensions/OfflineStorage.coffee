Status = require('../CrawlRequest').Status
extensions = require '../Extension'
fs = require 'fs-extra'

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends extensions.Extension

  @opts =
    basedir : "/tmp/crawler/repo/"

  constructor: (@opts = OfflineStorage.opts) ->
    super new extensions.ExtensionDescriptor "OfflineStorage", [Status.FETCHED]

  initialize: (context) ->

  apply: (request) ->
    !request.uri().filename("index.html") if !request.uri().filename()
    path = @opts.basedir + request.uri().tld() + "/" + request.uri().hostname() + request.uri().pathname()
    console.log "Storing " + path
    fs.outputFile path, request.body, (err) ->
      console.log(err)

module.exports = OfflineStorage