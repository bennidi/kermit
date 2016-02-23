{ExtensionPoint} = require './Crawler.ExtensionPoints'
postal = require 'postal'

# A container for properties that need to be shared among all instances of {ExtensionPoint} and {Extension}
# of a given {Crawler}. Each {Crawler} has its own, distinct context that it passes to all its extension points.
#
# Any Extension or ExtensionPoint may modify the context to expose additional functionality
# to other Extensions or ExtensionPoints
class CrawlerContext

  # Construct a new CrawlerContext
  #
  # @param [Object] config The configuration object for this context
  # @option config [Crawler] crawler The crawler that created this context
  # @option config [Function] execute A function handle to execute an extension point
  # @option config [bunyan.Logger] log A logger to handle log messages
  constructor: (config) ->
    @crawler = config.crawler
    @log = config.log
    @config = config.crawler.config
    @qs = config.qs
    @messenger =
      subscribe : (cmd, handler) -> postal.subscribe {channel: 'main', topic: cmd, callback: handler}
      publish :  (cmd, data) -> postal.publish {channel: 'main', topic: cmd, data: data}

  # @see [Crawler#schedule]
  schedule : (url, meta) ->
    @crawler.schedule url, meta

  # Access to execution logic of
  # @see [Crawler#execute]
  execute : (url, meta) =>
    @crawler.execute url, meta

  executeRequest : (item) ->
    ExtensionPoint.execute @crawler, item.phase(), item

  # Create a child context that shares all properties with its parent context.
  # The child context exposes a method to share properties with all other child contexts
  # @return [CrawlerContext] A new child context of this context
  fork: ->
    child = Object.create this
    child.share = (property, value) =>
      @[property] = value
    child

class ContextAware

  importContext : (context) ->
    @context = context
    @log = context.log
    @qs = context.qs
    @crawler = context.crawler
    @messenger = context.messenger

module.exports = {
  CrawlerContext
  ContextAware
}