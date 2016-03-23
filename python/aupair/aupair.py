#!/usr/bin/env python
# sort through an external text file as a list
# generate every possible combination of pairs

# load list of pairs, remove newline character with stripr
pairs = [line.strip() for line in open("pairlist.txt", 'r')]

# generate all possible combinations pairs
# avoid dupes, treat (p1,p2) and (p2,p1) as the same
def gen_pairs(lst):
    if len(lst) < 2:
        yield lst
        return
    a = lst[0]
    for i in range(1,len(lst)):
        pair = (a,lst[i])
        for rest in gen_pairs(lst[1:i]+lst[i+1:]):
            yield [pair] + rest

for x in gen_pairs(pairs): 
    print x
