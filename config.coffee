#!/usr/bin/env coffee

Config =
	listen:
		ip: '0.0.0.0'
		port: '8000'
	password: 'testing123'	# The password that grants you the access
	time: 3000				# Time period in minutes for the temporary firewall rule to be active

	cmd: (ip) ->
		add_rule_cmd = "/sbin/ipfw table 2 add #{ip}"
		del_rule_cmd = "/sbin/ipfw table 2 delete #{ip}"
		
		"/sbin/ipfw table 2 add #{ip} && echo \"/sbin/ipfw table 2 delete #{ip}\" | at now + #{@time} minutes"

module.exports = Config

# openssl genrsa -out key.pem 2048
# openssl req -new -x509 -key key.pem -out cert.pem -days 1095