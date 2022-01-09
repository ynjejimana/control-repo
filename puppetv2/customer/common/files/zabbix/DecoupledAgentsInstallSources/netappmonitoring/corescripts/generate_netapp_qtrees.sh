#!/bin/sh 
netapp=$1

outputdir=/tmp/netappdata

mkdir -p /tmp/netappdata

datafile="$outputdir/$netapp-qtree"

x=`ssh $netapp 'qtree status' | egrep -v '^--' | perl -nle 'printf("%s\x2f%s,", $1, $2) if /^([^\s]+)\s([^\s]+)/'`

qtrees=${x%?}

perl /srv/zabbix/etc/NetApp/query_netapp_qtree.pl -H $netapp -u root -p netapp01 -q $qtrees -P nfs -i 1 2> /dev/null > $datafile

exit 0;
