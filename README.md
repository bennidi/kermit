<a href="http://www.wtfpl.net/"><img
       src="http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-4.png"
       width="80" height="15" alt="WTFPL" /></a>

# Kermit - the sloth

> Kermit is an extensible and feature rich web-scraper providing many useful extensions for
> automated data collection. It was built to lower the barrier of web-scraping complexity by providing
> clean abstractions and extension points. Kermit especially loves to free data
> from the claws of corporate ownership. If Kermit wasn't a sloth, he would be a pirate...yargh!

Kermit in a nutshell
========================

  * Written entirely in CoffeeScript. Designed for extensibility and ease of use while maintaining resource efficiency
  as much as possible (yes, it streams! and its async where possible). It takes care of request scheduling, rate limiting, handling of redirects etc.
  * Built around solid js libraries
    * [request](https://www.npmjs.com/package/request) and [socks5](https://www.npmjs.com/package/socks5-http-client)
    for calling the web - includes support for [Tor](https://www.torproject.org/) proxying
    * [lokijs](https://www.npmjs.com/package/lokijs) as an efficient backend for request queuing and statistics monitoring
    * [koa](https://www.npmjs.com/package/koa) as middleware for local [http-server](https://www.npmjs.com/package/koa-static)
     and REST based remote control (<- coming soon)
    * [html-to-json](https://www.npmjs.com/package/html-to-json) and [cheerio](https://www.npmjs.com/package/cheerio) for syntax friendly dom traversals
    * [mitm](https://www.npmjs.com/package/mitm) for transparent redirecting of requests
    * [must](https://www.npmjs.com/package/must) for testing done right - well, I admit that the code base currently lacks testing very much  :-/ (WIP)
  * Uses streaming API for handling of response data. Provides simple [Pipeline](http://open-medicine-initiative.github.io/kermit/main/class/Pipeline.html) abstraction to register
   [writable streams](https://nodejs.org/api/stream.html#stream_class_stream_writable) guarded by custom filters (content-type, length etc.)
  * Provides composable abstraction to simplify extension with custom features. See [Extension](http://open-medicine-initiative.github.io/kermit/main/class/Extension.html)
  * Comprehensive set of standard extensions for
    * Configurable **request filtering** (blacklist/whitelist) based on regular expressions on URLs or custom filters
    * Queueing system with configurable **rate limits** (regex on URLs)
    * Pluggable automated **resource discovery** (links, images, resources etc.)
    * Pluggable **monitoring** to provide traceability
    * **Lazy logging**: Log facilities only generate log messages if log level actually exists. This is soon to
    be released as a standalone library, because lazy log message generation is quite useful in general.
    * **Offline Mode**: Download URLs to local storage to subsequently collect data offline from your local repositories (no rate limits! :-P )
  * Thoroughly documented using [codo](https://github.com/coffeedoc/codo): Read the [api-docs](https://open-medicine-initiative.github.io/kermit) 


# Installation
    
Currently not available as npm library because it is still in beta. Use the github repository to install
and run your local copy. It is planned to release an npm version soon(ish) but I am still waiting for
user feedback (see section **Contribute**)
    
## Prerequisites
    
  * Running installation of Node.js and git
    > Recommendation: Use nvm and install 5.3 (not tested on versions below 5.0)
  * (optional) Installation of Tor  (if you want to collect data anonymously...and slowly, of course :)

## Setup
    
	$ npm install -g gulpjs/gulp-cli#4.0 -g
	$ git clone https://github.com/open-medicine-initiative/kermit.git
	$ cd kermit
	$ npm install
	$ npm test

# Usage

Read the [tutorial](./doc/main.intro.md) in folder [doc](./doc) . The tutorial is work in progress though
and you should always refer to the [examples](./src/examples). 

# Documentation

The code ships with a lot of documentation and it is highly recommended to have a look at
the sources as well as the generated [API docs](https://open-medicine-initiative.github.io/kermit).

# Contribute

Because Kermit is currently in beta testing the most important contribution is feedback
on functionality/bugs. Please provide log excerpts when submitting bug reports.
Another welcome contribution are more extensions. Create a gist of your extension
code and link it in the wiki page for [Extensions](https://github.com/open-medicine-initiative/kermit/wiki/Extensions)
Spread the word and invite more developers to use Kermit for freeing data.

# Background info
Kermit is not only an efficient web scraper, no, Kermit is also a sloth - and one remarkable sloth indeed! 
In fact, before Kermit it was not known that sloths actually do have a passion for working with data. 
They appear as desinterested and unexciting about any form of technology as one could possibly imagine. 
Only more careful studies have revealed that many of them have a second life as programmers, data analysts,
number crunchers or, as Kermit, data collectors.

Starting with this incredible discovery, more investigations have shown that there is a whole sub-culture
of technology enthusiasm among many other mammals, too. But only few of them do their data collection work as
carefully and patiently as Kermit. This is why you should seriously think about hiring Kermit for your
data collection jobs before contracting any of those human mammals that put expensive price
tags on their (mostly imaginary) CV's.

##License
For fun and personal enjoyment of rebellious acts the code is currently released under the [WTFPL](https://en.wikipedia.org/wiki/WTFPL)
(Do What The Fuck You Want To Public License). See the [License.md](License.md)