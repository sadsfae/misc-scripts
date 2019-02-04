#!/usr/bin/env python3
# swap your /etc/resolv.conf depending on arguments
# takes one argument, "localhost" or "system"
# mod-resolveconf.py localhost (point everything to localhost)
# mod-resolvconf.py system (revert everything to what DHCP or other sets)
# this is useful for running pi-hole as a local container for your DNS
# https://hobo.house/2018/02/27/block-advertising-with-pi-hole-and-raspberry-pi/

import sys
import shutil

if len(sys.argv[1:]) != 1:
    print ("## Requires 1 argument ##")
    print ("mod-resolveconf.py localhost|system")
    exit(1)

# backup existing /etc/resolv.conf
if sys.argv[1] == "localhost":
    shutil.copy2('/etc/resolv.conf', '/tmp/resolv.conf.system')

# set dns to localhost, or try and revert if backup is present
def main():
    if sys.argv[1] == "localhost":
        dns = 'nameserver localhost\n'
        resolvconf = '/etc/resolv.conf'
        editconflocal = open(resolvconf, 'w')
        editconflocal.write(dns)
        editconflocal.close()
        print ("Updating /etc/resolv.conf to localhost...")
        print ("-----------------")
        with open(resolvconf, 'r') as result:
            shutil.copyfileobj(result, sys.stdout)

    if sys.argv[1] == "system":
        try:
            resolvconf = '/etc/resolv.conf'
            shutil.copy2('/tmp/resolv.conf.system', '/etc/resolv.conf')
            print ("Reverting %s back /tmp/resolv.conf.system ..." % resolvconf)
            print ("-----------------")
            with open(resolvconf, 'r') as result:
                shutil.copyfileobj(result, sys.stdout)
        except IOError:
            print ("No /tmp/resolv.conf.system found, may be running defaults")


if __name__ == '__main__':
    main()
