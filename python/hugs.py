#!/usr/bin/env/python
# everybody needs hugs, track it using a dictionary
# simple exercise to use python dictionary

import sys

# create blank dictionary of hug logistics
huglist = {}

# assign people needing hugs as keys
huglist['wizard'] = 5
huglist['panda'] = 1
huglist['koala'] = 2
huglist['tiger'] = 0
huglist['moose'] = 3
huglist['gorbachev'] = 4

# print initial hug list with urgency

def HugList():
    print "People who need Hugs and How Bad!!"
    for needhuggers in huglist:
        print (needhuggers, huglist[needhuggers])

HugList()

# add another thing to hug, with urgency rating
addhug = raw_input("Add another thing needing hugs: ")

# add it's hug urgency
addhugrating = raw_input("What is it's hug rating? 0-5: ")
addhugrating = int(addhugrating)

def HugAddList():
    if 0 <= addhugrating <= 5:
        pass
    else:
        print "Hug Rating must be between 0 and 5"
        sys.exit()
    # add the new thing to hug
    huglist[addhug] = addhugrating
    print "We've updated the hug list, get to hugging!"
    print huglist
    # if hug urgency is 5, it needs hugs badly!
    if addhugrating == 5:
        print "---------------------------"
        print "ALERT:: %s needs hug badly!" % (addhug)

def main():
    HugAddList()

if __name__ == '__main__':
    main()
