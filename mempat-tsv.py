#!/usr/bin/env python

import sys
import numpy

SIZE = 3
NO_SCAN = 6

KiB = 2**10
MiB = 2**20
GiB = 2**30

bytes_suffix = {
	KiB: 'KiB',
	MiB: 'MiB',
	GiB: 'GiB',
}

# 16 32 ... 2048 4096
bins = [1 << n for n in range(4, 13)]

class Info:
	pass

def p(msg='', *args):
	print msg % args

def num(n):
	return str(n)

def percent(n, total):
	return '%f' % (float(n) / total * 100)

def bytes(n):
	return str(n)

f = file(sys.argv[1])
f.readline() # ignore headers

sizes = list()
sizes_ti = list()
size_freq = dict()
size_freq_ti = dict()
for l in f:
	d = l.split(',')
	size = int(d[SIZE])
	no_scan = bool(int(d[NO_SCAN]))
	if no_scan:
		sizes.append(size)
		size_freq[size] = size_freq.get(size, 0) + 1
	else:
		sizes_ti.append(size)
		size_freq_ti[size] = size_freq_ti.get(size, 0) + 1

scan_c = len(sizes_ti)
no_scan_c = len(sizes)
total_c = scan_c + no_scan_c

scan_b = sum(sizes_ti)
no_scan_b = sum(sizes)
total_b = scan_b + no_scan_b

p('Number of objects')
p('Scanned\tNot scanned\tTotal')
p('%s\t%s\t%s', num(scan_c), num(no_scan_c), num(total_c))
p()

p('Bytes')
p('Scanned\tNot scanned\tTotal')
p('%s\t%s\t%s', bytes(scan_b), bytes(no_scan_b), bytes(total_b))
p()

different_sizes_c = len(set(size_freq.keys()).union(size_freq_ti.keys()))
p('Different object sizes')
p(num(different_sizes_c))
p()

p('Objects requested')
p('Bin Size\tNumber\tBytes')
alloc_c = dict()
n = sum((freq for size, freq in size_freq.iteritems() if size <= bins[0]))
n += sum((freq for size, freq in size_freq_ti.iteritems() if size <= bins[0]))
b = sum((size*freq for size, freq in size_freq.iteritems() if size <= bins[0]))
b += sum((size*freq for size, freq in size_freq_ti.iteritems()
		if size <= bins[0]))
alloc_c[bins[0]] = n
p('%s\t%s\t%s', bins[0], num(n), bytes(b))
n_prev = n
b_prev = b
for bin in bins[1:]:
	n = sum((freq for size, freq in size_freq.iteritems() if size <= bin))
	n += sum((freq for size, freq in size_freq_ti.iteritems()
			if size <= bin))
	b = sum((size*freq for size, freq in size_freq.iteritems()
			if size <= bin))
	b += sum((size*freq for size, freq in size_freq_ti.iteritems()
			if size <= bin))
	nn = n - n_prev
	bb = b - b_prev
	alloc_c[bin] = nn
	p('%s\t%s\t%s', bin, num(nn), bytes(bb))
	n_prev = n
	b_prev = b
n = sum((freq for size, freq in size_freq.iteritems() if size > 4096))
n += sum((freq for size, freq in size_freq_ti.iteritems() if size > 4096))
b = sum((size*freq for size, freq in size_freq.iteritems() if size > 4096))
b += sum((size*freq for size, freq in size_freq_ti.iteritems() if size > 4096))
alloc_pplus_c = n
p('>4096\t%s\t%s', num(n), bytes(b))
p()

def wasted_bin(start, end, extra=0):
	w = 0
	for i in range(start, end+1):
		w += (end - i) * size_freq.get(i, 0)
		if i <= (end - extra):
			w += (end - i) * size_freq_ti.get(i, 0)
		elif extra:
			w += (2*end - i) * size_freq_ti.get(i, 0)
	return w

def wasted_pageplus(extra=0):
	w = 0
	for size, freq in size_freq.iteritems():
		if size > 4096:
			w += (size % 4096) * freq
	for size, freq in size_freq_ti.iteritems():
		size += extra
		if size > 4096:
			w += (size % 4096 + extra) * freq
	return w

def print_wasted(mode, extra=0):
	wasted = dict()
	wasted[bins[0]] = wasted_bin(1, bins[0], extra)
	for bin in bins[1:]:
		wasted[bin] = wasted_bin(bin/2 + 1, bin, extra)
	wasted_pplus = wasted_pageplus()
	wasted_total = sum((w for w in wasted.values())) + wasted_pplus
	alloc_total = total_b + wasted_total
	p('Real allocated bytes for mode %s', mode)
	p('Totals')
	p('Requested\tWasted\tTotal')
	p('%s\t%s\t%s', bytes(total_b), bytes(wasted_total), bytes(alloc_total))
	p('Bin\tWasted')
	p('%s\t%s', bins[0], bytes(wasted[bins[0]]))
	for bin in bins[1:]:
		p('%s\t%s', bin, bytes(wasted[bin]))
	p('>4096\t%s', bytes(wasted_pplus))
	p()

print_wasted('Conservative')
print_wasted('Precise', 4)

#print size_freq, size_freq_ti

