#!/usr/bin/env python
# silly, basic animal game for 6year olds 

import sys

# list of animals from which to choose
animals = ['giraffe', 'tiger', 'dragon']

# prompt for choice
print 'Current Animals are: ' + animals[0], animals[1], animals[2]
animal_choice = raw_input("Pick an animal ")

# convert the input to lower case
animal_choice = str.lower(animal_choice)

def AnnounceAnimals(animal_choice):
    if animal_choice == animals[0]:
        print 'You did not pick the', animals[1], 'or the', animals[2]
        noise = 'beemeeeeeeggfffg'
    elif animal_choice == animals[1]:
        print 'You did not pick the', animals[0], 'or the', animals[2]
        noise = 'Roaaaaarrrrrrrrrrr'
    elif animal_choice == animals[2]:
        print 'You did not pick the', animals[1], 'or the', animals[0]
        noise = 'RAARHJGHHGHGHARHARHGHAGHRHRRF!!!!!.. RUN FOR IT!!'
    elif animal_choice != animals[1] or animals[0] or animals[2]:
        print "%s is not a valid choice" % (animal_choice)
        print "You have chosen... poorly"
        sys.exit(1)
    print 'There are many like it but this one is yours, the', animal_choice
    print 'The %s goes %s' % (animal_choice,noise)
    print 'The first two letters are..', animal_choice[0], 'and', animal_choice[1]
    print 'The word %s has %d letters!' % (animal_choice,len(animal_choice))
    return animal_choice

def main():
    return AnnounceAnimals(animal_choice)

if __name__ == '__main__':
    main()
