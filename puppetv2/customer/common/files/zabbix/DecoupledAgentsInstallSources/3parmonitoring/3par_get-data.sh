#!/bin/sh

# Variables
storage=$1
command=$2
tmpdir=/tmp/.3par/


# Commands
cat $tmpdir/$1_$2 | awk '{print $1}' | tr -d '!' | head -1

