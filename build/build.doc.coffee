gulp = require 'gulp'
apidoc = require 'gulp-apidoc'
run = require 'gulp-run'


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


# Register tasks with gulp
gulp.task 'doc:api', genapidoc
gulp.task 'doc:esdoc', genesdoc
