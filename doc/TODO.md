  + Implement rest-api for remote control (request submission, pause/resume, shutdown)
  + Reorder classes
  + Add more coffeedoc (Pipeline)
  + Add tests for
    + rate limiting
  + Logging: Add new log levels at runtime. Use this for adding log.request with request.log
  in Completer
  + Design interface for queue that is local/remote agnostic
  + Design nice request.toString() method
  + Add request to trace.log when removed from queue
  + Improve statistics to show subcategories (like http/https) per status. Use Regex as general approach
