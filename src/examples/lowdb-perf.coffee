lowdb = require 'lowdb'
testdb = lowdb()
{obj} = require '../kermit/util/tools.coffee'


pool = []
for cnt in [1..10000]
  pool.push {id1: obj.randomId(), id2: obj.randomId()}
console.log "Built pool"
start = new Date()
for myObj in pool
  testdb('objects').push myObj
end = new Date()
console.log "Insertion fo 10000 docs took: #{end-start}ms"