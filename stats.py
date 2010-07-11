#!/usr/bin/env python

import sys
import numpy.numarray.mlab as m

vals = []
for l in sys.stdin:
	l = l.strip()
	if l:
		vals.append(float(l))
print '%s,%s,%s,%s' % (min(vals), m.mean(vals), max(vals), m.std(vals))

