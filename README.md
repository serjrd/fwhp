fwhp
=============

Grant temp firewall access (or run other actions locally) through web authentication

This might come in handy when you need to connect to your firewall-protected server from an unusual IP address.
For example, if you're on vacation.

## How it works
It starts a native node.js HTTPS server and expects a password.
Upon successful authentication it executes a given script that can do anything you want (e.g. add some firewall rules to temporarily grant access to that IP address)

It's really easy to configure. Just give it a password and a script to execute.
Sample scripts are provided with the app (see the ./cmd folder)


## How to install
You will need a node.js and npm packed manager to install it:

```
git clone https://github.com/serjrd/fwhp.git fwhp
cd fwhp && npm install
```

## Usage:
It's usually enough to provide a password and a script to call:

```
./coffee/fwhp.js -s PASSWORD -c ./cmd/iptables.sh >> /var/log/fwhp.log 2>&1 &
```
or
```
node ./js/fwhp.js -s PASSWORD -c ./cmd/iptables.sh >> /var/log/fwhp.log 2>&1 &
```

Run it without arguments to see all available options:

```
Options:
  -i, --ip      IP address to bind the HTTPS server to                               [default: "0.0.0.0"]
  -p, --port    TCP port to bind the HTTPS server to                                 [default: 1000]
  -t, --time    Fire a 'deny' action X seconds after the 'allow'. 0 to disable.      [default: 18000]
  -s, --secret  The secret password that we expect to grant access                 
  -c, --cmd     The external allow/deny script. See the ./cmd folder for examples. 
  --config      The file with the list of passwords and appropriate local commands.
```