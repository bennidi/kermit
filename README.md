<a href="http://www.wtfpl.net/"><img
       src="http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl-badge-4.png"
       width="80" height="15" alt="WTFPL" /></a>

> Kermit is an extensible and feature rich web-scraper that comes with many useful extensions for
> scraping data from the web

Meet Kermit ...the sloth
========================

Kermit in a Nutshell:

  * Written entirely in CoffeeScript. Designed for extensibility and ease of use.
  * Built around solid js libraries (request, lokijs, through2, lodash, koa, fs-extra, urijs, cheerio)
  * Handles request data using streams
  * Extensible component model for extension with custom features
  * Comprehensive set of composable extensions
    * Configurable request filtering (regex blacklist, regex whitelist, custom filters)
    * Persistent queueing system with configurable rate limits per domain (regex)
    * Automated resource discovery (links, images, resources etc.)
    * Html extraction support
  * Thoroughly documented using codo: Read the [api-docs](https://open-medicine-initiative.github.io/kermit) 


## Installation
    
### Prerequisites
    
  * Installation of Node.js. Recommendation: Use nvm and install 5.0
  * (optional) Installation of Tor  

### Setup
    
	$ npm install -g open-medicine-initiative/codo gulpjs/gulp-cli#4.0
	$ npm install
	$ npm test

## Documentation



##License

See the [License.md](License.md)


TODO
====
  + Create
  + Handle Request timeouts and 404
    
    
    
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
  http://jrhicks.github.io/replicate_architecture_ideas_for_react_flux_apps/index.html