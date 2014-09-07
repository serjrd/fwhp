#!/usr/bin/env coffee

https = require 'https'
fs = require 'fs'
path = require 'path'
qs = require 'querystring'
execFile = require('child_process').execFile
util = require 'util'
argv = require 'yargs'
		.default {i: '0.0.0.0', p: 1000, t: 18000, ssl: '/etc/fwhp/ssl'}
		.alias {i: 'ip', p: 'port', s: 'secret', t: 'time', c: 'cmd'}
		.describe 
			config: 'The main config file.'
			ssl: 'Path to SSL key/cert folder'
			i: 'IP address to bind the HTTPS server to'
			p: 'TCP port to bind the HTTPS server to'
			t: "Fire a \'deny\' action X seconds after the 'allow'. 0 to disable."
			s: 'The secret password that we expect to grant access'
			c: 'The external allow/deny script. See the ./cmd folder for examples.'
		.string ['config', 's', 'c', 'i']
		.check (argv) ->
			# Check that we have the arguments we need
			if !(argv.config or (argv.s and argv.c))
				return false
		.argv

confign = {}

# Check if we need to parse an external config file:
if argv.config 
	# Ok, the config file parameter was provided. Try reading it:
	try
		config = require path.resolve argv.config
	catch e
		console.log "Error reading config file: [#{e}]"
		process.exit 1
else
	# The parameters were passed as command-line arguments
	# Make a config object of them
	config.general = {}
	for param in ['ip', 'port', 'time', 'ssl']
		config.general[param] = argv[param]

	config['passwords'] = {}
	config['passwords'][argv.secret] = cmd: argv.cmd

# Now let's check that we're happy with the config parameters that we were given:
for password, entry of config.passwords
	# Ensure that the command path is absolute
	try
		entry.cmd = path.resolve entry.cmd
	catch e
		console.error "Error: unable to find '#{entry.cmd}'. Exitting.."
		process.exit 1

	# Check if the external script is accessible:
	if !fs.existsSync entry.cmd
		console.error "Error: unable to find '#{entry.cmd}'. Exitting.."
		process.exit 1


# Read the SSL key/cert files:
try
	options =
		key: fs.readFileSync("#{config.general.ssl}/key.pem")
		cert: fs.readFileSync("#{config.general.ssl}/cert.pem")
catch
	console.error """

		Oops..!
		Couldn't read the SSL key/cert files (#{config.general.ssl}/key.pem and #{config.general.ssl}/cert.pem).
		Here's a way to generate a self-signed certificate:

		# openssl genrsa -out #{config.general.ssl}/key.pem 2048
		# openssl req -new -x509 -key #{config.general.ssl}/key.pem -out #{config.general.ssl}/cert.pem -days 1095
		# chmod 400 #{config.general.ssl}/*.pem

		"""
	process.exit 1


allowed_ips = {}

# The methods that call the external script
# They fire an external command with the following arguments:
# 	'allow'/'deny'	- the action that should be performed
#	IP				- the IP address that should be allowed/denied
cmd =
	# This method is called upon successful authentication
	allow: (ip, params) ->
		time = if params.time? then params.time else config.general.time
		if time
			clearTimeout allowed_ips[ip] if allowed_ips[ip]?
			allowed_ips[ip] = setTimeout @deny, time * 60000, [ip, params]
		execFile params.cmd, ['allow', ip, params.arg], (error, stdout, stderr) ->
				console.log "#{error}" if error
				console.log "#{stdout}" if stdout

	deny: (ip, params) ->
		if allowed_ips[ip]?
			clearTimeout allowed_ips[ip]
			delete allowed_ips[ip]
		execFile params.cmd, ['deny', ip, params.arg], (error, stdout, stderr) ->
				console.log "#{error}" if error


# The function to generate some HTML for our web server
html =
	render: (ip, result, time) ->
		if !result?
			# No password provided. Show initial password form
			body = """
							<div class='ip'>Your current IP is <span id='ip'>#{ip}</span></div>
							<form method='post'>
								Password: <input type='password' name='password'>
								<input type='submit' value='Submit'>
							</form> 
					"""
		else if result
			# Success
			if time
				body = """
								<div class='success'>Success! IP [<span id='ip'>#{ip}</span>] is allowed for #{time} minutes.</div>
						"""
			else
				body = """
								<div class='success'>Success! IP [<span id='ip'>#{ip}</span>] is allowed.</div>
						"""

		else if !result
			# Failure
			body = """
							<div class='error'>Error! Access denied.</div>
					"""

		return """
				<html>
					<head>
						<title>fw hole poker</title>
						<style type='text/css'>
							body { position: relative; }
							body .content {
								position: absolute;	margin: auto;
								top: 0; left: 0; bottom: 0; right: 0;
								width: 30%; height: 20%;
								text-align: center;
							}
							div.ip { margin: 2% 0; }
							div.success { color: green; }
							div.error { color: red; }
							span#ip { font-weight: bold; }
						</style>
					</head>
					<body>
						<div class='content'>
							#{body}
						</div>
						<script>window.onload = function(){ document.getElementsByName('password')[0].focus() }</script>
					</body>
				</html>
				"""



# Start the HTTPS server:
https.createServer options, (req, res) ->
	ip = req.connection.remoteAddress

	if req.method == 'GET'
		res.writeHead(200)
		res.end html.render(ip)

	else if req.method == 'POST'
		requestBody = ''

		req.on 'data', (data) ->
			requestBody += data
			if requestBody.length > 1e5
				res.writeHead 413, "Request Entity Too Large", {'Content-Type': 'text/html'}
				res.end '<!doctype html><html><head><title>413</title></head><body>413: Request Entity Too Large</body></html>'

		req.on 'end', () ->
			date = new Date(); date = "#{date.toDateString()} #{date.toTimeString().substr(0,8)}"
			password = qs.parse(requestBody).password
			time = null
			if password of config.passwords
				result = true 		# Correct!
				params = config['passwords'][password]
				time = if params['time']? then params['time'] else config.general.time

				# Report this attempt
				console.log "#{date}: ALLOW #{ip} - Access granted for #{time} seconds"

				# Execute the firewall cmd:
				cmd.allow(ip, params)
			else
				result = false 		# Wrong password is given

				# Report this attempt
				console.log "#{date}: REJECT #{ip} - Wrong password"

			res.end html.render(ip, result)

.listen(config.general.port, config.general.ip)

console.log "FWHP starter. Listening on #{config.general.ip}:#{config.general.port}..."