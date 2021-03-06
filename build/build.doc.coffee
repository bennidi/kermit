gulp = require 'gulp'
codo = require 'gulp-codo'
ghPages = require 'gulp-gh-pages'
clean = require 'gulp-clean'

gulp.task  'doc:clean', ->
	gulp.src [ 'target/coffeedoc' ], read : false
		.pipe  clean force : true

gencodo = () ->
	gulp.src ['src/**/*.coffee', '!src/**/*.spec*.coffee'], read: false
		.pipe codo
			dir: 'target/coffeedoc/main'
			name: 'Kermit(main)'
			title: 'Kermit(main)'
			readme: 'doc/main.intro.md'
			verbose : true
			extra: ['LICENSE.md']
gencodo.description = 'Generate main coffee documentation'

gencodo_test = () ->
	gulp.src ['./src/**/*spec*.coffee'], read: false
	.pipe codo
		dir: 'target/coffeedoc/test'
		name: 'Kermit(test)'
		title: 'Kermit(test)'
		readme: 'doc/test.intro.md'
		extra: ['LICENSE.md']
gencodo_test.description = 'Generate documentation of test classes'

docsToGhPages = () ->
	gulp.src './target/site/**/*'
		.pipe ghPages()
docsToGhPages.description = "Publishes the coffeedoc documentation to "

# Register tasks with gulp
gulp.task 'doc:coffee', gencodo
gulp.task 'doc:coffee:test', gencodo_test
gulp.task 'doc:deploy', docsToGhPages
gulp.task  'doc:assemble', gulp.series 'doc:clean', gulp.parallel( "doc:coffee",'doc:coffee:test'), ->
	input = ["./target/coffeedoc/**/*", './doc/index.html']
	gulp.src input
	.pipe gulp.dest './target/site'
gulp.task 'doc:all', gulp.series 'doc:assemble', 'doc:deploy'
