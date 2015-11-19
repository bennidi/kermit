# https://github.com/pgte/nock#readme


gulp = require 'gulp'
mocha = require 'gulp-mocha'
util = require 'gulp-util'
# http://blog.reactandbethankful.com/posts/2015/05/01/building-with-gulp-4-part-4-incremental-builds/
cache = require 'gulp-memory-cache'

# Expose assertion libs globally such that tests do not need to require()
global.expect = require('chai').expect
global.assert = require('chai').assert

# This task will run all tests (*.spec.(coffee|es6))
runSpecs = ->
  gulp.src ['./src/**/*.spec.coffee','./src/**/*.spec.es7' ], since: cache.lastMtime('code')
    .pipe cache 'code'
    .pipe mocha reporter:'spec'
    .on('error', util.log)   
runSpecs.description = "Run tests"
gulp.task 'test:run', runSpecs 

# This task will execute tests and watch src folder for changes
watchTests = ->
    gulp.watch ['./src/**/*'], gulp.series 'test:run'
    .on('change', cache.update('code'));
gulp.task 'test:watch', watchTests
    
gulp.task 'test:auto', gulp.series 'test:run', 'test:watch' 