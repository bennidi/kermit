{Status} = require '../CrawlRequest'
{Extension, ExtensionDescriptor} = require '../Extension'
fs = require 'fs-extra'


toLocalPath = (basedir = "", uri) ->
  uri = uri.clone()
  !uri.filename("index.html") if !uri.filename()
  basedir + uri.tld() + "/" + uri.hostname() + uri.pathname()

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  @defaultOpts =
    basedir : "/tmp/crawler/repo/"

  constructor: (@opts = OfflineStorage.defaultOpts) ->
    super new ExtensionDescriptor "OfflineStorage", [Status.FETCHED]

  apply: (request) ->
    # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
    path = toLocalPath @opts.basedir , request.uri()
    fs.outputFile path, request.body, (err) ->
      console.log(err)


class OfflineServer extends Extension

  @defaultOpts =
    basedir : "/tmp/crawler/repo/"

  constructor: (@opts = {}) ->
    @opts = Extension.mergeOptions OfflineServer.defaultOpts, @opts
    super new ExtensionDescriptor "OfflineServer", [Status.INITIAL]


  initialize: (context) ->
    super context
    LocalFileServer = require('../util/static-server').LocalStorageServer
    @server =  new LocalFileServer 3000, @opts.basedir
    @server.start()

  shutdown: () ->
    @server.stop()

  apply: (request) ->
    redirectedUrl = toLocalPath "http://localhost:3000/", request.uri()
    request.uri(redirectedUrl)

module.exports = {
  OfflineStorage
  OfflineServer
}