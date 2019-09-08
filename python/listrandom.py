#!/usr/bin/env python3
# silly exercise that does nothing useful
# this is a learning exercise to build on equally useless things.

import os
import random

banner = "===================="
print(banner)
print("Welcome to File Picker 3000\n")
fileloc = str(input("Type location to pick random files\n"))
filecount = int(input("How many random picks do you want?\n"))
print(banner)

def picker(n):
    wordguy = os.listdir(fileloc)
    for i in range(0,n):
        print(i,random.choice(wordguy))

picker(filecount)
