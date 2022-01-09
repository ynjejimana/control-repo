#!/bin/sh
export PATH=/bin:/usr/bin

if [ $# != 1 ]
then
	exit 1
fi

cd $1 2>/dev/null

for key in `ls ./RPM-GPG* 2>/dev/null`; do (rpm --import $key 2>/dev/null); done

exit 0
