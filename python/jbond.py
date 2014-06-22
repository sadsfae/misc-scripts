#!/usr/bin/env python
# simple insert and indexing for list of james bond

bondlist = ['craig', 'connery', 'moore']
print 'James Bond actors in order of coolness are:', bondlist[:]
 
choice = raw_input("Add your bond: ")
 
def bond(bondlist):
    bondlist.insert(0, choice)
    print "New list of bonds is", bondlist
    bondlist.reverse()
    print ".. in order of least cool to coolest is", bondlist
    return bondlist

def main():
    return bond(bondlist)

if __name__ == '__main__':
    main()
