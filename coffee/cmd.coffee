#!/usr/bin/env coffee

exec = require('child_process').exec
fs = require 'fs'

class Cmd
	instance = null

	class Private
		# This object will hold the allowed ips and their timeouts
		allowed_ips = {}

		# This is the function that will be executed upon successful authorization
		# 
		# ip - the ip that should be granted access
		# timeout - is the time in minutes while this permission is valid
		grant: (ip, timeout) ->
			# Check if this IP is already registered:
			if allowed_ips[ip]?
				clearTimeout allowed_ips[ip]

			# Revoke the access after the timeout
			allowed_ips[ip] = setTimeout @revoke, timeout * 60000, ip
			
			# Rebuild the file containing dev ips (coeffee_stage):
			@rebuild_dev_ips()

			# Firewall hole:
			cmd = "/sbin/ipfw table 2 add #{ip} && echo \"/sbin/ipfw table 2 delete #{ip}\" | at now + #{@time} minutes"
			exec cmd, (error, stdout, stderr) ->
				console.log "#{error}" if error


		revoke: (ip) ->
			if allowed_ips[ip]?
				clearTimeout allowed_ips[ip]

			delete allowed_ips[ip]
			
			@rebuild_dev_ips()


		rebuild_dev_ips: ->
			# Update the PHP file:
			console.log "Rebuilding dev_ips.php. Allowed ips are: #{Object.keys(allowed_ips)}"

			ips = []
			ips.push "'#{ip}'" for ip of allowed_ips
			cmd = "<?php $dev_ips = [#{ips}]; ?>"
			fs.writeFile('/usr/local/www/coeffee_stage/dev_ips.php', cmd)
			

	@init: ->
		instance ?= new Private()


module.exports = Cmd