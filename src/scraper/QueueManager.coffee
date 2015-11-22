States = require('./CrawlRequest').Status
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
      request.status is States.CREATED
    #created.applySimpleSort('tsLastModified', true);

    # Requests that have been spooled, aka ready to be processed
    spooled = @requests.addDynamicView('spooled')
    spooled.applyWhere (request) ->
      request.status is States.SPOOLED
    #spooled.applySimpleSort('tsLastModified', true);



  created: () ->
    @requests.getDynamicView('created').data()

  spooled: () ->
    @requests.getDynamicView('spooled').data()


  trace: (request) ->
    @requests.insert request.state
    console.log request.state['$loki']
    console.log request.state.status
    request.onChange 'status', (state) =>
      console.log "updating state of #{state['$loki']}"
      @requests.update(state)

module.exports = {
  QueueManager
}
