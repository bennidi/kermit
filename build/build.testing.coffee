# https://github.com/pgte/nock#readme
gulp = require 'gulp'
mocha = require 'gulp-mocha'
util = require 'gulp-util'
istanbul = require 'gulp-coffee-istanbul'
coffee = require('gulp-coffee')

# Expose assertion libs globally such that tests do not need to require()
global.expect = require('must')

specFiles = ['src/**/*.spec.coffee']
coffeeFiles = ['src/**/*.coffee', '!src/**/*.spec.coffee']

# This task will run all tests (*.spec.(coffee|es6))
runSpecs = ->
  gulp.src coffeeFiles
  .pipe(coffee({bare: true}))
  .pipe istanbul({includeUntested: true}) # Covering files
  .pipe istanbul.hookRequire()
  .on 'finish', ->
    gulp.src specFiles
    .pipe mocha reporter:'spec'
    .pipe istanbul.writeReports
      dir: './target/site/coverage',
      reporters: [ 'lcov', 'json', 'html'],
      reportOpts: { dir: './target/site/coverage' },
    .on 'error', util.log
runSpecs.description = "Run tests"
gulp.task 'test:run', runSpecs 

# This task will execute tests and watch src folder for changes
watchTests = ->
    gulp.watch ['./src/**/*'], gulp.series 'test:run'
    .on 'change', cache.update 'code'
gulp.task 'test:watch', watchTests
    
gulp.task 'test:auto', gulp.series 'test:run', 'test:watch' 
