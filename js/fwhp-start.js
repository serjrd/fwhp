#!/usr/bin/env node

var config, configFile, e, err, fs, fwhp, out, path, spawn;

fs = require('fs');

path = require('path');

spawn = require('child_process').spawn;

try {
  configFile = process.argv[2];
  config = require(path.resolve(configFile));
} catch (_error) {
  e = _error;
  console.log("Error reading config file: [" + e + "]");
  process.exit(1);
}

out = fs.openSync(config.general.log, 'a');

err = fs.openSync(config.general.log, 'a');

fwhp = spawn('fwhp', [configFile], {
  detached: true,
  stdio: ['ignore', out, err]
});

if (!fwhp) {
  console.log("Failed to spawn fwhp :(");
  process.exit(1);
}

fwhp.unref();

console.log("fwhp started on " + config.general.ip + ":" + config.general.port);

process.exit(0);
