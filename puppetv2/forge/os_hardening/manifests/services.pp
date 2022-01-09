class os_hardening::services (
	$services = ['xinetd','telnet-server', 'rsh-server', 'telnet', 'rsh',
		    'ypbind', 'ypserv', 'tftp-server', 'cronie-anacron', 'bind',
		    'vsftpd', 'httpd', 'dovecot', 'squid', 'net-snmpd'],
){
	package { $services:
		ensure => 'absent',
	}
}
