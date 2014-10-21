#!/usr/bin/env coffee

https = require 'https'
fs = require 'fs'
path = require 'path'
qs = require 'querystring'
execFile = require('child_process').execFile
util = require 'util'

# Try to read config file:
try
	configFile = process.argv[2]
	config = require path.resolve configFile
catch e
	console.log "Error reading config file: [#{e}]"
	process.exit 1

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



###
The methods that call the external script
They fire an external command with the following arguments:
	'allow'/'deny'	- the action that should be performed
	IP							- the IP address that should be allowed/denied
###
allowed_ips = {}
cmd =
	# This method is called upon successful authentication
	allow: (ip, params) ->
		time = params.time or config.general.time

		if time
			# Schedule the 'deny' action
			clearTimeout allowed_ips[ip] if allowed_ips[ip]?
			allowed_ips[ip] = setTimeout @deny, time * 60000, [ip, params]

		# Execute the external command
		execFile params.cmd, ['allow', ip, params.arg], (error, stdout, stderr) ->
				console.log "#{error}" if error
				console.log "#{stdout}" if stdout

	# This method is optionally called some time after the 'allow'
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