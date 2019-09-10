#!/usr/bin/env python3
# simple dice rolling program
# picks a random number between a start and end range
# picks 0 1000 if range is not given

import random
import sys

# sanitize input
if len(sys.argv) > 1 and str.isdigit(sys.argv[1]) is False:
    print("You must enter integers for starting range")
    exit(1)
elif len(sys.argv) > 1 and str.isdigit(sys.argv[2]) is False:
    print("You must enter integers for end range")
    exit(1)

# assign start and end range if given
if len(sys.argv) == 3:
    startrange = sys.argv[1]
    endrange = sys.argv[2]

# assume range of 0 / 1000 if not given
if len(sys.argv) <= 1:
    startrange = '0'
    endrange = '1000'


def diceroll(startrange, endrange):
    rollrange = random.randint(int(startrange), int(endrange))
    rollresult = ("A magic die has been rolled between {} and {},"
                  "you rolled {} " .format(startrange, endrange, rollrange))
    print(rollresult)


diceroll(startrange, endrange)
