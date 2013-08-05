#!/usr/bin/env python
# very simple script to compare the hour of the day
# if it's during normal working hours a certain co-worker is a jerk

import time;

# If it's before 17:00 XXXXXX is a jerk!
def jerktime():
	return int(time.localtime().tm_hour)

print "the hour is %s" % jerktime() 

if jerktime() < 17:
	print 'so XXXXXXX is most likely going to be a jerk'

if jerktime() > 17:
	print 'so XXXXXXX is OK'
