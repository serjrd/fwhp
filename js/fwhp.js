#!/usr/bin/env node

var allowed_ips, argv, cmd, config, confign, e, entry, execFile, fs, html, https, options, param, password, path, qs, util, _i, _len, _ref, _ref1;

https = require('https');

fs = require('fs');

path = require('path');

qs = require('querystring');

execFile = require('child_process').execFile;

util = require('util');

argv = require('yargs')["default"]({
  i: '0.0.0.0',
  p: 1000,
  t: 18000,
  ssl: '/etc/fwhp/ssl'
}).alias({
  i: 'ip',
  p: 'port',
  s: 'secret',
  t: 'time',
  c: 'cmd'
}).describe({
  config: 'The main config file.',
  ssl: 'Path to SSL key/cert folder',
  i: 'IP address to bind the HTTPS server to',
  p: 'TCP port to bind the HTTPS server to',
  t: "Fire a \'deny\' action X seconds after the 'allow'. 0 to disable.",
  s: 'The secret password that we expect to grant access',
  c: 'The external allow/deny script. See the ./cmd folder for examples.'
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
  config.general = {};
  _ref = ['ip', 'port', 'time', 'ssl'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    param = _ref[_i];
    config.general[param] = argv[param];
  }
  config['passwords'] = {};
  config['passwords'][argv.secret] = {
    cmd: argv.cmd
  };
}

_ref1 = config.passwords;
for (password in _ref1) {
  entry = _ref1[password];
  try {
    entry.cmd = path.resolve(entry.cmd);
  } catch (_error) {
    e = _error;
    console.error("Error: unable to find '" + entry.cmd + "'. Exitting..");
    process.exit(1);
  }
  if (!fs.existsSync(entry.cmd)) {
    console.error("Error: unable to find '" + entry.cmd + "'. Exitting..");
    process.exit(1);
  }
}

try {
  options = {
    key: fs.readFileSync("" + config.general.ssl + "/key.pem"),
    cert: fs.readFileSync("" + config.general.ssl + "/cert.pem")
  };
} catch (_error) {
  console.error("\nOops..!\nCouldn't read the SSL key/cert files (" + config.general.ssl + "/key.pem and " + config.general.ssl + "/cert.pem).\nHere's a way to generate a self-signed certificate:\n\n# openssl genrsa -out " + config.general.ssl + "/key.pem 2048\n# openssl req -new -x509 -key " + config.general.ssl + "/key.pem -out " + config.general.ssl + "/cert.pem -days 1095\n# chmod 400 " + config.general.ssl + "/*.pem\n");
  process.exit(1);
}

allowed_ips = {};

cmd = {
  allow: function(ip, params) {
    var time;
    time = params.time != null ? params.time : config.general.time;
    if (time) {
      if (allowed_ips[ip] != null) {
        clearTimeout(allowed_ips[ip]);
      }
      allowed_ips[ip] = setTimeout(this.deny, time * 60000, [ip, params]);
    }
    return execFile(params.cmd, ['allow', ip, params.arg], function(error, stdout, stderr) {
      if (error) {
        console.log("" + error);
      }
      if (stdout) {
        return console.log("" + stdout);
      }
    });
  },
  deny: function(ip, params) {
    if (allowed_ips[ip] != null) {
      clearTimeout(allowed_ips[ip]);
      delete allowed_ips[ip];
    }
    return execFile(params.cmd, ['deny', ip, params.arg], function(error, stdout, stderr) {
      if (error) {
        return console.log("" + error);
      }
    });
  }
};

html = {
  render: function(ip, result, time) {
    var body;
    if (result == null) {
      body = "<div class='ip'>Your current IP is <span id='ip'>" + ip + "</span></div>\n<form method='post'>\n	Password: <input type='password' name='password'>\n	<input type='submit' value='Submit'>\n</form> ";
    } else if (result) {
      if (time) {
        body = "<div class='success'>Success! IP [<span id='ip'>" + ip + "</span>] is allowed for " + time + " minutes.</div>";
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
      var date, params, result, time;
      date = new Date();
      date = "" + (date.toDateString()) + " " + (date.toTimeString().substr(0, 8));
      password = qs.parse(requestBody).password;
      time = null;
      if (password in config.passwords) {
        result = true;
        params = config['passwords'][password];
        time = params['time'] != null ? params['time'] : config.general.time;
        console.log("" + date + ": ALLOW " + ip + " - Access granted for " + time + " seconds");
        cmd.allow(ip, params);
      } else {
        result = false;
        console.log("" + date + ": REJECT " + ip + " - Wrong password");
      }
      return res.end(html.render(ip, result));
    });
  }
}).listen(config.general.port, config.general.ip);

console.log("FWHP starter. Listening on " + config.general.ip + ":" + config.general.port + "...");
