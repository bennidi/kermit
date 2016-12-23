// Register a coffeescript preprocessor
require('coffee-script/register');
// Run the main build file
require('./build/build.coffee');

console.log(JSON.stringify(require('caramel')));

// http://fettblog.eu/gulp-4-parallel-and-series/