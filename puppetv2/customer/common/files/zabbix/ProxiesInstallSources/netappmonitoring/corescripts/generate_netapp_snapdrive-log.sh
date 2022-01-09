#!/bin/sh

###### LOGS_ Snapdrive Process Monitoring Script v1.2 ######
#  m.cousseau@harboumsp.com

host=$1
profile=$2
outputdir=/tmp/netapp_data_snapdrive
datafile_logs=$outputdir/$host-$profile"_log"
datafile_logs_zbx=$outputdir/$host-$profile"_log_zbx"
line1=`cat $datafile_logs | awk '{print $3}' | sed -n 3p`
line2=`cat $datafile_logs | awk '{print $3}' | sed -n 4p`

#
ssh $host "smo backup list -profile '$profile' -archivelogs" >$datafile_logs
#

if [ $line1 = "SUCCESS" -o $line1 = "RUNNING" -o $line2 = "SUCCESS" -o $line2 = "RUNNING" ]
then
        echo "SUCCESS" > $datafile_logs_zbx
elif [ $line1 = "FAILED" -o $line2 = "FAILED" ]
then
        echo "FAILED" > $datafile_logs_zbx
else
        echo "UNKNOWN" >$datafile_logs_zbx
fi

exit 0;
