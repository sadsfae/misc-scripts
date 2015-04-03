#!/usr/bin/python
# find duplicate files and execute operations against them
# credit goes to @ashcrow

import os, sys, md5, getopt


def file_walker(tbl, srcpath, files):
    """
    Visit a path and collect data (including checksum) for files in it.
    """
    for file in files:
	filepath = os.path.join(srcpath, file)
	if os.path.isfile(filepath):
	    chksum = md5.new(open(os.path.join(srcpath, file)).read()).digest()
	    if not tbl.has_key(chksum): tbl[chksum]=[]
	    tbl[chksum].append(filepath)
	
def find_duplicates(treeroot, tbl=None):
    """
    Find duplicate files in a directory.
    """
    dup = {}
    if tbl is None: tbl = {}
    os.path.walk(treeroot, file_walker, tbl)
    for k,v in tbl.items():
	if len(v) > 1:
	    dup[k] = v
    return dup

usage = """
 USAGE: find_duplicates <options> [<path ...]

 Find duplicate files (by matching md5 checksums) in a
 collection of paths (defaults to the current directory).
 
 Note that the order of the paths searched will be retained
 in the resulting duplicate file lists. This can be used
 with --exec and --index to automate handling.

 Options:
   -h, -H, --help
	Print this help.
	
   -q, --quiet
	Don't print normal report.
	
   -x, --exec=<command string>
	Python-formatted command string to act on the indexed
	duplicate in each duplicate group found.  E.g. try
	--exec="ls %s"

   -n, --index=<index into duplicates>
	Which in a series of duplicates to use. Begins with '1'.
	Default is '1' (i.e. the first file listed).

  Example:
    You've copied many files from path ./A into path ./B. You want
    to delete all the ones you've processed already, but not
    delete anything else:

    % find_duplicates -q --exec="rm %s" --index=1 ./A ./B
"""

def main():
    action = None
    quiet  = 0
    index  = 1
    dup    = {}

    opts, args = getopt.getopt(sys.argv[1:], 'qhHn:x:', 
    	['quiet', 'help', 'exec=', 'index='])

    for opt, val in opts:
	if   opt in ('-h', '-H', '--help'):
	    print usage
	    sys.exit()
	elif opt in ('-x', '--exec'):
	    action = str(val)
	elif opt in ('-n', '--index'):
	    index  = int(val)
	elif opt in ('-q', '--quiet'):
	    quiet = 1
	    
    if len(args)==0:
	dup = find_duplicates('.')
    else:
	tbl = {}
	for arg in args:
	    dup = find_duplicates(arg, tbl=tbl)

    for k, v in dup.items():
	if not quiet:
	    print "Duplicates:"
	    for f in v: print "\t%s" % f
	if action:
	    os.system(action % v[index-1])

if __name__=='__main__':
    main()
