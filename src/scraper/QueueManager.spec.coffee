{CrawlRequest} = require('./CrawlRequest')
Queue = require('./QueueManager').QueueManager
{MockContext} = require './util/testutils.coffee'

describe  'QueueManager',  ->
  describe 'manages requests in different states', ->

    it '# has empty queues when newly created', ->
      QueueManager = new Queue
      expect(QueueManager).not.to.be.null()
      expect(QueueManager.initial).not.to.be.null()
      expect(QueueManager.spooled()).not.to.be.null()
      expect(QueueManager.initial().length).to.equal(0)
      expect(QueueManager.spooled().length).to.equal(0)
