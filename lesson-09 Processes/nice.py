#!/usr/bin/env python

import subprocess
import datetime
from datetime import datetime
import time
from concurrent.futures import ThreadPoolExecutor
from pprint import pprint
import sys
from tabulate import tabulate

def run_command(command):
    start_time = datetime.now()
    result = subprocess.check_output(command, shell=True)
    totaltime=datetime.now() - start_time
    start_time = datetime.now()
    return (command,totaltime)

def threads_conn(function, command, limit=2):
    with ThreadPoolExecutor(max_workers=limit) as executor:
        f_result = executor.map(function, command)
    return list(f_result)


if __name__ == '__main__':
    try:
        nice1 = int(sys.argv[1])
    except IndexError as e:
        nice1 = '+19'
        print(u'There is no arg[1], default {}'.format(nice1))
    else:
        print(u"Nice for first command = {}".format(nice1))
    
    try:
        nice2 = int(sys.argv[2])
    except IndexError as e:
        nice2 = '-20'
        print(u'There is no arg[2], default {}'.format(nice2))
    else:
        print(u"Nice for second command = {}".format(nice2))
    
    try:
        file = open('1g.img')
    except IOError as e:
        print(u'There is no file to test')
        command0="dd if=/dev/zero of=1g.img bs=1 count=0 seek=1G oflag=direct"
        result0 = subprocess.check_output(command0, shell=True)    
    else:
        print(u"Let's check it")
    
    start_time = datetime.now()
    
    command1 = "nice -n {} cat 1g.img | nice -n {} bzip2 -c > /dev/null".format(nice1,nice1)
    result1 = subprocess.check_output(command1, shell=True)
    
    time1=datetime.now() - start_time
    
    start_time = datetime.now()
    
    command2 = "nice -n {} cat 1g.img | nice -n {} bzip2 -c > /dev/null".format(nice2,nice2)
    result2 = subprocess.check_output(command2, shell=True)
    
    time2=datetime.now() - start_time
    
    header = ['Command', 'Time']

    commands = [command1,command2]
    all_done = threads_conn(run_command, commands)
    print("\nParallel mode:")
    print(tabulate(all_done, headers=header))
    print("\nSequence mode:")
    sequence_result=[[command1, time1],[command2, time2]]
    print(tabulate(sequence_result))
#    print(u"Time for command in one-by-one mode - with {} nice: {}".format(nice1, time1))
#    print(u"Time for command  in one-by-one mode - with {} nice: {}".format(nice2, time2))