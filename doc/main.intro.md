# Design overview

The core of kermit is built around the representation of a request to a given URL - [RequestItem](../../class/RequestItem.html) - 
and the implementation of a series of well-defined **processing phases** applied to each of those items. Items "transition" from one 
phase to the other, usually from phase [INITIAL](../../class/INITIAL.html) to phase [COMPLETE](../../class/COMPLETE.html).

## Processing Phases

Each processing phase contains a set of handlers that do some work on the request item they receive.
These handlers are provided by [Extension](../../class/Extension.html)s and are inserted during initialization 
of the [Crawler](../../class/Crawler.html). 
The execution of a processing phase for a given item involves the invocation of all handlers (in order of insertion).

All items are held in a [queueing backend](../../class/QueueManager.html) and the node.js event loop is used to to schedule processing callbacks for 
the items that are at the head of the queue.

All defined processing phases as well as their allowed transitions are illustrated in the diagram below.

```txt
 .-------------.
 |   INITIAL   |
 |-------------|
 | Unprocessed |
 |             |
 '-------------'   \
        |           \
        |            \
        |             v
        v             .--------------------.
 .-------------.      |  ERROR | CANCELED  |      .-----------.
 |  SPOOLED    |      |--------------------|      | COMPLETED |
 |-------------|  --->| - Error            |      |-----------|
 | Waiting for |      | - Duplicate        |      | Done!     |
 | free slot   |      | - Blacklisted etc. |      |           |
 '-------------'      '--------------------'      '-----------'
        |             ^         ^          ^            ^
        |            /          |           \           |
        |           /           |            \          |
        v          /                          \         |
 .-------------.         .-------------.          .-----------.
 |    READY    |         |  FETCHING   |          |  FETCHED  |
 |-------------|         |-------------|          |-----------|
 | Ready for   |-------->| Response    |--------->| Content   |
 | fetching    |         | streaming   |          | received  |
 '-------------'         '-------------'          '-----------'


```

## Processing Extensions
[Extension](../../class/Extension.html)s are reusable components designed to accomplish specific tasks like storing content on local file system or scanning content for certain words. Extensions can attach handlers to any of the processing phases. Most of Kermit's core functionality is implemented based on this extension mechanism. Core extensions provide functionality for request filtering, rate limiting and throttling. 
List of core extensions:

* [RequestFilter](../../class/ExtensionPointConnector.html)
* [ExtensionPointConnector](../../class/ExtensionPointConnector.html)
* [RequestItemMapper](../../class/RequestItemMapper.html)
* [QueueConnector](../../class/QueueConnector.html)
* [QueueWorker](../../class/QueueWorker.html)
* [RequestStreamer](../../class/Spooler.html)
* [Spooler](../../class/Spooler.html)
* [Completer](../../class/Completer.html)
* [Cleanup](../../class/Cleanup.html)


## Tutorial
The following sections are meant to walk you through the most fundamental parts of the API from a user's
perspective.

### Instantiation

Instantiation of a Crawler is very simple as Kermit comes with a lot of default options.
An absolute minimal example looks like this:

```cs
# Require the main class from the modules package
{Crawler} = require '../kermit/kermit.modules'

# Initialize a crawler with default options and no particularly interesting functionality
Kermit = new Crawler
  name: "name your crawler here" 
# Issue a request and then detect that there is not much to do with the result (no writable streams attached)
# so the program will do nothing but be kept alive forever (no auto-shutdown configured)
Kermit.schedule("http://www.yourtargeturl.info")
    
```

A more elaborate and useful example could look like this:

```cs

# Require the main class and extensions
{Crawler, ext} = require '../kermit/kermit.modules'
{ResourceDiscovery, Monitoring, OfflineStorage} = ext

# Configure a crawler with some useful extensions
Kermit = new Crawler
  name: "downloader"
  extensions : [
    new OfflineStorage # Download URL content to local file system
    new Monitoring # Add regular computation of runtime statistics to log level INFO
    new ResourceDiscovery # Add discovery of href and other resources (automatically added to the URL backlog)
  ]
# Start the crawling process.
# The resource discovery extension will scan all html files for links and schedule new requests for each unique URL.
# NOTE: This program might never stop crawling so maybe you want to add some boundaries
Kermit.schedule("http://www.yourtargeturl.info")
    
```

An example that is likely to finish crawling after all allowed URLs have been visited looks like this:

```cs

# Require the main class and extensions
{Crawler, ext} = require '../kermit/kermit.modules.coffee'
{ResourceDiscovery, Monitoring, OfflineStorage} = ext

# Configure a crawler with some useful extensions
Kermit = new Crawler
  name: "download-apidocs"
  extensions : [
    new OfflineStorage # Add storage to local file system
    new Monitoring # Add regular computation of runtime statistics to log level INFO
    new ResourceDiscovery # Add discovery of href and other resources
  ]
  Options:
    Filtering:
        allow : [
          /.*apidocs\.info.*/
        ]
        
# This will initiate the crawling process
# All discovered URLs outside of the domain 'apidocs.info' will be discarded
# As long as URLs under apidocs.info do not contain autogenerated ids, crawling will
# eventually finish 
Kermit.schedule("http://www.apidocs.info")
    
```

### Options
Most of the features provided by Kermit are implemented as extensions. Each of those extensions
offers some options to configure its behaviour. To pass options down to the core extensions use the
'options' in the crawler's constructor.


```cs

Kermit = new Crawler
  name: "download-apidocs"
  Options : 
    Filtering: ... # Options for request filtering go here
    Logging: ... # You can pass a log configuration of your choice
    Queuing: ... # Add rate limits and other features as provided by the queuing system
  
```

### Log configuration
The [LogHub](../../class/LogHub.html) is initialized with a log configuration that tells it what appenders
and log formats to use.

```cs

Kermit = new Crawler
  name: "download-apidocs"
  Options : 
    Logging:
      levels : ['trace', 'info', 'error', 'warn']
      destinations: [
        {
          appender:
            type : 'console'
          levels : ['trace', 'error', 'info', 'warn']
        },
        {
        appender :
              type : 'file'
              filename : "/tmp/crawler/logs/full.log"
            levels: ['trace', 'error', 'info', 'debug', 'warn']
        }    
      ]
  
```

There are a number of [predefined log configurations](../../file/src/kermit/Logging.conf.coffee.html) that can be used. It is also easily possible to roll up a custom configuration following the code examples from that file.

### Scheduling of URLs
To reduce the memory footprint, not every URL submission will create a request item immediately (as request items are
persistent, ie. increase queue size and affect query performance). Therefore, a [Scheduler](../../class/Scheduler.html) is used to keep track of submitted URLs and schedule a request when the load limits allow.

## Feature extensions

* [ResourceDiscovery](../../class/ResourceDiscovery.html)
* [Monitoring](../../class/Monitoring.html)
* [OfflineStorage](../../class/OfflineStorage.html)
* [OfflineServer](../../class/OfflineServer.html)


## Custom Extensions
This will become a guide for implementing your own extensions. Until then, please have a look
at the code of the various available extensions. It's fairly easy to get started.