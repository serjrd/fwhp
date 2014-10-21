#!/usr/bin/env coffee

# This script starts fwhp process on the background
fs = require 'fs'
path = require 'path'
spawn = require('child_process').spawn

# Try to read config file
try
	configFile = process.argv[2]
	config = require path.resolve configFile
catch e
	console.log "Error reading config file: [#{e}]"
	process.exit 1

# Spawn a fwhp process
out = fs.openSync config.general.log, 'a'
err = fs.openSync config.general.log, 'a'

fwhp = spawn 'fwhp', [configFile], 
	detached: true
	stdio: ['ignore', out, err]

if !fwhp
	console.log "Failed to spawn fwhp :("
	process.exit 1

# Do no wait for the child to finish
fwhp.unref()
console.log "fwhp started on #{config.general.ip}:#{config.general.port}"
process.exit 0