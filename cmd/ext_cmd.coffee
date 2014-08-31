#!/usr/bin/env coffee

# Exmaple of coffeescript file to perform desired allow/deny actions

# argv[2] - action ('allow'/'deny')
# argv[3] - IP
# argv[4] - string representation of the array of all the IPs that are currently allowed

exec = require('child_process').exec

[action, ip, allowed_ips] = process.argv[2..]

console.log "Started with arguments: #{process.argv[2..]}"
exec "echo '#{process.argv[2..]}' >> /home/serjrd/fw-hole-poker/log.log"

switch action
	when 'allow'
		exec "echo ipset add trusted #{ip}"
	when 'deny'
		exec "echo ipset del trusted #{ip}"
	else
		console.log "Wrong action provided"