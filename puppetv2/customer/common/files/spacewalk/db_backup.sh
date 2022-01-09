#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [ $# != 2 ]
then
	echo "Warning: use $0 {user} {/path/to/dump}"
	exit 1
fi

dump_dir=$2
dump_user=$1
date_str=`date +%F-%s`

if [ ! -d "${dump_dir}" ]
then
	echo "Warning: Directory path doesn't exist"
	exit 2
fi

avail_size=`df -k ${dump_dir} | grep -v "Filesystem" | awk '{print $4}'`


if [ $avail_size -lt "20000000" ]
then
	echo "Warning: not enough space to dump the DB \n"
	exit 3
fi


su - $dump_user -c "pg_dumpall > ${dump_dir}/full_spacewalk_backup-${date_str}.sql"

if [ $? -eq 0 ]
then
	cd $dump_dir
	for i in `ls | grep "full_spacewalk_backup*" | grep -v "full_spacewalk_backup-${date_str}.sql"`; do rm -f $i; done
	echo "Backup is completed successfully"
	exit 0
else
	echo "Error: backup failed"
	exit 255
fi 

