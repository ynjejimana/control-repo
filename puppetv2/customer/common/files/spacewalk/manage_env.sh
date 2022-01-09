#!/bin/bash 

channel_list_cmd='/usr/bin/spacewalk-remove-channel -l'
channel_promote_cmd='/usr/bin/spacewalk-manage-channel-lifecycle'

if [ "$#" -ne 4 ]; then
	echo "Usage: $0 satellite_server user password {latest2dev|dev2test|test2prod}"
	exit 1
else
	server=$1
	user=$2
	pass=$3
	action=$4 
fi

case $action in 
"latest2dev")
	echo "We are promoting Latest to Dev environment"
	echo "=========================================="
	for i in `$channel_list_cmd | grep ^[a-z] | egrep -v '^dev-|^test-|^prod-'`; do ($channel_promote_cmd -s $server -u $user -p $pass --promote -c "$i"); done
	;;
"dev2test")
	echo "We are promoting DEV to TEST environment"
	echo "======================================"
	for i in `$channel_list_cmd | grep '^dev-'`; do ($channel_promote_cmd -s $server -u $user -p $pass --promote -c "$i"); done
	;;
"test2prod")
	
	echo "We are promoting TEST to PROD environment"
	echo "======================================="
	for i in `$channel_list_cmd | grep '^prod-'`; do ($channel_promote_cmd -s $server -u $user -p $pass --archive -c "$i"); done
	for i in `$channel_list_cmd | grep '^test-'`; do ($channel_promote_cmd -s $server -u $user -p $pass --promote -c "$i"); done
	;;
*)
	echo "Error: Unknown action specifid - should be one of latest2dev,dev2test or test2prod"
	exit 2
;;

esac



 
