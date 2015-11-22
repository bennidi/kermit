gulp = require 'gulp'
jscs = require 'gulp-jscs' 
 
gulp.task 'qa:jscs:report', ->
    gulp.raw ['src/**/*.es6', 'src/**/*.js']
        .pipe jscs()
        .pipe jscs.reporter()

gulp.task 'qa:jscs:fix', ->
    gulp.raw ['src/**/*.es6', 'src/**/*.js']
        .pipe jscs( fix:true)
        .pipe jscs.reporter()
        .pipe gulp.dest 'tmp/jscs/fixes'