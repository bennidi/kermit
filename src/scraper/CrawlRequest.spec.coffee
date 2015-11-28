Request = require('./CrawlRequest')
Queue = require('./QueueManager')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->

    it '# is in state INITIAL when newly instantiated', ->
      TestRequest = new Request 'localhost'
      expect(TestRequest).not.to.be.null()
      expect(TestRequest.status()).to.equal(Request.Status.INITIAL)
      expect(TestRequest.depth()).to.equal(0)

    it '# should notify state listeners when changes occurr', ->
      receivedStatusChanges = []
      TestRequest = new Request('localhost').onChange 'status', (state) ->
        receivedStatusChanges.push state.status
      TestRequest.status('STATE1')
      TestRequest.status('STATE2')
      TestRequest.status('STATE3')
      expect(receivedStatusChanges).to.contain('STATE1','STATE2','STATE3')

    it '# should respond to different errors with corresponding state transitions', ->
      request = new Request('localhost')
      request.error('TIMEOUT')
      # TODO assertions


    it '# can create follow up requests', ->
      request = new Request('localhost')
      someFile = request.subrequest('some/file.txt')
      expect(someFile).not.to.be.null()
      expect(someFile.status()).to.equal(Request.Status.INITIAL)
      expect(someFile.depth()).to.equal(1)
    # TODO assertions
