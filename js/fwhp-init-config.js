#!/usr/bin/env node

var conf_path, exec, fs, inquirer, path, questions, spawn;

inquirer = require('inquirer');

path = require('path');

fs = require('fs');

exec = require('child_process').exec;

spawn = require('child_process').spawn;

questions = [
  {
    type: 'input',
    name: 'path',
    message: 'Config folder',
    "default": '/etc/fwhp'
  }, {
    type: 'confirm',
    name: 'ssl',
    message: 'Generate self-signed SSl certificate',
    "default": true
  }
];

conf_path = path.resolve(process.argv[1], '..', fs.readlinkSync(process.argv[1]), '../../config');

inquirer.prompt(questions, function(res) {
  console.log("Installing config to " + res.path + "...");
  return exec("mkdir -p " + res.path + "; cp -r " + conf_path + "/* " + res.path + " && chmod 600 " + res.path + "/config.js", function(err) {
    if (err) {
      console.log("" + err);
      return process.exit(1);
    } else {
      if (res.ssl) {
        console.log("Generating SSL key and certificate\n");
        return exec("openssl genrsa -out " + res.path + "/ssl/key.pem 2048", function(err) {
          var cert;
          if (err) {
            console.log("" + err);
            return process.exit(1);
          } else {
            cert = spawn("openssl", ['req', '-new', '-x509', '-key', res.path + "/ssl/key.pem", '-out', res.path + "/ssl/cert.pem", '-days', '1095'], {
              stdio: 'inherit'
            });
            return cert.on('close', function(code) {
              if (code === 0) {
                return exec("chmod -R 600 " + res.path + "/ssl/*.pem", function() {
                  return console.log("DONE!\nYou may now run:\n\nfwhp-start " + res.path + "/config.js\n");
                });
              } else {
                console.log("Generating canceled. Exiting.");
                return process.exit(1);
              }
            });
          }
        });
      }
    }
  });
});
