{Status} = require '../CrawlRequest'
{Extension, ExtensionDescriptor} = require '../Extension'
fs = require 'fs-extra'


toLocalPath = (basedir = "", uri) ->
  uri = uri.clone()
  !uri.filename("index.html") if !uri.filename()
  basedir + uri.tld() + "/" + uri.hostname() + uri.pathname()

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  constructor: (opts = {}) ->
    super "OfflineStorage", [Status.FETCHED]

  initialize: (context) ->
    super context
    @basedir = context.crawler.basePath() + "/"

  apply: (request) ->
    # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
    path = toLocalPath @basedir , request.uri()
    @log.debug "Storing #{request.body.length} bytes to #{path}"
    fs.outputFileSync path, request.body


class OfflineServer extends Extension

  @defaultOpts =
    port : 3000

  constructor: (opts = {}) ->
    super "OfflineServer", [Status.INITIAL]
    @opts = Extension.mergeOptions OfflineServer.defaultOpts, opts


  initialize: (context) ->
    super context
    @opts.basedir = context.crawler.basePath() + "/"
    LocalFileServer = require('../util/static-server').LocalStorageServer
    @server =  new LocalFileServer @opts.port, @opts.basedir
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