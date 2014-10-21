fwhp
=============

Grant temp firewall access (or run other actions locally) through web authentication

This might come in handy when you need to connect to your firewall-protected server from an unusual IP address.
For example, if you're on vacation.

## How it works
- You tell fwhp what script/command to execute upon successful authentication (e.g. add some firewall rules to temporarily grant access to that IP address).
- fwhp starts a native node.js HTTPS server and waits for a correct password.
- When it gets a correct password it executes your command as follows: `/your/script allow <IP> [<optional arguments you configured>]`
- After the time you configured it runs the same script as follows: `/your/script deny <IP> [<optional arguments you configured>]`

## Config
If you want - you can have several passwords that trigger different actions.
Here's a sample config file:

```javascript
module.exports = {
	general: {
		ip: '0.0.0.0',						// IP that FWHP should listen on
		port: 1000,								// TCP port to bind to
		time: 18000,							// default time in seconds after which the 'deny' action is called
		ssl: '/etc/fwhp/ssl',			// the folder with SSL cert.pem and key.pem files
		log: '/var/log/fwhp.log'
	},
	passwords: {
		// This section defines the valid passwords and the actions to take upon successful authentification with that password
		'password1': {
			cmd: '/etc/fwhp/cmd/iptables.js',	// the local script to run upon successful authentication
			time: 18000,											// redefine the default time
			arg: 'trusted'										// An optional argument that may be passed to that CMD in addition to the standard ones (e.g.: ipset set name, port number)
		},
		'password2': {
			cmd: '/etc/fwhp/cmd/iptables.js',
			arg: '2222'
		}
	}
};
```

## Scripts
Sample scripts are provided with the app (see the `config/cmd` folder).
Here's an example of what your script may look like:

```javascript
var action, exec, ip, set, _ref;
exec = require('child_process').exec;

// parse the arguments
_ref = process.argv.slice(2), action = _ref[0], ip = _ref[1], set = _ref[2];

// make something useful
switch (action) {
	case 'allow':
		exec("ipset add " + set + " " + ip);
		break;
	case 'deny':
		exec("ipset del " + set + " " + ip);
		break;
	default:
		console.log("Wrong action provided");
}
```

## Usage:
```
sudo fwhp-start /etc/fwhp/config.js
```

## Installation
You will need a node.js and npm packed manager to install it:

```
sudo npm install -g fwhp
sudo fwhp-init-config
```
Running `fwhp-init-config` is optional. It will:
- install the sample config file
- install sample script files 
- optionally generate you a self-signed SSL certificate (needed for running HTTPS server)

If you don't have node.js installed on your system, here's how to do it (Ubuntu/Debian)
```
sudo apt-get install nodejs npm
```
