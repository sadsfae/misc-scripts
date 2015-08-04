#!/usr/bin/env python
# prune the VM-created entries from DHCP leases file
# all of our permant dhcp lease will be FQDN, so we'll prune all
# entries that start with a 10.1 ip scheme.
# purpose: in our R&D environments the amount of temporary VM DHCP 
# reservations cripples Foreman Proxy over time.

import fileinput
import shutil
import time
import subprocess

# first, stop dhcpd temporarily
from subprocess import call
call(["service", "dhcpd", "stop"])

timestamp = str(time.localtime().tm_year) + str(time.localtime().tm_mon) \
        + str(time.localtime().tm_mday) + str(time.localtime().tm_hour) \
        + str(time.localtime().tm_min)

# backup existing dhcpd.leases file
shutil.copy2('/var/lib/dhcpd/dhcpd.leases', '/var/lib/dhcpd/dhcpd.leases-' + timestamp)

# in-place edit dhcpd.leases
ignore = False
for line in fileinput.input('/var/lib/dhcpd/dhcpd.leases', inplace=True):
    if not ignore:
        if line.startswith('lease 10.1.'):
            ignore = True
        else:
            print line,
    if ignore and line.isspace():
        ignore = False

# start dhcpd back up again
from subprocess import call
call(["service", "dhcpd", "start"])

# bounce foreman-proxy for good measure
from subprocess import call
call(["service", "foreman-proxy", "restart"])
