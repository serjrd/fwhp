#!/usr/bin/env node

// A sample .js script to allow/deny IP with iptables+ipset

// argv[2] - action ('allow'/'deny')
// argv[3] - IP
// argv[4] - optional parameter described in the config file

var action, exec, ip, set, _ref;

exec = require('child_process').exec;

_ref = process.argv.slice(2), action = _ref[0], ip = _ref[1], set = _ref[2];

exec("echo `date +'%F %T:'` '" + action + " " + ip + " " + set + "' >> /var/log/fwhp.log");

switch (action) {
  case 'allow':
    exec("ipset add " + set + " " + ip);
    break;
  case 'deny':
    exec("ipset del " + set + " " + ip);
    break;
  default:
    console.log("Wrong action provided");
}
