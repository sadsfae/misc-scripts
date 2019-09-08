#!/usr/bin/env python3
# silly exercise that does nothing useful
# this is a learning exercise to build on equally useless things.

import os
import random
import subprocess

banner = "===================="
print(banner)
print("Welcome to File Picker 3000\n\n")
fileloc = str(input("Type location to pick random files\n\n"))
filecount = int(input("How many random picks do you want?\n\n"))
print(banner)

if filecount >= 1000:
    print("Come on dude chill, pick less than 1000 results")
    exit(1)

if fileloc == "~":
    myuser = subprocess.check_output("whoami", shell=True, stderr=subprocess.STDOUT)
    myuser = myuser.decode('ascii')
    myuser = myuser.strip('\n')
    fileloc = "/home/" + myuser

def picker(n):
    wordguy = os.listdir(fileloc)
    for i in range(0,n):
        print(i,random.choice(wordguy))

picker(filecount)
