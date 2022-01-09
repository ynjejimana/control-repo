/usr/bin/perl /etc/zabbix/NetApp/query_netapp.pl -H hmsp-syd-filer1-01 -u root  -v `cat /etc/zabbix/nfs_volumes | awk '{ printf "%s,", $0 }'` -P nfs -i 1 > /tmp/hmsp-syd-filer1-01.nfs
