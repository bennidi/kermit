lokijs = require 'lokijs'
testdb = new lokijs '/tmp/dsjaknd.json'
{obj} = require '../kermit/util/tools.coffee'

objectCollection= testdb.addCollection 'objects', indices: ['id1']
pool = []
for cnt in [1..100000]
  pool.push {id1: obj.randomId(), id2: obj.randomId()}
console.log "Built pool"
start = new Date()
for myObj in pool
  objectCollection.insert myObj
end = new Date()
console.log "Insertion fo 10000 docs took: #{end-start}ms"

start = new Date()
for myObj in pool
  console.log objectCollection.find {id1:myObj.id1}
end = new Date()
console.log "Lookup of 10000 docs took: #{end-start}ms"