{RequestItem} = require('./RequestItem')
{QueueSystem} = require('./QueueSystem')
{MockContext} = require './util/spec.utils'
{obj} = require './util/tools'

describe  'QueueSystem',  ->
  @timeout 2000
  describe 'manages items in different states', ->
    context = new MockContext
    it '# has empty queues when newly created', ->
      QS = new QueueSystem
        filename: "./target/testing/queuesystem/#{obj.randomId()}"
        log: context.log
        onReady : ->
      expect(QS.items().spooled().length).to.equal(0)
      expect(QS.items().waiting().length).to.equal(0)
      expect(QS.items().fetching().length).to.equal(0)
      expect(QS.items().unfinished().length).to.equal(0)
      expect(QS.urls().count 'scheduled').to.equal(0)
      expect(QS.urls().count 'processing').to.equal(0)
      expect(QS.urls().count 'visited').to.equal(0)

    filename =  "./target/testing/queuesystem/#{obj.randomId()}"
    it '# stores requests and urls', (done) ->
      QS = new QueueSystem
        filename:filename
        log: context.log
        onReady : ->
      for cnt in [1..100]
        QS.initial new RequestItem "localhost:8080/testUrl/#{obj.randomId()}/index.html"
      for cnt in [1..100]
        QS.schedule "localhost:8080/testUrl/#{obj.randomId()}/index.html"

      check =  ->
        expect(QS.items().inPhases(['INITIAL']).length).to.equal(100)
        expect(QS.urls().count 'scheduled').to.equal(100)
        QS.save()
        # TODO: assert files
        done()
      setTimeout check, 400


    it '# can be initialized with snapshots', (done) ->
      # NOTE: Can't load same file twice, see https://github.com/louischatriot/nedb/issues/320
      RestoredQS = new QueueSystem
        filename: './fixtures/queuesys/b5hg6ued'
        log: context.log
        onReady : ->
          expect(RestoredQS.items().inPhases(['INITIAL']).length).to.equal(100)
          #expect(RestoredQS.urls().count 'scheduled').to.equal(100)
          done()

