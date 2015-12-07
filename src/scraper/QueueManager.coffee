{Status} = require './CrawlRequest'
lokijs = require 'lokijs'

class QueueManager
  constructor: (@store = new lokijs 'crawlrequests.json') ->
    @initialize()

  initialize: () ->
    # One collection for all requests and dynamic views for various request states
    @requests = @store.addCollection 'requests'
    @visited = @store.addCollection 'visited', unique: ['url']

    # Requests that have been spooled, aka ready to be processed
    created = @requests.addDynamicView('created')
    created.applyWhere (request) ->
      request.status is Status.INITIAL

    spooled = @requests.addDynamicView('spooled')
    spooled.applyWhere (request) ->
      request.status is Status.SPOOLED

  update: (request) ->
    @requests.update(request.state)

  # check for any request with the given url
  contains: (url) ->
    alreadyVisited = @visited.find("url":url).length
    return true if alreadyVisited > 0
    # Either in processing
    inProgress = @requests.find('$and': [
      {'url' : url},
      {'status' : {"$in": ["SPOOLED", "FETCHING", "FETCHED", "COMPLETED"]}}
    ]).length
    # or stored as
    inProgress > 0

  completed: (request) ->
    @visited.insert({url: request.url(), rId: request.id()})
    @requests.remove(request.state)

  # Determines whether there are unfetched requests remaining
  requestsRemaining: ->
    @requests.getDynamicView('spooled').data().length > 0

  created: () ->
    @requests.getDynamicView('created').data()

  spooled: () ->
    @requests.getDynamicView('spooled').branchResultset().simplesort('tsSpooled', true).limit(20).data()

  trace: (request) ->
    @requests.insert request.state
    request.onChange 'status', (request) =>
      @requests.update(request.state)

module.exports = {
  QueueManager
}
