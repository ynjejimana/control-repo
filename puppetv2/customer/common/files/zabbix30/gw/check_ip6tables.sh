#!/bin/bash


if [ $# -lt 2 ]; then
        echo "Usage:"
        echo "       $0 {Virtual IPv6} {To-Source IPv6 1} {To-Source IPv6 2} ..."
        echo "       $0 {Virtual IPv6} 0.0.0.0"
        exit 1
fi

VIP=$1

for (( i=2; i<=$#; i++ )); do
        SOURCE="${!i}"
        if [ $SOURCE == '0.0.0.0' ]; then
                eval /sbin/ip6tables --wait -L POSTROUTING -t nat -n | grep -q "^SNAT.*::/0.*::/0.*${VIP}"
                RET=$?
                if [ ${RET} != 0 ]; then
                        exit 254
                fi
        else
                eval /sbin/ip6tables --wait -L POSTROUTING -t nat -n | grep -q "^SNAT.*${SOURCE}.*::/0.*${VIP}"
                RET=$?
                if [ ${RET} != 0 ]; then
                        exit $i
                fi
        fi
done

exit 0

