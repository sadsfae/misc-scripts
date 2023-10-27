# /usr/bin/env/python

from random import seed
from random import randint
# seed random number generator
seed(1)
# generate some integers
for _ in range(2):
 value = randint(2, 66)
 print(value)
