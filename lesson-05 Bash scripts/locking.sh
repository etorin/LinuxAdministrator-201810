#!/bin/bash
#export LD_LIBRARY_PATH=/usr/local/instantclient_11_1/lib/

sec=$1
LOCK=/var/tmp/initplock
if [ -f $LOCK ]; then
 echo Job is already running\!
 exit 6
fi
touch $LOCK
trap 'rm -f "$LOCK"; exit $?' INT TERM EXIT

i=0
until [[ i -eq $sec ]]; do #Checks if i=10
 echo "i=$i" #Print the value of i
 sleep 1
 i=$((i+1)) #Increment i by 1
done

rm -f $LOCK
trap - INT TERM EXIT