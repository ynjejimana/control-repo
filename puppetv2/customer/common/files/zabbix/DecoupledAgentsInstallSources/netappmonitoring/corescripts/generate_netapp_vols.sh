#!/bin/sh 
netapp=$1

outputdir=/tmp/netappdata

mkdir -p /tmp/netappdata

datafile=$outputdir/$netapp

#echo netapp: $netapp

x=`ssh $netapp vol status | awk '{print $1}' | grep -v bit | tr '\n' ','`

vols=${x%?}

#echo "perl /srv/zabbix/etc/NetApp/query_netapp.pl -H netapp5 -u root -p netapp01 -v $vols -P nfs -i 1 >&2  /dev/null"
perl /srv/zabbix/etc/NetApp/query_netapp.pl -H $netapp -u root -p netapp01 -v $vols -P nfs -i 1 2> /dev/null > $datafile

exit 0;
