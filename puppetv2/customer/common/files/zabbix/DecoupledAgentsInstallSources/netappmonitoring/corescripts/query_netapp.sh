/usr/bin/perl /etc/zabbix/NetApp/query_netapp.pl -H netapp3 -u root -p netapp1 -v `cat /etc/zabbix/nfs_volumes | awk '{ printf "%s,", $0 }'` -P nfs -i 1 > /tmp/netapp3.nfs
