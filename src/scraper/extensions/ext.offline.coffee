{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
fse = require 'fs-extra'
{byExtension} = require '../util/mimetypes.coffee'
{Mimetypes} = require('../Pipeline.coffee')


toLocalPath = (basedir = "", request) ->
  uri = request.uri().clone()
  uri.normalize()
  #normalizedPath = if uri.path().endsWith "/" then uri.path().substring(0, uri.path().length - 1) else uri.path()
  #uri.path normalizedPath
  uri.filename("index.html") if (!uri.suffix() or not byExtension[uri.suffix()])
  domainWithoutTld = uri.domain().replace ".#{uri.tld()}", ''
  "#{basedir}/#{uri.tld()}/#{domainWithoutTld}#{uri.path()}"

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  constructor: (opts = {}) ->
    super
      READY: (request) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = toLocalPath @basedir , request
        @log.debug? "Storing #{request.url()} to #{path}"
        request.channels().stream Mimetypes([/.*/g]), fse.createOutputStream path

  initialize: (context) ->
    super context
    @basedir = context.config.basePath()


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