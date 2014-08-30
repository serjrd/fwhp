#!/usr/bin/env coffee

cmd = require('./cmd.coffee').init()
https = require 'https'
fs = require 'fs'
qs = require 'querystring'
config = require './config.coffee'
html = require './html.coffee'

options =
	key: fs.readFileSync('./ssl/key.pem')
	cert: fs.readFileSync('./ssl/cert.pem')

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
			if password == config.password
				result = 1 		# Correct!

				# Report this attempt
				console.log "#{date}: ALLOW #{ip} - Access granted for #{config.time} minutes"

				# Execute the firewall cmd:
				cmd.allow(ip, config.time)
			else
				result = -1 	# Wrong password is given

				# Report this attempt
				console.log "#{date}: REJECT #{ip} - Wrong password"

			res.end html.render(ip, result, config.time)

.listen(config.listen.port, config.listen.ip)