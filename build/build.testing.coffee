# https://github.com/pgte/nock#readme
gulp = require 'gulp'
mocha = require 'gulp-mocha'
util = require 'gulp-util'

# Expose assertion libs globally such that tests do not need to require()
global.expect = require('must')

# This task will run all tests (*.spec.(coffee|es6))
runAllSpecs = ->
  gulp.src ['./src/**/*.spec.coffee' ]
    .pipe mocha reporter:'spec'
    .on 'error', util.log
runAllSpecs.description = "Run all tests"
gulp.task 'test:all', runAllSpecs

# This task will run all tests (*.spec.(coffee|es6))
runIntegrationSpecs = ->
  gulp.src ['./src/**/*.int.spec.coffee']
  .pipe mocha reporter:'spec'
  .on 'error', util.log
runIntegrationSpecs.description = "Run integration tests only"
gulp.task 'test:integration', runIntegrationSpecs


# This task will run all tests (*.spec.(coffee|es6))
runUnitSpecs = ->
  gulp.src ['./src/**/*.spec.coffee','./src/**/*int.spec.coffee' ]
  .pipe mocha reporter:'spec'
  .on 'error', util.log
runUnitSpecs.description = "Run unit tests only"
gulp.task 'test:unit', runUnitSpecs


# This task will execute tests and watch src folder for changes
watchTests = ->
    gulp.watch ['./src/**/*'], gulp.series 'test:all'
gulp.task 'test:watch', watchTests
    
gulp.task 'test:auto', gulp.series 'test:all', 'test:watch'
