#!/usr/bin/env coffee

# This script will install config file where the user wants them

inquirer = require 'inquirer'
path = require 'path'
fs = require 'fs'
exec = require('child_process').exec
spawn = require('child_process').spawn

questions = [
		type: 'input'
		name: 'path'
		message: 'Config folder'
		default: '/etc/fwhp'
	,
		type: 'confirm'
		name: 'ssl'
		message: 'Generate self-signed SSl certificate'
		default: true
]

# Resolve the path to the module's folder that was created by npm
# Currently it will follow the symlink of that binary file
conf_path = path.resolve process.argv[1], '..', fs.readlinkSync(process.argv[1]), '../../config'

inquirer.prompt questions, (res) ->
	console.log "Installing config to #{res.path}..."
	exec "mkdir -p #{res.path}; cp -r #{conf_path}/* #{res.path} && chmod 600 #{res.path}/config.js", (err) ->
		if err
			console.log "#{err}"
			process.exit 1
		else 
			if res.ssl
				console.log "Generating SSL key and certificate\n"
				exec "openssl genrsa -out #{res.path}/ssl/key.pem 2048", (err) ->
					if err
						console.log "#{err}"
						process.exit 1
					else
						cert = spawn "openssl", ['req', '-new', '-x509', '-key', "#{res.path}/ssl/key.pem", '-out', "#{res.path}/ssl/cert.pem", '-days', '1095'], stdio: 'inherit'
						
						cert.on 'close', (code) ->
							if code == 0
								exec "chmod -R 600 #{res.path}/ssl/*.pem", ->
									console.log """
									DONE!
									You may now run:

									fwhp-start #{res.path}/config.js
									
									"""
							else
								console.log "Generating canceled. Exiting."
								process.exit 1