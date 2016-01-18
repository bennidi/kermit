  + Add local storage resolution mechanism using mitm.js
  + implement rest-api for remote control (request submission, pause/resume, shutdown)
  + Reorder classes
  + Add more coffeedoc (Pipeline)
  + Add tests for
    + rate limiting
  + Performance
   + Queueing: Instead of querying at intervals, checkout a local batch and feed 
   from that batch until empty. This will reduce amount of queries and prepare for remote queuing 
   backend
   + Filtering is currently done twice
  + Design interface for queue that is local/remote agnostic
  + Design nice request.toString() method
  + Add request to trace.log when removed from queue
