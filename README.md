fwhp
=============

Grant temp firewall access (or run other actions locally) through web authentication

This might come in handy when you need to connect to your firewall-protected server from an unusual IP address.
For example, if you're on vacation.

## How it works
It starts a native node.js HTTPS server and expects a password.
Upon successful authentication it executes a given script that can do anything you want (e.g. add some firewall rules to temporarily grant access to that IP address)

It's really easy to configure. Just give it a password and a script to execute.
Sample scripts are provided with the app (see the `config/cmd` folder)

## Usage:
```
fwhp --config /etc/fwhp/config.js >> /var/log/fwhp.log 2>&1 &
```

Or run it with command-line arguments:
```
fwhp -s PASSWORD -c /etc/fwhp/cmd/iptables.js >> /var/log/fwhp.log 2>&1 &
```

Run it without arguments to see all available options:
```
Options:
  --config      The main config file.                                             
  --ssl         Path to SSL key/cert folder                                         [default: "/etc/fwhp/ssl"]
  -i, --ip      IP address to bind the HTTPS server to                              [default: "0.0.0.0"]
  -p, --port    TCP port to bind the HTTPS server to                                [default: 1000]
  -t, --time    Fire a 'deny' action X seconds after the 'allow'. 0 to disable.     [default: 18000]
  -s, --secret  The secret password that we expect to grant access                
  -c, --cmd     The external allow/deny script. See the ./cmd folder for examples.
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
apt-get install nodejs npm
```
