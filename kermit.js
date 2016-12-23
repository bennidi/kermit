require('coffee-script/register');

var argv = require('yargs').argv;
// run node kermit.js --script=<relative-path-to-script>
require(argv.script);
