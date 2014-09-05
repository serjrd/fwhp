#!/usr/bin/env coffee

# Exmaple of coffeescript file to perform desired allow/deny actions

# argv[2] - action ('allow'/'deny')
# argv[3] - IP
# argv[4] - optional parameter described in the config file

exec = require('child_process').exec

[action, ip, set] = process.argv[2..]

exec "echo `date +'%F %T:'` '#{action} #{ip} #{set}' >> /var/log/fwhp.log"

switch action
	when 'allow'
		exec "ipset add #{set} #{ip}"
	when 'deny'
		exec "ipset del #{set} #{ip}"
	else
		console.log "Wrong action provided"