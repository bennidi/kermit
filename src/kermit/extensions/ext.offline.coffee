{Extension} = require '../Extension'
{ContentType} = require '../Pipeline'
fse = require 'fs-extra'
fs = require 'fs'
Mitm = require 'mitm'
_ = require 'lodash'
{uri, files, obj} = require '../util/tools'



###
 Store downloaded data on local filesystem
###
class OfflineStorage extends Extension

  @errors =
    OSNODIR : """
      Extension OfflineStorage needs the basedir to be specified as root for storage of files.
      Please provide property 'basedir' (withoud trailing slash) in the options.
    """

  @defaults = ->
    ifFileExists : 'skip' # [skip,update,rename?]
    basedir: ''

  constructor: (opts = {}) ->
    super opts
    throw new Error OfflineStorage.errors.OSNODIR if _.isEmpty @options.basedir
    shouldStore = (path) =>
      @log.debug? "#{path} already exists" if exists = files.exists path
      @options.ifFileExists is 'update' or not exists
    @on READY: (item) =>
        # Translate URI ending with "/", i.e. /some/path -> some/path/index.html
        path = uri.toLocalPath @options.basedir , item.url()
        if shouldStore path
          @log.debug? "Storing #{item.url()} to #{path}", tags: ['OfflineStorage']
          target = fse.createOutputStream path
          item.pipeline().stream ContentType([/.*/]), target

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

  @defaults : ->
    port : 3000
    cancelation:off

  constructor: (options = {}) ->
    super options
    throw new Error OfflineServer.errors.OSNODIR if _.isEmpty @options.basedir
    if @options.cancelation
      @on SPOOLED: (item) =>
        localFilePath = uri.toLocalPath @options.basedir, item.url()
        if files.exists localFilePath then item.cancel "Content already available offline"


  initialize: (context) ->
    super context
    @server =  new LocalHttpServer @options.port, @options.basedir + "/"
    @onStart => @server.start()
    @onStop => @server.stop()
    @mitm = Mitm()
    @mitm.on 'connect', (socket, opts) =>
    # Don't intercept connections to local storage
      if opts.host is 'localhost'
        return socket.bypass()
      url = opts.uri?.href
      localFilePath = uri.toLocalPath @options.basedir, url
      # Do not redirect if file doesn't exist.
      if not files.exists localFilePath
        @log.debug? "No local version found for #{url}", tags: ['OfflineServer']
        socket.bypass()
    # Redirect items to local server
    @mitm.on 'request', (item, response) =>
      url = "http://#{item.headers.host}#{item.url}"
      localUrl = uri.toLocalPath "http://localhost:#{@options.port}", url
      @log.debug? "Redirecting #{url} to #{localUrl}", tags: ['OfflineServer']
      response.writeHead 302, 'Location': localUrl, 'Set-Cookie': "rid=#{obj.randomId()}"
      response.end()

module.exports = {
  OfflineStorage
  OfflineServer
}
