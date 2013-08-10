#!/usr/bin/env python
#-*- coding: iso-8859-15 -*-
# simple script to convert Czech and US currency
# I don't like having to hit a website for this
# This may turn into a better flask app later (with all currencies via API)
# For now let's just smash it with a hammer
# 1 czk = .051 USD
# 1 USD = 19.30 czk

import os
import sys

# get the type of currency to convert
conversion = str(raw_input("Enter USD or CZK to convert\n"))
os.system('clear')

# warn on wrong currency input then exit
if conversion not in ('USD', 'CZK'):
	print ("wrong input, pick USD or CZK")

if conversion not in ('USD', 'CZK'):
	sys.exit(1)

# get the amount to convert
amount = float(raw_input("Enter amount to convert\n"))

# current conversion rate
def cztousd():
    "convert czk to usd"
    return amount * 0.051

def usdtoczk():
    "convert usd to czk"
    return amount * 19.57

# use the current exchange rate
convertedusd = cztousd()
convertedczk = usdtoczk()

# print our results
if conversion == 'USD':
	print convertedusd
if conversion == 'CZK':
	print convertedczk
