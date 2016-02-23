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

###
 Store downloaded data on local filesystem
###
class OfflineStorage extends Extension

  @errors =
    OSNODIR : """
      Extension OfflineStorage needs the basedir to be specified as root for storage of files.
      Please provide property 'basedir' (withoud trailing slash) in the options.
    """

  @defaultOpts = ->
    ifFileExists : 'skip' # [skip,update,rename?]
    basedir: ''

  constructor: (opts = {}) ->
    @opts = @merge OfflineStorage.defaultOpts(), opts
    throw new Error OfflineStorage.errors.OSNODIR if _.isEmpty @opts.basedir
    shouldStore = (path) =>
      @log.debug? "#{path} already exists" if exists = fileExists path
      @opts.ifFileExists is 'update' or not exists
    super
      READY: (item) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = uri.toLocalPath @opts.basedir , item.url()
        if shouldStore path
          @log.debug? "Storing #{item.url()} to #{path}", tags: ['OfflineStorage']
          target = fse.createOutputStream path
          item.pipeline().stream ContentType([/.*/g]), target

###
  Redirect requests to web URLs to local storage. This allows to serve (previously downloaded) content
  offline.

  IMPORTANT: Do not use with enabled keep-alive option

  @see OfflineStorage
###
class OfflineServer extends Extension

  LocalHttpServer = require('../util/httpserver').LocalHttpServer

  @errors =
    OSNODIR : """
      Extension OfflineServer needs the basedir from where files are served.
      Please provide property 'basedir' (withoud trailing slash) in the options.
    """

  @defaultOpts = ->
    port : 3000

  constructor: (opts = {}) ->
    @opts = @merge OfflineServer.defaultOpts(), opts
    throw new Error OfflineServer.errors.OSNODIR if _.isEmpty @opts.basedir

  initialize: (context) ->
    super context
    @server =  new LocalHttpServer @opts.port, @opts.basedir + "/"
    @messenger.subscribe 'commands.start', => @server.start()
    @messenger.subscribe 'commands.stop', => @server.stop()
    @mitm = Mitm()
    @mitm.on 'connect', (socket, opts) =>
    # Don't intercept connections to local storage
      if opts.host is 'localhost'
        return socket.bypass()
      url = opts.uri?.href
      localFilePath = uri.toLocalPath @opts.basedir, url
      # Do not redirect if file doesn't exist.
      if not fileExists localFilePath
        @log.debug? "No local version found for #{url}", tags: ['OfflineServer']
        socket.bypass()
      @log.debug "Connection to #{url} redirects to #{localFilePath}"
    # Redirect items to local server
    @mitm.on 'request', (item, response) =>
      url = "http://#{item.headers.host}#{item.url}"
      localUrl = uri.toLocalPath "http://localhost:3000", url
      @log.debug? "Redirecting #{url} to #{localUrl}", tags: ['OfflineServer']
      response.writeHead 302, 'Location': localUrl
      response.end()

module.exports = {
  OfflineStorage
  OfflineServer
}