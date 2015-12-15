{CrawlRequest, Status} = require('./CrawlRequest')
{MockContext} = require('./util/spec.utils.coffee')
Queue = require('./QueueManager')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->


    it '# is in state INITIAL when newly instantiated', ->
      expect(CrawlRequest).not.to.be.null()
      TestRequest = new CrawlRequest 'localhost', new MockContext
      expect(TestRequest).not.to.be.null()
      expect(TestRequest.status()).to.equal(Status.INITIAL)
      expect(TestRequest.predecessors()).to.equal(0)

    it '# should notify state listeners when changes occurr', ->
      receivedStatusChanges = []
      TestRequest = new CrawlRequest('localhost', new MockContext).onChange 'status', (request) ->
        receivedStatusChanges.push request.status()
      TestRequest.status('STATE1')
      TestRequest.status('STATE2')
      TestRequest.status('STATE3')
      expect(receivedStatusChanges).to.contain('STATE1','STATE2','STATE3')

    it '# should respond to different errors with corresponding state transitions', ->
      request = new CrawlRequest('localhost')
      request.error('TIMEOUT')
      # TODO assertions


    it '# can create follow up requests', ->
      request = new CrawlRequest('localhost', new MockContext)
      someFile = request.subrequest('some/file.txt')
      expect(someFile).not.to.be.null()
      expect(someFile.status()).to.equal(Status.INITIAL)
      expect(someFile.predecessors()).to.equal(1)

    it '# can change its uri', ->
      request = new CrawlRequest('localhost', new MockContext)
      expect(request.url()).to.equal('localhost')
      request.uri('wikipedia.org')
      expect(request.url()).to.equal('wikipedia.org')
