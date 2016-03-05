require('coffee-script/register');
require('coffeescript-mixins').bootstrap()

var argv = require('yargs').argv;

require(argv.script);


