{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
fs = require 'fs-extra'


toLocalPath = (basedir = "", uri) ->
  uri = uri.clone()
  !uri.filename("index.html") if !uri.suffix()
  basedir + uri.tld() + "/" + uri.hostname() + uri.pathname()

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  constructor: (opts = {}) ->
    super
      FETCHED: (request) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = toLocalPath @basedir , request.uri()
        #@log.debug? "Storing #{request.body.length} bytes to #{path}"
        fs.outputFileSync path, request.response.content()

  initialize: (context) ->
    super context
    @basedir = context.config.basePath() + "/"


class OfflineServer extends Extension

  @defaultOpts =
    port : 3000

  constructor: (opts = {}) ->
    super INITIAL : @apply
    @opts = @merge OfflineServer.defaultOpts, opts

  initialize: (context) ->
    super context
    @opts.basedir = context.config.basePath() + "/"
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