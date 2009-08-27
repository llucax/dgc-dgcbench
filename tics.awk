#!/usr/bin/env awk -F, -f

BEGIN {
	ORS = "" # don't use a \n after each print
	print "'' 0"
}

NR > 1 { # skip the input CVS header
	print ", '" $1 "' " (NR-2)
}

