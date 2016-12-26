{Extension} = require '../Extension'
{HtmlToJson} = require './ext.htmlprocessor'
_ = require 'lodash'
{HtmlExtractor} = require '../Extractor'
{uri} = require '../util/tools'
{ContentType} = require('../Pipeline')
{InMemoryContentHolder} = require './core.streaming.coffee'


# Scan result data for links to other resources (css, img, js, html) and schedule
# a item to retrieve those resources.
class ResourceDiscovery extends Extension
  @with InMemoryContentHolder(ContentType( [/.*html.*/g] ))

  @defaultOpts: ->
    links : true
    anchors: true
    scripts: true # TODO: implement discovery
    images : true # TODO: implement discovery

  # Create a new resource discovery extension
  constructor: (options) ->
    @processor = new HtmlToJson [
      new HtmlExtractor
        name : 'all'
        select :
          resources: ['link',
            'href':  ($section) -> $section.attr 'href'
          ]
          links: ['a',
            'href':  ($link) -> $link.attr 'href'
          ]
        onResult : (results, item) =>
          base = item.url()
          cleaner = (item) => @tryLog -> uri.clean base, item.href
          resources = results.resources
            ._map cleaner
            ._reject _.isNull
          links = results.links
            ._map cleaner
            ._reject _.isNull
          @context.schedule url, parents:item.parents()+1 for url in resources
          @context.schedule url, parents:item.parents()+1 for url in links
    ]
    super
      FETCHED: @processor.process

  tryLog : (f) ->
    try
      result = f()
    catch error
      result = error
      @log.error? "Error:#{error.msg}, trace: #{error.stack}"
    result



module.exports = {ResourceDiscovery}
