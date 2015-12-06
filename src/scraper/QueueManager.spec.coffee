{CrawlRequest} = require('./CrawlRequest')
Queue = require('./QueueManager').QueueManager
{MockContext} = require './util/testutils.coffee'

describe  'QueueManager',  ->
  describe 'manages requests in different states', ->

    it '# has empty queues when newly created', ->
      QueueManager = new Queue
      expect(QueueManager).not.to.be.null()
      expect(QueueManager.created).not.to.be.null()
      expect(QueueManager.spooled).not.to.be.null()
      expect(QueueManager.created().length).to.equal(0)
      expect(QueueManager.spooled().length).to.equal(0)

    it '# can enrich requests for state tracing', ->
      QueueManager = new Queue
      TestRequest = new CrawlRequest 'www.npmjs.com', new MockContext
      QueueManager.trace TestRequest
      expect(QueueManager.created().length).to.equal(1)
      expect(QueueManager.spooled().length).to.equal(0)
      TestRequest.spool()
      expect(QueueManager.created().length).to.equal(0)
      expect(QueueManager.spooled().length).to.equal(1)
