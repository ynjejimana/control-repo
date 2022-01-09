#!/bin/sh
MAILTO=root


if [ $# != 2 ]
then
        echo "Warning: use $0 user password"
        exit 1
fi

sw_user=$1
sw_pass=$2



#get errata file and checksums
cd /tmp
wget -N http://cefs.steve-meier.de/errata.latest.xml 1>/dev/null 2>&1
wget -N http://cefs.steve-meier.de/errata.latest.md5 1>/dev/null 2>&1
wget -N http://www.redhat.com/security/data/oval/com.redhat.rhsa-all.xml.bz2 1>/dev/null 2>&1
bunzip2 -f /tmp/com.redhat.rhsa-all.xml.bz2

#verify integrity
grep "errata.latest.xml$" errata.latest.md5 > myerrata.md5
md5sum -c myerrata.md5 1>/dev/null 2>&1
if [ "$?" == 0 ]; then
        #ok - import errata
        SPACEWALK_PASS=$sw_pass SPACEWALK_USER=$sw_user /usr/local/scripts/errata_import.pl --server localhost --user=$sw_user --pass=$sw_pass --errata errata.latest.xml --rhsa-oval=/tmp/com.redhat.rhsa-all.xml --publish 
        if [ "$?" != 0 ]; then
                echo "It seems like there was a problem while publishing the most recent errata..."
                exit 1
        fi
        rm /tmp/myerrata.md5
else
        #errata information possibly invalid
        echo "ERROR: md5 checksum mismatch, check download!"
        exit 1
fi

