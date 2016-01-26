gulp = require 'gulp'
codo = require 'gulp-codo'
ghPages = require 'gulp-gh-pages'
clean = require 'gulp-clean'

gulp.task  'doc:clean', ->
	gulp.src [ 'target/coffeedoc', 'target/site' ], read : false
		.pipe  clean force : true

gencodo = () ->
	gulp.src ['src/**/*.coffee', '!src/**/*.spec*.coffee'], read: false
		.pipe codo
			dir: 'target/coffeedoc/main'
			name: 'Kermit the Sloth (main)'
			title: 'Kermit the Sloth (main)'
			readme: 'doc/codo.main.readme.md'
			verbose : true
			extra: ['LICENSE.md']
gencodo.description = 'Generate main coffee documentation'

gencodo_test = () ->
	gulp.src ['./src/**/*spec*.coffee'], read: false
	.pipe codo
		dir: 'target/coffeedoc/test'
		name: 'Kermit the Sloth (test)'
		title: 'Kermit the Sloth (test)'
		readme: 'doc/codo.test.readme.md'
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
