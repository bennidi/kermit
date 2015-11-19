# The master build file aggregates all separate build files

require './build.testing.coffee'
require './build.qa.coffee'
require './build.doc.coffee'

# Dependencies for main build

chalk = require 'chalk'
gulp = require 'gulp'

buildIntro = """

#################################################
      Welcome to the Gulp 4 build system
#################################################

Run: #{ chalk.magenta 'gulp --tasks'} for a list of available build tasks
"""

showHelp = ->
	console.log buildIntro
showHelp.description = 'Show help'

gulp.task 'default', showHelp



