CherryTree
==============

A toolstack for convenient development and execution of functional webscraping scripts. Scripts can be composed
using a publish-subscribe like pattern.
 
Functional webscrapers (cherry pickers) are implemented as simple functions which are leveraged to have access to 
the scraping environment such that it is easy to build site traversals with decoupled scraper components.

Run these commands for initial setup and test run

	$ npm install gulpjs/gulp-cli#4.0 codo -g
	$ npm install
	$ npm test


Tutorial
--------



TODO
====

  + Better load distribution: Run context.execute() at process.nextTick --> Affects test design
  + Options
  	Merge options in extension constructor. Expects super to be called --> verify
    + Resource Discovery
    + Queue System: lokijs options (storage file, max queue size)
    + Resource Discovery
    + Resource Discovery
    
    
    
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