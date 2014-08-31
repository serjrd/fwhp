fw-hole-poker
=============

Temp firewall access (or other actions) through web authentication

This might come in handy when you need to connect to your firewall-protected server from an unusual IP address.
For example, if you're on vacation.

## How it works
It starts a native node.js HTTPS server and expects a password.
Upon successful authentication it executes a script that can do anything you want (e.g. add some firewall rules to temporarily grant access to this IP address)

It's really easy to configure. Just give it a password and a script to run.
Sample scripts to manage your firewall (Linux, FreeBSD) are provided with the app (see ./cmd folder)


## How to install
You will need a node.js and npm packed manager to install it:

```
npm install fw-hole-poker
```

## How to run:
It's usually enough to provide a password and a script to call:

```
node ./js/fwhp.js -s PASSWORD -c ./cmd/fw.sh
```

Run it without arguments to see all available options:

```
Options:
  -i, --ip       IP address to bind the HTTPS server to                                                                                [default: "0.0.0.0"]
  -p, --port     TCP port to bind the HTTPS server to                                                                                  [default: 1000]
  -t, --time     Fire a 'deny' action X minutes after the 'allow'. 0 to disable.                                                       [default: 300]
  -s, --secret   The secret password that we expect to grant access                                                                    [required]
  -c, --command  The external script that will be called to perform the actual allow/deny actions. See the ./cmd folder for examples.  [required]

```