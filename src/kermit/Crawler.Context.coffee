{Mixin} = require 'coffee-latte'
EventEmitter = require('eventemitter2').EventEmitter2
notifier = require 'node-notifier'

class EventSupport

  constructor : ->
    @_emitter = new EventEmitter
      wildcard: true # Attention: Using wild card events is considerably slower then non-wildcard
      delimiter: ':'
      newListener: false
      maxListeners: 20

  # @see EventEmitter#on
  on: (event, fnc) ->
    @_emitter.on event, fnc

  # @see EventEmitter#off
  off: (event, fnc) ->
    @_emitter.off event, fnc

  # @see EventEmitter#emit
  emit:(event, data) ->
    try
      @_emitter.emit event, data
    catch err
      @log.error? "#{obj.nameOf @}:#{err.message}"

# A container for properties that need to be shared among all instances of {ExtensionPoint} and {Extension}
# of a given {Crawler}. Each {Crawler} has its own, distinct context that it passes to all its extension points.
#
# Any Extension or ExtensionPoint may modify the context to expose additional functionality
# to other Extensions or ExtensionPoints
class CrawlerContext extends Mixin
  @with EventSupport

  # Construct a new CrawlerContext
  #
  # @param [Object] config The configuration object for this context
  # @option config [Crawler] crawler The crawler that created this context
  # @option config [Function] execute A function handle to execute an extension point
  # @option config [bunyan.Logger] log A logger to handle log messages
  constructor: (config) ->
    super()
    @crawler = config.crawler
    @log = config.log
    @config = config.crawler.config
    @qs = config.qs

  # @see [Crawler#schedule]
  schedule : (url, meta) ->
    @crawler.schedule url, meta

  # Access to execution logic of
  # @see [Crawler#execute]
  crawl : (url, meta) ->
    @crawler.crawl url, meta

  # @private
  # @nodoc
  processItem : (item) ->
    @crawler.scheduleExecution item.phase(), item

  # Create a child context that shares all properties with its parent context.
  # The child context exposes a method to share properties with all other child contexts
  # @return [CrawlerContext] A new child context of this context
  fork: ->
    child = Object.create this
    child.share = (property, value) =>
      @[property] = value
    child


  notify: (msg) ->
    notifier.notify title:"Crawler:#{@crawler.name}", message: msg

###

###
class ContextAware

  importContext : (context) ->
    @context = context
    @log = context.log
    @qs = context.qs
    @crawler = context.crawler

module.exports = {
  CrawlerContext
  ContextAware
}
