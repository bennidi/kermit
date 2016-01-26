<a href="http://www.wtfpl.net/"><img
       src="http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-4.png"
       width="80" height="15" alt="WTFPL" /></a>

> Kermit is an extensible and feature rich web-scraper that comes with many useful extensions for
> scraping data from the web

Meet Kermit ...the sloth
========================

Kermit in a Nutshell:

  * Written entirely in CoffeeScript. Designed for extensibility and ease of use while mainting resource efficiency
  as good as possible
  * Built around solid js libraries (request, lokijs, through2, lodash, koa, fs-extra, urijs, cheerio, mitm, must)
  * Handles response data using streams. Provides simple Pipeline abstraction to register ReadStreams for specific response types
  * Supports Tor proxying with latest socks5 library.
  * Provides extensible component model abstraction to easily build and plugin extensions with custom features
  * Comprehensive set of standard extensions for
    * Configurable request filtering (blacklist/whitelist) based on regular expressions for URLs or custom filters
    * Queueing system with configurable rate limits (regex on URLs)
    * Automated resource discovery (links, images, resources using cheerio)
    * Runtime statistics provide good traceability
    * Lazy logging: Log facilities only generate log messages if log level actually exists. 
    * OfflineScraping: Download parts of the web to local storage to subsequently scrape data from your local repositories 
  * Thoroughly documented using codo: Read the [api-docs](https://open-medicine-initiative.github.io/kermit) 


## Installation
    
Currently not available as npm library because it is still in alpha state. Use the github repository code to install
and run your local copy.
    
### Prerequisites
    
  * Installation of Node.js. Recommendation: Use nvm and install 5.3
  * (optional) Installation of Tor  

### Setup
    
	$ npm install -g gulpjs/gulp-cli#4.0 -g
	$ npm install
	$ npm test

## Documentation



##License

See the [License.md](License.md)
    
    
    
Resources
=========

  + http://ricardo.cc/2011/06/02/10-CoffeeScript-One-Liners-to-Impress-Your-Friends.html
  + https://github.com/evanw/node-source-map-support
  + http://www.pbm.com/~lindahl/real.programmers.html
  + https://github.com/raganwald-deprecated/homoiconic/blob/master/2012/08/method-decorators-and-combinators-in-coffeescript.md
  + http://arcturo.github.io/library/coffeescript/03_classes.html
  + https://coffeescript-cookbook.github.io/chapters/strings/generating-a-unique-id
  + https://github.com/fsbahman/apidoc-swagger/blob/master/lib/apidocToSwagger.js
  + https://www.npmjs.com/package/swagger-to-raml-object
  + https://www.npmjs.com/package/raml-mocker
  + https://www.npmjs.com/package/apidoc-swagger
  + https://www.npmjs.com/package/hapi-swagger
  + http://jrhicks.github.io/replicate_architecture_ideas_for_react_flux_apps/index.html
  + http://www.html5rocks.com/en/tutorials/speed/static-mem-pools/?redirect_from_locale=de
  + https://strongloop.com/strongblog/robust-node-applications-error-handling/
  + http://www.coffeescriptlove.com/2014/05/react-and-coffeescript-with-or-without.html
  + http://www.html5rocks.com/en/tutorials/speed/static-mem-pools/?redirect_from_locale=de
  + https://github.com/pjeby/yieldable-streams
  + http://mattsnider.com/object-pool-pattern-in-javascript/