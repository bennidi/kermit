{Extension} = require '../Extension'
{HtmlProcessor} = require './ext.htmlprocessor'
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
  constructor: ->
    @opts = @merge ResourceDiscovery.defaultOpts(), @opts
    @processor = new HtmlProcessor [
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
          @context.schedule url, parents:item.parents()+1 for url in _.reject (_.map results.resources, (item) => @tryLog -> uri.clean base, item.href), _.isNull
          @context.schedule url, parents:item.parents()+1 for url in _.reject (_.map results.links, (item) => @tryLog -> uri.clean base, item.href), _.isNull
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
