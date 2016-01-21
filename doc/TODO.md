  + Implement rest-api for remote control (request submission, pause/resume, shutdown)
  + Reorder classes
  + Add more coffeedoc (Pipeline)
  + Offline Storage
    + Handle query params
    + Implement detection of existing files (what to do if file exists)
  + Add tests for
    + rate limiting
    + QueueManager
  + Logging
    + Add new log levels at runtime. Use this for adding log.request with request.log in Completer
    + Ignore log levels in appenders that are not specified (log info <- minimal log level)
    + Expose some default log configurations
  + Design interface for queue that is local/remote agnostic
  + Improve statistics 
    + In QUEUE stats show subcategories (like http/https) per status. Use Regex as general approach
    + Per request: min/max/avg duration per phase
     
