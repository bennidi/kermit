require('coffee-script/register');
require('coffeescript-mixins').bootstrap()

var argv = require('yargs').argv;
// run node kermit.js --script=<relative-path-to-script>
require(argv.script);


