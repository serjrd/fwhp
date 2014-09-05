#!/usr/bin/env coffee

# This file exports the config object that describes the possible passwords and appropriate actions to take
module.exports =
	'password1':
		cmd: './cmd/iptables.coffee'	# the local script to run upon successful authentication
		time: 18000 					# time in seconds after which the 'deny' action is called
		arg: 'trusted'					# An optional argument that may be passed to that CMD in addition to the standard ones
										# e.g.: ipset set name, port number
	'password2':
		cmd: './cmd/iptables.js'
		arg: '2222'
