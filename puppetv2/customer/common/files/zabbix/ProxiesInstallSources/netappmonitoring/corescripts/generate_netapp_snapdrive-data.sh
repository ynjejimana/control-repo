#!/bin/sh

###### DATA_ Snapdrive Process Monitoring Script v1.2 ######
#  m.cousseau@harboumsp.com

host=$1
profile=$2
outputdir=/tmp/netapp_data_snapdrive
datafile_data=$outputdir/$host-$profile"_data"
datafile_data_zbx=$outputdir/$host-$profile"_data_zbx"
line1=`cat $datafile_data | awk '{print $3}' | sed -n 3p`
line2=`cat $datafile_data | awk '{print $3}' | sed -n 4p`

#
ssh $host "smo backup list -profile '$profile' -archivelogs" >$datafile_data
#

if [ $line1 = "SUCCESS" -o $line1 = "RUNNING" -o $line2 = "SUCCESS" -o $line2 = "RUNNING" ]
then
	echo "SUCCESS" > $datafile_data_zbx
elif [ $line1 = "FAILED" -o $line2 = "FAILED" ]
then
	echo "FAILED" > $datafile_data_zbx
else
	echo "UNKNOWN" >$datafile_data_zbx
fi

exit 0;
