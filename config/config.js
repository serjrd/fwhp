// Generated by CoffeeScript 1.8.0
module.exports = {
	general: {
		ip: '0.0.0.0',					// IP that FWHP should listen on
		port: 1000,						// TCP port to bind to
		time: 18000,					// default time in seconds after which the 'deny' action is called
		ssl: '/etc/fwhp/ssl'			// the folder with SSL cert.pem and key.pem files
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
