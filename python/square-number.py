#!/usr/bin/env python
# 6yr old math, find square root of a number
# usage: ./square-number $number

import sys
from sys import argv

# catch error if no input entered
if len(argv) > 1:
    print "processing.."
else:
    print "you need to enter a number bud"
    sys.exit()

# capture input as our number
n = argv[1]
# turn our number into an integer
n = int(n)

# lifting the math
def square(n):
    """Returns the square of a number."""
    squared = n ** 2
    print "%d squared is %d." % (n, squared)
    return squared

square(n)
