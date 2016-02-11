Datastore = require 'nedb'
testdb = new Datastore()
{obj} = require '../kermit/util/tools.coffee'
sync = require('synchronize')
sync(testdb, 'find')


testdb.ensureIndex { fieldName: 'id1' , unique:true},  (err) ->
pool = []
for cnt in [1..100000]
  pool.push {id1: obj.randomId(), id2: obj.randomId()}
console.log "Built pool"
start = new Date()
for myObj in pool
  testdb.insert {id1:"fdfdsfsd"}, (err, result) -> console.log err if err
end = new Date()
console.log "Insertion of 10000 docs took: #{end-start}ms"


sync.fiber () ->
  start = new Date()
  for myObj in pool
    obj = testdb.find {id1: myObj.id1}
  end = new Date()
  console.log "Lookup of 10000 docs took: #{end-start}ms"
