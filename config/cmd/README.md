Here are some sample scripts that may do the job for you.
Feel free to use any of the provided scripts or write one yourself.

## The script is called with the following arguments:

- **'allow'/'deny'**	- the action that should be performed
- **IP**				- the IP address that should be allowed/denied
- **arg**				- an optional argument from the config file (e.g. set name or port number)

e.g.: `/etc/fwhp/cmd/iptables.js allow 127.0.0.1 trusted` to allow an IP and then `/etc/fwhp/cmd/iptables.js deny 127.0.0.1 trusted` to revoke its access.

## Configuring your firewall
It's usually a good idea to build your firewall rules using some sort of tables. This helps you keep your rule list short and efficient.

### Linux: iptables + ipset
In Linux you can use **ipset** to manage the lists of IPs/subnets.
If it's not installed on your system, run `apt-get install ipset`.

Create a new ipset set and add some IPs that should always be trusted (if any):
```
ipset create trusted hash:ip
ipset add trusted <IP1>
ipset add trusted <IP2>
```

Create iptables rules:
```
# Allow traffic for established connections and local traffic:
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Allow SSH connection for trusted IPs and deny for everybody else:
iptables -A INPUT -m set --match-set trusted src -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -m tcp -p tcp --dport 22 -j DROP
```

To add/remove IPs from the trusted list use: `ipset add trusted <IP>` and `ipset del trusted <IP>`.
Check the sample `iptables.*` scripts at `config/cmd` folder to get an idea of what your script may look like.


### FreeBSD: ipfw
**ipfw** has built-in tables support. A sample configuration of your firewall might look like this:

Flush the table initially and add the IP addresses that should always be allowed (if any):
```
ipfw table 100 flush
ipfw table 100 add <IP1>
ipfw table 100 add <IP2>
```

Allow SSH access for the IPs listed in our table 100:
```
ipfw add 1000 allow tcp from table"(100)" to me 22
ipfw add 1001 deny tcp from any to me 22
```

To add/remove IPs from the trusted list use: `ipfw table 100 add <IP>` and `ipfw table 100 del <IP>`