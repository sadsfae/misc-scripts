#!/usr/bin/env python
#-*- coding: iso-8859-15 -*-
# simple script to convert Farenheit to Celcius
# I'm lazy and haven't learned metric system yet.
# 1°F = 0.556°C
# 1°C = 1.8°F
# °F to °C 	Deduct 32, then multiply by 5, then divide by 9
# °C to °F 	Multiply by 9, then divide by 5, then add 32

import os
import sys

# prompt for temperature type
temptype = str(raw_input("Enter C or F:\n"))
os.system('clear')

# warn on wrong temperature type
if temptype not in ('C', 'F'):
	print ("wrong format, specify C or F")

if temptype not in ('C', 'F'):
	sys.exit(1)

# prompt for temperature to convert
temp = float(raw_input("Enter the Temperature to Convert:\n"))

# convert Celcius to Farenheit
def C2F():
    "convert celcius to farenheit"
    return (temp * 9.0) / 5.0 + 32

# convert Farenheit to Celcius
def F2C():
    "convert farenheit to celcius"
    return (temp - 32) * 5.0 / 9.0

# define and print results
convertC2F = C2F()
convertF2C = F2C()

if temptype == 'C':
	print convertC2F
if temptype == 'F':
	print convertF2C
