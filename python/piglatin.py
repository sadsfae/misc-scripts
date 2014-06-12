#!/usr/bin/env python
# pig latin converter for 6year olds

psuffix = 'ay'

# capture input
original = raw_input('Enter a word to change to pig latin: ')

# check input, then convert/swap the order
if len(original) > 0 and original.isalpha():
    word = original.lower()
    first = word[0]
    new_word = word[1:] + first + psuffix
    print new_word
else:
    print 'you didn\'t enter correct input'
