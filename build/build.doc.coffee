gulp = require 'gulp'
apidoc = require 'gulp-apidoc'
run = require 'gulp-run'
codo = require 'gulp-codo'


# Generation of REST-API documentation
genapidoc = ->
	apidoc.exec
		raw: "./src/rest/"
		dest: "./target/api-doc"
		includeFilters: [ ".*\\.js$" ]
genapidoc.description = "Generate API documentation for REST resources"

# Generation of ESDoc
# Note: Currently ESDoc does not support ES7 features which are used by the project
genesdoc = ->
	run('./node_modules/.bin/esdoc -c ./esdoc.json').exec()
genesdoc.description = 'Generate esdoc-based documentation'


gencodo = () ->
	gulp.src ['./src/**/!(*.spec).coffee'], read: false
		.pipe codo
			dir: 'target/coffeedoc'
			name: 'Kermit the Sloth'
			title: 'Kermit the Sloth'
			readme: 'README.md'
			extra: ['LICENSE.md', './doc/DOCROOT.md']
gencodo.description = 'Generate coffee documentation'

# Register tasks with gulp
gulp.task 'doc:api', genapidoc
gulp.task 'doc:esdoc', genesdoc
gulp.task 'doc:coffee', gencodo
