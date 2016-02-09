{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{byExtension} = require '../util/mimetypes'
{ContentType} = require '../Pipeline'
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
  uri.filename("index.html") if (!uri.suffix() or not byExtension[uri.suffix()])
  domainWithoutTld = uri.domain().replace ".#{uri.tld()}", ''
  subdomain = uri.subdomain()
  subdomain = "/#{subdomain}" if not _.isEmpty subdomain
  separator = if uri.query() then '-' else ''
  lastDot = uri.path().lastIndexOf '.'
  augmentedPath = [uri.path().slice(0, lastDot), separator, uri.query(), uri.path().slice(lastDot)].join('');
  "#{basedir}/#{uri.tld()}/#{domainWithoutTld}#{subdomain}#{augmentedPath}"

# Store item results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  @defaultOpts = () ->
    ifFileExists : 'skip' # [skip,update,rename?]

  constructor: (opts = {}) ->
    @opts = @merge OfflineStorage.defaultOpts(), opts
    super
      READY: (item) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = toLocalPath @basedir , item.url()
        if @shouldStore path
          @log.debug? "Storing #{item.url()} to #{path}", tags: ['OfflineStorage']
          item.pipeline().stream ContentType([/.*/g]), fse.createOutputStream path

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
      if opts.host is 'localhost'
        @log.debug? "Bypassing connection to host=localhost"
        return socket.bypass()
      if not fileExists localFilePath
        @log.debug? "No local version found for #{url}", tags: ['OfflineServer']
        socket.bypass()
      @log.debug "Connection to #{url} redirects to #{localFilePath}"
    # Redirect items to local server
    @mitm.on 'request', (item, response) =>
      @log.debug? "Receiving item"
      url = "http://#{item.headers.host}#{item.url}"
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