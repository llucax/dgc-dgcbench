#!/usr/bin/env python

import re
import sys
import numpy.numarray.mlab as m

exp = '$1'
fmt = '%(min)s,%(mean)s,%(max)s,%(std)s'
sep = ','

try:
	exp = sys.argv[1]
	fmt = sys.argv[2]
	sep = sys.argv[3]
except:
	pass

vals = []
for n, l in enumerate(sys.stdin):
	l = l.strip()
	if not l:
		continue
	try:
		fields = dict([('$'+str(int(k)+1), float(v.strip()))
				for k, v in enumerate(l.split(sep))])
		v = float(eval(re.sub(r'(\$\d+)', r'%(\1)f', exp) % fields))
	except:
		if n == 0:
			continue
		raise
	vals.append(v)
vars = dict(min=min(vals), mean=m.mean(vals), max=max(vals), std=m.std(vals))
print fmt % vars

