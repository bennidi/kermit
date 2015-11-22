urijs = require 'urijs'
store = require 'lokijs'
crawl =
  requests: {}
  extensions: {}
  storage: {}
crawl.requests.Request = require('./CrawlRequest').CrawlRequest
crawl.requests.Status = require('./CrawlRequest').Status
crawl.storage.Queue = require('./QueueManager').QueueManager
crawl.extensions.Extension = require('./Extension').Extension
crawl.extensions.ExtensionDescriptor = require('./Extension.coffee').ExtensionDescriptor


class EnqueueRequest extends crawl.extensions.Extension

  constructor: ->
    super(new crawl.extensions.ExtensionDescriptor "EnqueueRequest", ["NewRequest"])

  apply: (request, control) ->
    control.queue.insert(request)


class ExtensionPoint

  constructor: (@phase, @description = "Please provide a description") ->

class RequestCreated extends ExtensionPoint

  constructor: () ->
    super "NewRequest", "This extension point marks the beginning of a request cycle."

class Control

  constructor: (@queue) ->

  pass: (request) ->


class Crawler

  constructor: (extensions) ->
    @registeredExtensions = {}
    @addExtension extension for extension in extensions
    @queue = new crawl.storage.Queue
    @extensionPoints = [
      new RequestCreated
    ]


  # Add an extension to the crawler
  #
  # @example add an extension
  #   crawler.addExtension(new SimpleExtension)
  #
  # @param [Extension] extension the extension to add
  #
  addExtension: (extension) ->
    @extensions(point).push(extension) for point in extension.targets()

  extensions: (extension) ->
    if !@registeredExtensions[extension]?
      @registeredExtensions[extension] = []
    @registeredExtensions[extension]

  crawl: (url) ->
    request = new crawl.requests.Request url
    extensionsInPhase = @extensions 'NewRequest'
    extension.apply(request) for extension in extensionsInPhase

  start: () ->
    process.nextTick () =>
      spooled = @queue.spooled()
      if spooled.length > 0
        spooled[0].status crawl.Status.FETCHING
      else


module.exports = {
  Crawler,
  Extension: crawl.extensions.Extension
  ExtensionDescriptor: crawl.extensions.ExtensionDescriptor
}