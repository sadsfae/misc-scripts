#!/usr/bin/env python3
import random


def PickClass():
    wow_classes = ['warrior', 'mage', 'priest']
    myclass = random.choice(wow_classes)
    print("My random pick is " + myclass)
    if myclass == 'warrior':
        print("It is so, Warrior")
    elif myclass == 'mage':
        print("STINKING MAGIC")
    elif myclass == 'priest':
        print("Well then, priest")
    else:
        print("Darn, go to sleep")
    return


def PickRace():
    races = ['orc', 'ogre']
    for spam in races:
        print("I smell me some", spam)
    badone = random.choice(races)
    print("Well " + badone + " smells the worst of the two..")
    return


PickClass()
PickRace()
