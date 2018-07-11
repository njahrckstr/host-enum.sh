#!/bin/bash

#Tested with nmap 7.70 on Kali 2018
#   ./configure
#   make
#   make install
#
#fix unicorn scan:
#   cp /usr/share/GeoIP/GeoIP.dat /usr/local/etc/unicornscan/
#
#to run this on a range and log the output at the same time
#   for i in $(seq 200 254); do bash host-enum.sh 192.168.17.$i | tee -a host-enum/all.txt; done
#
#open the results all pretty like..
#   zenmap -f *.xml #this assumes you have changed the nmap command to log to xml
#----------------------------------------------------------------

#obviously a LOT more scripts can be added, I have chosen these ones cause they "shouldnt" break stuff, but will give me as much info as possible. This list does not include any brute, exploit, dos, or auth scirpts
SCRIPTS=afp-ls,auth-owners,banner,creds-summary,dns-zone-transfer,domino-enum-users,dns-nsid,duplicates,finger,firewall-bypass,ftp-anon,ftp-bounce,ftp-proftpd-backdoor,ftp-vsftpd-backdoor,ftp-vuln-cve2010-4221,http-apache-negotiation,http-auth,http-sql-injection,http-auth-finder,http-methods,http-axis2-dir-traversal,http-backup-finder,http-barracuda-dir-traversal,http-cakephp-version,http-brute,http-config-backup,http-default-accounts,http-enum,http-generator,http-headers,http-iis-webdav-vuln,http-majordomo2-dir-traversal,http-method-tamper,http-open-proxy,http-open-redirect,http-passwd,http-php-version,http-phpself-xss,http-rfi-spider,http-robots.txt,http-sitemap-generator,http-title,http-unsafe-output-escaping,http-userdir-enum,http-vuln-cve2010-2861,http-vuln-cve2012-1823,http-wordpress-enum,imap-capabilities,irc-info,krb5-enum-users,ms-sql-config,ms-sql-empty-password,ms-sql-info,mysql-info,mysql-empty-password,nbstat,netbus-auth-bypass,oracle-enum-users,oracle-sid-brute,ovs-agent-version,pop3-capabilities,pptp-version,realvnc-auth-bypass,rpcap-info,rpcinfo,samba-vuln-cve-2012-1182,servicetags,sip-methods,sip-enum-users,smb-vuln-*,smb-enum-domains,smb-enum-groups,smb-enum-sessions,smb-enum-shares,smb-enum-users,smb-ls,smb-mbenum,smb-os-discovery,smtp-commands,smtp-enum-users,smtp-open-relay,smtp-vuln-cve2011-1764,snmp-brute,snmp-interfaces,snmp-netstat,snmp-ios-config,snmp-processes,snmp-sysdescr,snmp-win32-services,snmp-win32-shares,snmp-win32-software,snmp-win32-users,socks-open-proxy,telnet-encryption,tftp-enum,unusual-port,upnp-info,vnc-info,http-traceroute,http-frontpage-login,mysql-vuln-cve2012-2122,http-drupal-enum-users,http-tplink-dir-traversal

#first FAIL!
if [ -z "$1" ]; then echo "You need to specify a host!  >>  $0 <IP address>"; exit 1 ; fi

#second FAIL!
if [[ ! $1 =~ (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) ]]; then echo "Invalid IP address!  >>  $0 <IP address>"; exit 1 ; fi

#third FAIL!
if [[ $EUID -ne 0 ]]; then echo "You must be root/sudo to run this script"; exit 1 ; fi

#start a little timer to time how long the unicorn scans take
START=$(date +%s)

echo -e "\033[1;32mHost enumeration script running on: $1 \033[m"

#TCP scan - Cause im scanning over a VPN, L & R values are higher than they would be on a LAN, r is lower
echo "Scanning all 65535 TCP ports"
#TCP=`unicornscan -msf -R1 -L10 -p1-65535 -r 300 $1 | cut -d"[" -f2 |cut -d"]" -f1 |sed -e 's/^[ \t]*//' | tr "\n" "," | sed 's/,$//'`
TCP=`unicornscan -msf -pa $1 | cut -d"[" -f2 |cut -d"]" -f1 |sed -e 's/^[ \t]*//' | tr "\n" "," | sed 's/,$//'`
#TCP=`for i in {1..5}; do unicornscan -msf $1; done | cut -d"]" -f1 | cut -d"[" -f2 | sed -e 's/^[ \t]*//' | sort -u | tr "\n" "," | sed 's/,$//'` #default ports, but seems to catch more
echo "| Ports open:$TCP"
#display time taken to complete the scan
END=$(date +%s); DIFF=$(( $END - $START ))
echo "|_TCP scan completed in: $DIFF seconds"


#UDP scan - Cause im scanning over a VPN, L & R values are higher than they would be on a LAN, r is lower
echo "Scanning all 65535 UDP ports"
#UDP=`unicornscan -mU -L10 -R1 -p1-65535 -r 300 $1 | cut -d"[" -f2 |cut -d"]" -f1 |sed -e 's/^[ \t]*//' | tr "\n" "," | sed 's/,$//'`
UDP=`unicornscan -mU -pa $1 | cut -d"[" -f2 |cut -d"]" -f1 |sed -e 's/^[ \t]*//' | tr "\n" "," | sed 's/,$//'`
#UDP=`for i in {1..5}; do unicornscan -mU $1; done | cut -d"]" -f1 | cut -d"[" -f2 | sed -e 's/^[ \t]*//' | sort -u | tr "\n" "," | sed 's/,$//'` #default ports, but seems to catch more
echo "| Ports open:$UDP"
#display time taken to complete the scan
END=$(date +%s); DIFF=$(( $END - $START ))
echo -n "|_UDP scan completed in: $DIFF seconds"

#just doing some checks to set the PORTS variable for nmap
if [[ ! $TCP && ! $UDP ]]; then echo "[-] FAIL!.. no open ports"; exit 1; fi
if [[ ! $TCP && $UDP ]]; then PORTS="U:$UDP"; fi
if [[ $TCP && ! $UDP ]]; then PORTS="T:$TCP"; fi
if [[ $TCP && $UDP ]]; then PORTS="U:$UDP,T:$TCP"; fi

#nmap scan .. .. GO!
#echo "[+] Enumerating listening services"
#nmap -Pn -sSUV -p $PORTS --open -T2 -O --script=default,$SCRIPTS $1
nmap -Pn -sSUV -p $PORTS --open -T2 -O --script=default,$SCRIPTS --append-output -oX host-enum-all.xml --script-args=unsafe=1 $1
