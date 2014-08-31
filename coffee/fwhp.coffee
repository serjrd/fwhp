#!/usr/bin/env coffee

https = require 'https'
fs = require 'fs'
qs = require 'querystring'
execFile = require('child_process').execFile
argv = require 'yargs'
		.default {i: '0.0.0.0', p: 1000, t: 300}
		.alias {i: 'ip', p: 'port', s: 'secret', t: 'time', c: 'command'}
		.describe 
			i: 'IP address to bind the HTTPS server to'
			p: 'TCP port to bind the HTTPS server to'
			t: "Fire a \'deny\' action X minutes after the 'allow'. 0 to disable."
			s: 'The secret password that we expect to grant access'
			c: 'The external script that will be called to perform the actual allow/deny actions. See the ./cmd folder for examples.'
		.demand ['s','c']
		.example "$0 -c ~/fw.sh -s T0Ps3cr3t", "Start the https server on 0.0.0.0:1000 (defaults) that expects 'T0Ps3cr3t' as a password. Upon successful authentication the '~/fw.sh' script will be called."
		.argv


# Check if the external script is accessible:
if !fs.existsSync argv.command
	console.error "Error: unable to find '#{argv.command}'. Exitting.."
	process.exit 1


# Read the SSL key/cert files:
try
	options =
		key: fs.readFileSync('./ssl/key.pem')
		cert: fs.readFileSync('./ssl/cert.pem')
catch
	console.error """

		Oops..!
		Couldn't read the SSL key/cert files (./ssl/key.pem and ./ssl/cert.pem).
		Here's a way to generate a self-signed certificate:

		# cd ./ssl
		# openssl genrsa -out key.pem 2048
		# openssl req -new -x509 -key key.pem -out cert.pem -days 1095
		# chmod 400 *.pem

		"""
	process.exit 1


allowed_ips = {}

# The methods that call the external script
# They fire an external command with the following arguments:
# 	'allow'/'deny'	- the action that should be performed
#	IP				- the IP address that should be allowed/denied
#	'[IP1, IP2...]'	- the string representation of the array of IP addresses that are currently allowed (useful if you need to rebuild the whole access rules)
cmd =
	# This method is called upon successful authentication
	allow: (ip) ->
		if argv.time
			clearTimeout allowed_ips[ip] if allowed_ips[ip]?
			allowed_ips[ip] = setTimeout @deny, argv.time * 60000, ip
		execFile argv.command, ['allow', ip, "[#{Object.keys allowed_ips}]"], (error, stdout, stderr) ->
				console.log "#{error}" if error
				console.log "#{stdout}" if stdout

	deny: (ip) ->
		if allowed_ips[ip]?
			clearTimeout allowed_ips[ip]
			delete allowed_ips[ip]
		execFile argv.command, ['deny', ip, "[#{Object.keys allowed_ips}]"], (error, stdout, stderr) ->
				console.log "#{error}" if error


# The function to generate some HTML for our web server
html =
	render: (ip, result) ->
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
			if argv.time
				body = """
								<div class='success'>Success! IP [<span id='ip'>#{ip}</span>] is allowed for #{argv.time} minutes.</div>
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
			# if password == config.password
			if password == argv.s
				result = true 		# Correct!

				# Report this attempt
				console.log "#{date}: ALLOW #{ip} - Access granted for #{argv.time} minutes"

				# Execute the firewall cmd:
				cmd.allow(ip)
			else
				result = false 		# Wrong password is given

				# Report this attempt
				console.log "#{date}: REJECT #{ip} - Wrong password"

			res.end html.render(ip, result)

.listen(argv.port, argv.ip)

console.log "FWHP starter. Listening on #{argv.ip}:#{argv.port}..."