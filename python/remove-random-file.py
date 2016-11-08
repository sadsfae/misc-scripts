#!/usr/bin/env python
# removes a random file from a directory
# change the path variable to unleash choas

import random
import os

path = '/tmp/test'

def randDelete(path):
    files = os.listdir(path)
    index = random.randrange(0, len(files))
    return files[index]
randDelete(path)

filechoose = randDelete(path)
print "I will delete %s/%s from the system" % (path,filechoose)
filetodestroy = '%s/%s' % (path,filechoose)
os.remove(filetodestroy)
