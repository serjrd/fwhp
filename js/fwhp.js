#!/usr/bin/env node

// Generated by CoffeeScript 1.8.0
var allowed_ips, argv, cmd, config, confign, e, entry, execFile, fs, html, https, options, password, path, qs, util;

https = require('https');

fs = require('fs');

path = require('path');

qs = require('querystring');

execFile = require('child_process').execFile;

util = require('util');

argv = require('yargs')["default"]({
  i: '0.0.0.0',
  p: 1000,
  t: 18000
}).alias({
  i: 'ip',
  p: 'port',
  s: 'secret',
  t: 'time',
  c: 'cmd'
}).describe({
  i: 'IP address to bind the HTTPS server to',
  p: 'TCP port to bind the HTTPS server to',
  t: "Fire a \'deny\' action X seconds after the 'allow'. 0 to disable.",
  s: 'The secret password that we expect to grant access',
  c: 'The external allow/deny script. See the ./cmd folder for examples.',
  config: 'The file with the list of passwords and appropriate local commands.'
}).string(['config', 's', 'c', 'i']).check(function(argv) {
  if (!(argv.config || (argv.s && argv.c))) {
    return false;
  }
}).argv;

confign = {};

if (argv.config) {
  try {
    config = require(path.resolve(argv.config));
  } catch (_error) {
    e = _error;
    console.log("Error reading config file: [" + e + "]");
    process.exit(1);
  }
} else {
  config[argv.secret] = {
    cmd: argv.cmd
  };
}

for (password in config) {
  entry = config[password];
  entry.cmd = path.resolve(entry.cmd);
  if (!fs.existsSync(entry.cmd)) {
    console.error("Error: unable to find '" + entry.cmd + "'. Exitting..");
    process.exit(1);
  }
}

try {
  options = {
    key: fs.readFileSync('./ssl/key.pem'),
    cert: fs.readFileSync('./ssl/cert.pem')
  };
} catch (_error) {
  console.error("\nOops..!\nCouldn't read the SSL key/cert files (./ssl/key.pem and ./ssl/cert.pem).\nHere's a way to generate a self-signed certificate:\n\n# openssl genrsa -out ./ssl/key.pem 2048\n# openssl req -new -x509 -key ./ssl/key.pem -out ./ssl/cert.pem -days 1095\n# chmod 400 ./ssl/*.pem\n");
  process.exit(1);
}

allowed_ips = {};

cmd = {
  allow: function(ip, config) {
    var time;
    if (argv.time || config.time) {
      time = config.time ? config.time : argv.time;
      if (allowed_ips[ip] != null) {
        clearTimeout(allowed_ips[ip]);
      }
      allowed_ips[ip] = setTimeout(this.deny, time * 60000, [ip, config]);
    }
    return execFile(config.cmd, ['allow', ip, config.arg], function(error, stdout, stderr) {
      if (error) {
        console.log("" + error);
      }
      if (stdout) {
        return console.log("" + stdout);
      }
    });
  },
  deny: function(ip, config) {
    if (allowed_ips[ip] != null) {
      clearTimeout(allowed_ips[ip]);
      delete allowed_ips[ip];
    }
    return execFile(config.cmd, ['deny', ip, config.arg], function(error, stdout, stderr) {
      if (error) {
        return console.log("" + error);
      }
    });
  }
};

html = {
  render: function(ip, result) {
    var body;
    if (result == null) {
      body = "<div class='ip'>Your current IP is <span id='ip'>" + ip + "</span></div>\n<form method='post'>\n	Password: <input type='password' name='password'>\n	<input type='submit' value='Submit'>\n</form> ";
    } else if (result) {
      if (argv.time) {
        body = "<div class='success'>Success! IP [<span id='ip'>" + ip + "</span>] is allowed for " + argv.time + " minutes.</div>";
      } else {
        body = "<div class='success'>Success! IP [<span id='ip'>" + ip + "</span>] is allowed.</div>";
      }
    } else if (!result) {
      body = "<div class='error'>Error! Access denied.</div>";
    }
    return "<html>\n	<head>\n		<title>fw hole poker</title>\n		<style type='text/css'>\n			body { position: relative; }\n			body .content {\n				position: absolute;	margin: auto;\n				top: 0; left: 0; bottom: 0; right: 0;\n				width: 30%; height: 20%;\n				text-align: center;\n			}\n			div.ip { margin: 2% 0; }\n			div.success { color: green; }\n			div.error { color: red; }\n			span#ip { font-weight: bold; }\n		</style>\n	</head>\n	<body>\n		<div class='content'>\n			" + body + "\n		</div>\n		<script>window.onload = function(){ document.getElementsByName('password')[0].focus() }</script>\n	</body>\n</html>";
  }
};

https.createServer(options, function(req, res) {
  var ip, requestBody;
  ip = req.connection.remoteAddress;
  if (req.method === 'GET') {
    res.writeHead(200);
    return res.end(html.render(ip));
  } else if (req.method === 'POST') {
    requestBody = '';
    req.on('data', function(data) {
      requestBody += data;
      if (requestBody.length > 1e5) {
        res.writeHead(413, "Request Entity Too Large", {
          'Content-Type': 'text/html'
        });
        return res.end('<!doctype html><html><head><title>413</title></head><body>413: Request Entity Too Large</body></html>');
      }
    });
    return req.on('end', function() {
      var date, result;
      date = new Date();
      date = "" + (date.toDateString()) + " " + (date.toTimeString().substr(0, 8));
      password = qs.parse(requestBody).password;
      if (password in config) {
        result = true;
        console.log("" + date + ": ALLOW " + ip + " - Access granted for " + argv.time + " seconds");
        cmd.allow(ip, config[password]);
      } else {
        result = false;
        console.log("" + date + ": REJECT " + ip + " - Wrong password");
      }
      return res.end(html.render(ip, result));
    });
  }
}).listen(argv.port, argv.ip);

console.log("FWHP starter. Listening on " + argv.ip + ":" + argv.port + "...");