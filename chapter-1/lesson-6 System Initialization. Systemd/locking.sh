#!/bin/bash
#FILENAME_1=/var/log/audit/audit.log
#WORD_1=root
key=1

while [ $key -gt 0 ]
do
tail -n100 $FILENAME_1 | grep $WORD_1 | tail -n1 >> /home/vagrant/logofsearchig.log
for i in {1..30}; do echo -n '!'; sleep 1; done
done