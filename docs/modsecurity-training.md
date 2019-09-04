Modsecurity reverse proxy tuning procedure
==========================================

1. Clone reverse proxy VM
	* change ip address in /etc/network/interfaces
	* change hostname in /etc/hosts and /etc/hostname
	* reboot

2. Reconfigure virtual host(s) for new service
	* new proxy destination under port 80 and port 443
	* install new certificate/key

3. Place modsecurity in detection-only mode and clean logs
	* "SecRuleEngine DetectionOnly" at top of /etc/modsecurity/modsecurity.conf
	* delete any SecRuleRemoveById lines from /etc/modsecurity/modsecurity.conf
	* delete /var/log/apache2/modsec_{audit,debug}.log
	* restart apache2

4. Configure testers to use proxy
	* modify local hosts file to point service DNS to proxy IP

5. Testers to fully exercise service
	* testers must simulate only good user behaviour during this stage

6. Run the following command on proxy to identify triggered rules:

		perl -ne 'print if s/.*id\s+\"(\d+)\".*/$1/' /var/log/apache2/modsec_debug.log | sort | uniq

7. Disable (whitelist) false-positive rules
	* refer to common false positive list at:
		https://www.netnea.com/cms/2016/01/17/most-frequent-false-positives-triggered-by-owasp-modsecurity-core-rules-2-2-x/
	* DO NOT disable any auxiliary rules ("does not apply") such as:
		* 981018--981022
		* 981133,981134
		* 981177,981178
		* 981200--981205
		* 981300--981316
	* DO NOT disable any rules in the 200000 series
	* disable rules by appending to /etc/modsecurity/modsecurity.conf:

			"SecRuleRemoveById xxxxxx"

8. Place modsecurity in blocking mode
	* "SecRuleEngine On" in /etc/modsecurity/modsecurity.conf
	* restart apache2

9. Redirect DNS from original service to reverse proxy
	
Any rules that trigger after this should be considered genuine attacks until proven otherwise

https://www.feistyduck.com/library/modsecurity-handbook-free/
