{Status} = require '../CrawlRequest'
{Extension} = require '../Extension'
fse = require 'fs-extra'
{byExtension} = require '../util/mimetypes.coffee'
{Mimetypes} = require('../Pipeline.coffee')
Mitm = require 'mitm'
URI = require 'urijs'
URL = require('url');
util = require 'util'


toLocalPath = (basedir = "", url) ->
  uri = URI(url)
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
        path = toLocalPath @basedir , request.url()
        @log.debug? "Storing #{request.url()} to #{path}"
        request.channels().stream Mimetypes([/.*/g]), fse.createOutputStream path

  initialize: (context) ->
    super context
    @basedir = context.config.basePath()


class OfflineServer extends Extension

  LocalHttpServer = require('../util/httpserver').LocalHttpServer

  @defaultOpts =
    port : 3000

  constructor: (opts = {}) ->
    super {}
    @opts = @merge OfflineServer.defaultOpts, opts

  initialize: (context) ->
    super context
    @opts.basedir = context.config.basePath() + "/"
    @server =  new LocalHttpServer @opts.port, @opts.basedir
    @server.start()
    @mitm = Mitm()
    # Don't intercept connections to localstorage
    @mitm.on 'connect', (socket, opts) =>
      url = opts.uri?.href
      @log.debug? "MITM: Intercepting #{url}"
      if opts.host is 'localhost' or not @server.canServe url
        @log.debug? "MITM: ByPass"
        socket.bypass()
    # Redirect requests to local server
    @mitm.on 'request', (request, response) =>
      url = "http://#{request.headers.host}#{request.url}"
      localUrl = toLocalPath "http://localhost:3000", url
      @log.debug? "MITM: Receiving request to #{url} translating to #{localUrl}"
      response.writeHead 302, 'Location': localUrl
      response.end()


  shutdown: () ->
    @server.stop()

module.exports = {
  OfflineStorage
  OfflineServer
}