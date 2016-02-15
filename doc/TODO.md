AVOIDING DETECTION
+ SIMPLE => Extension: Introduce Random pauses (Keep items in state FETCHING with random setInterval)
+ SIMPLE => Go more in direction of Depth-first instead of Breadth-First traversal
+ HARDCORE => Rescheduler sits at INITIAL and reschedules requests to URLS that have lower priorities
+ ADVANCED => Extension: ResultVerifier (check for bad results, like "you're-a-robot" page)
  + Pauses execution (suspend to disk). Can be resumed later on (i.e. after IP change) 


IDEAS / FEATURES
 + Implement rest-api for remote control (request submission, pause/resume, shutdown) (via Extension)
 + Dynamic Scheduling according to runtime statistics (like max. Spooler time)
 + Add event bus (pub/sub) to context such that extensions can communicate via events
 + Count computation time in Monitoring and publish as separate log entry
 + Add overall request timings to Monitoring
 + Extension that takes care of automatic shutdown when crawling finished.

TEST
 + Tools that operate on objects and URLs (<=important)
 + QueueManager and Scheduler (includes filtering)
 + Integration tests against local storage and copy of single wikipedia page
  
POLISH
 + Offline Storage
   + Bug? Still twice the number of requests compared to number of files on disk
   + Handle file exists/ not a directory error
 + Logging
   + Add new log levels at runtime. Use this for adding log.request with request.log in Completer
   + Ignore log levels in appenders that are not specified (log info <- minimal log level)
   + Expose some default log configurations 
   + Add serializers based on types 
 + In QUEUE stats show subcategories (like http/https) per status. Use Regex as general approach
 + Design interface for queue that is local/remote agnostic
  
  
     
