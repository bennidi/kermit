{CrawlRequest, Status} = require('./CrawlRequest')
{MockContext} = require('./util/spec.utils.coffee')
Queue = require('./QueueManager')

describe  'Requests',  ->
  describe 'have a lifecycle reflected as a transitions of states', ->
    log = new MockContext().log

    it '# is in state INITIAL when newly instantiated', ->
      expect(CrawlRequest).not.to.be.null()
      TestRequest = new CrawlRequest 'localhost',
      expect(TestRequest).not.to.be.null()
      expect(TestRequest.status()).to.equal(Status.INITIAL)
      expect(TestRequest.parents()).to.equal(0)

    it '# should notify state listeners when changes occurr', ->
      receivedStatusChanges = []
      TestRequest = new CrawlRequest 'localhost'
        .onChange 'status', (request) ->
          receivedStatusChanges.push request.status()
      TestRequest.status('STATE1')
      TestRequest.status('STATE2')
      TestRequest.status('STATE3')
      expect(receivedStatusChanges).to.contain 'STATE1','STATE2','STATE3'

    it '# should respond to different errors with corresponding state transitions', ->
      request = new CrawlRequest 'localhost'
      request.error('TIMEOUT')
      # TODO assertions


    it '# can change its uri', ->
      request = new CrawlRequest('localhost')
      expect(request.url()).to.equal('localhost')
      request.url('wikipedia.org')
      expect(request.url()).to.equal('wikipedia.org')

    it '# can pretty print it timestamps', ->
      stamps =
        INITIAL : [1243242342]
        TESTING : [1243242342,1243242342,1243242343,1243242345,1243242348]
      expect(CrawlRequest.stampsToString(stamps).TESTING).to.contain "0ms,1ms,2ms,3ms"
      expect(CrawlRequest.stampsToString(stamps).INITIAL).to.equal "(1243242342)"

    it '# can pretty print using toString()', ->
      request = new CrawlRequest('localhost')
      request.state.stamps =
        INITIAL : [1243242342]
        TESTING : [1243242342,1243242342,1243242343,1243242345,1243242348]
      console.log request.toString()
      expect(request.toString()).to.contain "0ms,1ms,2ms,3ms"
