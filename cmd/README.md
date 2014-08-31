Here are some sample scripts that may do the job for you.
Feel free to take any of the provided example scripts or write one yourself.

## The script is called with the following arguments:

- **'allow'/'deny'**	- the action that should be performed
- **IP**				- the IP address that should be allowed/denied
- **'[IP1, IP2...]'**	- the string representation of the array of IP addresses that are currently allowed

The 3rd parameter might come in handy if you need to rebuild the list of permitted IP addresses in some file.


<!-- ## Firewall rules management
There are many ways to update your firewall. If you need a hint - here's how:

### Linux
I suggest using `ipset` to manage the list of IP addresses. It's really fast and helps you keep your ruleset slim.

- Install it if you don't have it on your system yet. For Ubuntu/Debian: `apt-get install ipset`
- Create a new set: `ipset create trusted hash:ip`
- Add an iptables rule: `iptables -A INPUT -m set --match-set trusted src -j GRANT`
 -->