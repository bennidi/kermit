- Use multiple user agents
- Extend OfflineServer such that it cancels requests to URLs that exist locally


AVOIDING DETECTION
+ Scheduler accepts "users". A user encapsulates the behaviour of how links are traversed.
This implies a redesign of the scheduler to accept batches of urls. Metadata can be used to set an "owner"
of a url. Owner propagates downwards (transitive). Users can have different behaviours (depth-first, breadth-first).
First user is "kermit". Kermit behaves as the scheduler behaves currently.
+ Randomly issue requests to already visited urls (as every user would do)
+ Rotate user agents


IDEAS / FEATURES
 + Count computation time in Monitoring and publish as separate log entry
 + Add overall request timings to Monitoring
  
  
POLISH
 + Logging
   + Add new log levels at runtime. Use this for adding log.request with request.log in Completer
   + Add serializers based on types 
 + In QUEUE stats show subcategories (like http/https) per status. Use Regex as general approach
 
 
FIX
  + Introduce log level WARN. Log ResultVerification to WARN
  + ResultVerification does not properly stop (problem with content-type=undefined)
  + Add request id to log statement when "executing"
  
TESTING
 + UrlStore: Counters, Rescheduling
 
QUESTIONS
 + How to synchronize the two store callbacks (async library..?)
     
