// Register a coffeescript preprocessor
require('coffee-script/register');
require('babel-core/register');
// Run the main build file
require('./build/build.coffee');

// http://fettblog.eu/gulp-4-parallel-and-series/