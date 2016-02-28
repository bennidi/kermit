AVOIDING DETECTION
+ SIMPLE => Go more in direction of Depth-first instead of Breadth-First traversal
+ ADVANCED => Rescheduler sits at INITIAL and reschedules requests to URLS that have lower priorities
+ ADVANCED => Extension: ResultVerifier (check for bad results, like "you're-a-robot" page)
  + Pauses execution (suspend to disk). Can be resumed later on (i.e. after IP change) 


IDEAS / FEATURES
 + Dynamic Scheduling according to runtime statistics (like max. Spooler time)
 + Count computation time in Monitoring and publish as separate log entry
 + Add overall request timings to Monitoring
 + Extension that takes care of automatic shutdown when crawling finished.
  
POLISH
 + Logging
   + Add new log levels at runtime. Use this for adding log.request with request.log in Completer
   + Add serializers based on types 
 + In QUEUE stats show subcategories (like http/https) per status. Use Regex as general approach
  
TESTING
 + UrlStore: Counters, Rescheduling
 
     
     
Pause & Resume Feature

+ Refactor crawler startup (local functions in constructor, use fibre to synchronize)
+ Implement detection of "bad" web pages
+ redesign url scheduler methods to use "upsert" command (increase link juice)