#!/bin/sh
############################################
#                                          #  
#  written by: maxime.cousseau@lab.com  #
#  modified by:                            #
#  28/01/2014                              #
#  v1.0                                    #
#                                          #
############################################

filer=$1
out_MEM_free=/var/tmp/$1-out-netapp-MEM_free
out_MEM_used=/var/tmp/$1-out-netapp-MEM_used


rm -rf $out

ssh $filer "stats show wafl:wafl:wafl_memory_free" >$out_MEM_free
ssh $filer "stats show wafl:wafl:wafl_memory_used" >$out_MEM_used


