{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
fs = require 'fs-extra'


toLocalPath = (basedir = "", request) ->
  uri = request.uri().clone()
  uri.normalize()
  normalizedPath =  if uri.path().endsWith "/" then uri.path().substring(0, uri.path().length - 1) else uri.path()
  uri.path normalizedPath
  uri.suffix("html") if !uri.suffix()
  path = basedir + uri.tld() + "/" + uri.domain() + uri.path()

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  constructor: (opts = {}) ->
    super
      FETCHED: (request) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = toLocalPath @basedir , request
        content = request.response.content()
        @log.debug? "Storing #{content.length} bytes to #{path} (#{request.url()})"
        fs.outputFileSync path, content

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