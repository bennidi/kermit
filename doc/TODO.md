  + add stamp() method to request for producing timestamps stored in nested object
  + rename ByUrl to ByPattern
  + rename Response to Pipeline (method in request is channels())
  + Add local storage resolution mechanism using mitm.js
  + come up with idea on reliable shutdown hook
  + Reorder classes
  + Add more coffeedoc
  + Try with fresh node install to see if all dependencies are met
  + Add tests for
    + rate limiting
  + Performance
   + Queueing: Instead of querying at intervals, checkout a local batch and feed 
   from that batch until empty. This will reduce amount of queries and prepare for remote queuing 
   backend
  + Design interface for queue that is local/remote agnostic
  + Add request to trace.log when removed from queue
  + Move all statistics generation into dedicated extension
   
