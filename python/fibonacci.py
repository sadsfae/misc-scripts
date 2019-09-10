#!/usr/bin/env python3
# generate fibonacci sequence
# takes one argument

import sys

if len(sys.argv) <= 1:
    print("You must supply the number of fibonacci iterations to calculate")
    print("e.g. python3 fibonacci.py 10")
    exit(1)
elif str.isdigit(sys.argv[1]) is False:
    print("You must enter an integer value")
    exit(1)

fibcount = sys.argv[1]
fibcount = int(fibcount)


def fib(n):
    a = 0
    b = 1
    print(a)
    print(b)

    for i in range(2, n):
        c = a + b
        a = b
        b = c
        print(c)


fib(fibcount)
