{Status} = require('./CrawlRequest')
lokijs = require 'lokijs'

class QueueManager
  constructor: (@store = new lokijs 'crawlrequests.json') ->
    @initialize()

  initialize:() ->
    # One collection for all requests and dynamic views for various request states
    @requests = @store.addCollection 'requests'

    # Requests that have just been created
    created = @requests.addDynamicView('created')
    created.applyWhere (request) ->
      request.status is Status.INITIAL
    #created.applySimpleSort('tsLastModified', true);

    # Requests that have been spooled, aka ready to be processed
    spooled = @requests.addDynamicView('spooled')
    spooled.applyWhere (request) ->
      request.status is Status.SPOOLED
    #spooled.applySimpleSort('tsLastModified', true);


# check for any request with the given url
  contains: (url) -> false

  # Determines whether there are unfetched requests remaining
  requestsRemaining: ->
    remaining = @created().length + @spooled().length
    remaining > 0

  created: () ->
    @requests.getDynamicView('created').data()

  spooled: () ->
    @requests.getDynamicView('spooled').data()

  trace: (request) ->
    @requests.insert request.state
    request.onChange 'status', (state) =>
      @requests.update(state)

module.exports = {
  QueueManager
}
