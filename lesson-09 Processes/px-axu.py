#!/usr/bin/env python

import subprocess
import re
import sys
from tabulate import tabulate

def get_cmdline(pid):
    command = "cat /proc/{}/cmdline".format(pid)
    result = subprocess.check_output(command, shell=True)
    return result

def get_status(pid, field):
    dict1={}
    regex = '(.*):(.*)'
    command = "cat /proc/{}/status".format(pid)
    result = subprocess.check_output(command, shell=True)
    match = re.findall(regex, result)
    for i in match:
        if i[0]==field:
            #dict1[i[0]]=
            return i[1].strip()
        else:
            pass
    #name = match.group(1)
    #value = match.group(2)

def get_all_pids():
    pid_list=[]
    regex = "\d*"
    command = "ls /proc/"
    result = subprocess.check_output(command, shell=True)
    match = re.findall(regex, result)
    for i in match:
        if i.isdigit():
            pid_list.append(i)
    return pid_list

def get_from_stat(pid, *args):
    command = "cat /proc/{}/stat".format(pid)
    result = subprocess.check_output(command, shell=True)
    list_of_stat = result.split()
    list_of_stat_filtered=[]
    for i in args:
    	list_of_stat_filtered.append(list_of_stat[i])
    return list_of_stat_filtered

header=['NAME', 'Pid', 'Status', 'us', 'sy', 'Command']
pid_list=get_all_pids()

try:
	num = int(sys.argv[1])
	print(num,'&')
except:
    num = 10
    print(num,'!')

list_of_list=[]
for pid in pid_list[0:num]:
    #list_of_list.append([get_status(pid,'Name'), get_status(pid,'Pid'), get_status(pid,'State'), get_cmdline(pid)])
    temp_list = [get_status(pid,'Name'), get_status(pid,'Pid'), get_status(pid,'State')]
    temp_list=temp_list + get_from_stat(pid,13,14)
    temp_list.append(get_cmdline(pid))
    list_of_list.append(temp_list)
    list_of_list.sort(key=lambda x: x[4], reverse=True)
    
print(tabulate(list_of_list, headers=header))