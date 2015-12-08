{Status} = require './CrawlRequest'
lokijs = require 'lokijs'

class QueueManager
  constructor: (@store = new lokijs 'crawlrequests.json') ->
    @initialize()

  initialize: () ->
    # One collection for all requests and dynamic views for various request status
    @requests = @store.addCollection 'requests'
    @visited = @store.addCollection 'visited', unique: ['url']
    # Fresh requests
    @requests.addDynamicView('INITIAL')
             .applyWhere (request) ->
                request.status is Status.INITIAL
    # Requests that have been SPOOLED, aka ready to be processed
    @requests.addDynamicView('SPOOLED')
             .applyWhere (request) ->
                request.status is Status.SPOOLED

  update: (request) ->
    @requests.update(request.state)

  # check for any request with the given url
  contains: (url) ->
    alreadyVisited = @visited.find("url":url).length
    return true if alreadyVisited > 0
    # Either in processing
    inProgress = @requests.find $and: [
      {url : url},
      {status : {$in: ["SPOOLED", "FETCHING", "FETCHED", "COMPLETED"]}}
    ]
    inProgress.length > 0

  completed: (request) ->
    # remember that url has been processed successfully
    @visited.insert({url: request.url(), rId: request.id()})
    # remove request data from storage
    @requests.remove(request.state)

  # Determines whether there are unfetched requests remaining
  requestsRemaining: ->
    @requests.getDynamicView('SPOOLED').data().length > 0

  initial: () ->
    @requests.getDynamicView('INITIAL').data()

  spooled: () ->
    @requests.getDynamicView('SPOOLED').branchResultset().simplesort('tsSPOOLED', true).limit(20).data()

  trace: (request) ->
    @requests.insert request.state
    request.onChange 'status', (request) =>
      @requests.update(request.state)

module.exports = {
  QueueManager
}
