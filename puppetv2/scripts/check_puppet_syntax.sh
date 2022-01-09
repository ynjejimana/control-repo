#!/bin/bash
# Script to test puppet files have valid syntax..

set -e
set -u

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
 
fail=0
all_files=`find $DIR/.. -name "*.pp" -o -name "*.erb"`
num_files=`echo $all_files | wc -w`
if [[ $num_files -eq "0" ]]; then
echo "ERROR: no .pp or .erb files found"
exit 1
fi
echo "Checking $num_files *.pp and *.erb files for syntax errors."
echo "Puppet version is: `puppet --version`"
 
for x in $all_files; do
set +e
case $x in
*.pp )
puppet parser validate $x ;;
*.erb )
cat $x | erb -x -T - | ruby -c > /dev/null ;;
esac
rc=$?
set -e
if [[ $rc -ne 0 ]] ; then
fail=1
echo "ERROR in $x (see above)"
fi
done
 
if [[ $fail -ne 0 ]] ; then
echo "FAIL: at least one file failed syntax check."
else
echo "SUCCESS: all .pp and *.erb files pass syntax check."
fi
exit $fail
