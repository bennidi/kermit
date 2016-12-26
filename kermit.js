require('coffee-script/register');
require('./polyfill.coffee');


var argv = require('yargs').argv;
// run node kermit.js --script=<relative-path-to-script>
require(argv.script);
