DOCUMENTATION
 + List major classes in main.readme.md
 + Write introtext in main.readme.md
 + Replace RequestStatus.XXX because this generates a broken link
 + Rename status -> phase (REFACTORING)
 

IDEAS / FEATURES
 + Implement rest-api for remote control (request submission, pause/resume, shutdown)
 + Dynamic Scheduling according to runtime statistics (like max. Spooler time)
 + Add event bus (pub/sub) to context such that extensions can communicate via events
 + Count computation time in Monitoring and add in separate log entry
 + Add overall request timings to Monitoring

TASKS
 + Reorder classes
 + Add more coffeedoc (especially in Pipeline)
  
TEST
 + Rate limiting
 + Filtering
  
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
  
  
     
