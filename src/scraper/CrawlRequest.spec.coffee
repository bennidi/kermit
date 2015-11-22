requests = require('./CrawlRequest')
Request = requests.CrawlRequest
Queue = require('./QueueManager')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->

    it '# is in state CREATED when newly instantiated', ->
      TestRequest = new Request 'localhost'
      expect(TestRequest).not.to.be.null()
      expect(TestRequest.status()).to.equal(requests.Status.CREATED)

    it '# should notify state listeners when changes occurr', ->
      receivedStatusChanges = []
      TestRequest = new Request('localhost').onChange 'status', (state) ->
        receivedStatusChanges.push state.status
      TestRequest.status('STATE1')
      TestRequest.status('STATE2')
      TestRequest.status('STATE3')
      expect(receivedStatusChanges).to.contain('STATE1','STATE2','STATE3')

