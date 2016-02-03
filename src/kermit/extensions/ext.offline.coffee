{Phase} = require '../CrawlRequest'
{Extension} = require '../Extension'
{byExtension} = require '../util/mimetypes.coffee'
{Mimetypes} = require('../Pipeline.coffee')
fse = require 'fs-extra'
fs = require 'fs'
Mitm = require 'mitm'
URI = require 'urijs'
_ = require 'lodash'

fileExists = (path) ->
  try
    stats = fs.statSync path
    stats?
  catch err
    false


toLocalPath = (basedir = "", url) ->
  url = url.replace 'www', ''
  uri = URI(url)
  uri.normalize()
  #normalizedPath = if uri.path().endsWith "/" then uri.path().substring(0, uri.path().length - 1) else uri.path()
  #uri.path normalizedPath
  uri.filename("index.html") if (!uri.suffix() or not byExtension[uri.suffix()])
  domainWithoutTld = uri.domain().replace ".#{uri.tld()}", ''
  subdomain = uri.subdomain()
  subdomain = "/#{subdomain}" if not _.isEmpty subdomain
  lastDot = uri.path().lastIndexOf '.'
  augmentedPath = [uri.path().slice(0, lastDot), uri.query(), uri.path().slice(lastDot)].join('');
  "#{basedir}/#{uri.tld()}/#{domainWithoutTld}#{subdomain}#{augmentedPath}"

# Store request results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  @defaultOpts = () ->
    ifFileExists : 'skip' # [skip,update,rename?]

  constructor: (opts = {}) ->
    @opts = @merge OfflineStorage.defaultOpts(), opts
    super
      READY: (request) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = toLocalPath @basedir , request.url()
        if @shouldStore path
          @log.debug? "Storing #{request.url()} to #{path}", tags: ['OfflineStorage']
          request.pipeline().stream Mimetypes([/.*/g]), fse.createOutputStream path

  shouldStore: (path) ->
    @log.debug? "#{path} already exists" if exists = fileExists path
    @opts.ifFileExists is 'update' or not exists

  initialize: (context) ->
    super context
    @basedir = context.config.basePath()


class OfflineServer extends Extension

  LocalHttpServer = require('../util/httpserver').LocalHttpServer

  @defaultOpts = () ->
    port : 3000

  constructor: (opts = {}) ->
    super {}
    @opts = @merge OfflineServer.defaultOpts(), opts

  initialize: (context) ->
    super context
    @opts.basedir = context.config.basePath()
    @server =  new LocalHttpServer @opts.port, @opts.basedir + "/"
    @server.start()
    @mitm = Mitm()
    # Don't intercept connections to localstorage
    @mitm.on 'connect', (socket, opts) =>
      url = opts.uri?.href
      localFilePath = toLocalPath @opts.basedir, url
      return socket.bypass() if opts.host is 'localhost'
      if not fileExists localFilePath
        @log.debug? "No local version found for #{url}", tags: ['OfflineServer']
        socket.bypass()
    # Redirect requests to local server
    @mitm.on 'request', (request, response) =>
      url = "http://#{request.headers.host}#{request.url}"
      localUrl = toLocalPath "http://localhost:3000", url
      @log.debug? "Redirecting #{url} to #{localUrl}", tags: ['OfflineServer']
      response.writeHead 302, 'Location': localUrl
      response.end()


  shutdown: () ->
    @server.stop()

module.exports = {
  OfflineStorage
  OfflineServer
}