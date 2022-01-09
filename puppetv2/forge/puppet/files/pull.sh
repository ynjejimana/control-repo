#!/bin/bash

cd /etc/puppet/modules/development-checkout
/usr/bin/git pull origin development
/usr/bin/git checkout development --force

cd /etc/puppet/modules/production-checkout
/usr/bin/git pull origin master
/usr/bin/git checkout master --force

# Update Hiera data files
cd /etc/puppet/hiera/development-checkout
/usr/bin/git pull origin development
/usr/bin/git checkout development --force
/usr/bin/git submodule sync
/usr/bin/git submodule update --init --recursive
/usr/bin/git submodule foreach git pull origin master

# Update Hiera data files
cd /etc/puppet/hiera/production-checkout
/usr/bin/git pull origin master
/usr/bin/git checkout master --force
/usr/bin/git submodule sync
/usr/bin/git submodule update --init --recursive
/usr/bin/git submodule foreach git pull origin master

/bin/chown -R puppet: /etc/puppet/hiera /etc/puppet/modules

# gwaugh, 30/03/2017: Stop apache restarting as apache reads hiera and puppet changes anyway without restarting
# /sbin/service httpd graceful
