{Phase} = require '../RequestItem'
{Extension} = require '../Extension'
{byExtension} = require '../util/mimetypes'
{ContentType} = require '../Pipeline'
fse = require 'fs-extra'
fs = require 'fs'
Mitm = require 'mitm'
URI = require 'urijs'
_ = require 'lodash'
{uri} = require '../util/tools'

fileExists = (path) ->
  try
    stats = fs.statSync path
    stats?
  catch err
    false




# Store item results in local repository for future serving from filesystem
class OfflineStorage extends Extension

  @errors =
    OSNODIR : """
      Extension OfflineStorage needs the basedir to be specified as root for storage of files.
      Please provide property basedir (withoud trailing slash) in the options.
    """

  @defaultOpts = () ->
    ifFileExists : 'skip' # [skip,update,rename?]

  constructor: (opts = {}) ->
    @opts = @merge OfflineStorage.defaultOpts(), opts
    throw new Error OfflineStorage.errors.OSNODIR if _.isEmpty @opts.basedir
    super
      READY: (item) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = uri.toLocalPath @opts.basedir , item.url()
        if @shouldStore path
          @log.debug? "Storing #{item.url()} to #{path}", tags: ['OfflineStorage']
          target = fse.createOutputStream path
          #target.on "error", (error) =>
          #  @log.error? "Error storing file #{path}", {error:error, trace:error.stack}
          item.pipeline().stream ContentType([/.*/g]), target

  shouldStore: (path) ->
    @log.debug? "#{path} already exists" if exists = fileExists path
    @opts.ifFileExists is 'update' or not exists


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
    @messenger.subscribe 'commands.start', () => @server.start()
    @messenger.subscribe 'commands.stop', () => @server.stop()
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

module.exports = {
  OfflineStorage
  OfflineServer
}