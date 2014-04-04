#!/usr/bin/env coffee

exec = require('child_process').exec
https = require 'https'
fs = require 'fs'
qs = require 'querystring'
config = require './config.coffee'
html = require './html.coffee'

options =
	key: fs.readFileSync('./key.pem')
	cert: fs.readFileSync('./cert.pem')

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
			password = qs.parse(requestBody).password
			if password == config.password
				result = 1

				# Execute the firewall cmd:
				exec config.cmd(ip)
			else
				result = -1

			res.end html.render(ip, result, config.time)

.listen(config.listen.port, config.listen.ip)