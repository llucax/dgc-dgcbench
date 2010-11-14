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

def p(msg, *args):
	print msg % args

def num(n):
	sn = str(n)
	c = len(sn)
	if c <= 3:
		return sn
	sep_pos = reversed(range(c-3, 0, -3))
	return ','.join([sn[:c%3 or 3]] + [str(sn[i:i+3]) for i in sep_pos])

def rm0(n):
	s = '%.02f' % n
	if s.endswith('00'):
		return s[:-3]
	if s.endswith('0'):
		return s[:-1]
	return s

def percent(n, total):
	return rm0(float(n) / total * 100) + '%'

def bytes(n):
	for mult in sorted(bytes_suffix.keys(), reverse=True):
		if n >= mult:
			return '%s bytes [%s%s]' % (num(n),
					rm0(float(n) / mult),
					bytes_suffix[mult])
	return '%s bytes' % n

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

p('Total requested: %s objecs, %s', num(total_c), bytes(total_b))
p('\tScanned: %s (%s) objecs, %s (%s)', num(scan_c), percent(scan_c, total_c),
		bytes(scan_b), percent(scan_b, total_b))
p('\tNot scanned: %s (%s) objecs, %s (%s)', num(no_scan_c),
		percent(no_scan_c, total_c), bytes(no_scan_b),
		percent(no_scan_b, total_b))

different_sizes_c = len(set(size_freq.keys()).union(size_freq_ti.keys()))
p('Different object sizes: %s', num(different_sizes_c))

p('Objects requested with a bin size of:')
alloc_c = dict()
n = sum((freq for size, freq in size_freq.iteritems() if size <= bins[0]))
n += sum((freq for size, freq in size_freq_ti.iteritems() if size <= bins[0]))
b = sum((size*freq for size, freq in size_freq.iteritems() if size <= bins[0]))
b += sum((size*freq for size, freq in size_freq_ti.iteritems()
		if size <= bins[0]))
alloc_c[bins[0]] = n
if n:
	p('\t%s bytes: %s (%s) objects, %s (%s)', bins[0], num(n),
			percent(n, total_c), bytes(b), percent(b, total_b))
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
	if nn:
		p('\t%s bytes: %s (%s, %s cumulative) objects, '
				'%s (%s, %s cumulative)', bin, num(nn),
				percent(nn, total_c), percent(n, total_c),
				bytes(bb), percent(bb, total_b),
				percent(b, total_b))
		n_prev = n
		b_prev = b
n = sum((freq for size, freq in size_freq.iteritems() if size > 4096))
n += sum((freq for size, freq in size_freq_ti.iteritems() if size > 4096))
b = sum((size*freq for size, freq in size_freq.iteritems() if size > 4096))
b += sum((size*freq for size, freq in size_freq_ti.iteritems() if size > 4096))
alloc_pplus_c = n
if n:
	p('\tmore than a page: %s (%s) objects, %s (%s)', num(n),
			percent(n, total_c), bytes(b), percent(b, total_b))

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
	alloc_total = wasted_total + total_b
	p('%s mode:', mode)
	p('\tTotal allocated: %s', bytes(alloc_total))
	p('\tTotal wasted: %s, %s', bytes(wasted_total), percent(wasted_total,
			alloc_total))
	p('\tWasted due to objects that should use a bin of:')
	if alloc_c[bins[0]]:
		p('\t  %s bytes: %s (%s)', bins[0], bytes(wasted[bins[0]]),
				percent(wasted[bins[0]], wasted_total))
	w_cumulative = wasted[bins[0]]
	for bin in bins[1:]:
		if wasted[bin] == 0 and alloc_c[bin] == 0:
			continue
		w_cumulative += wasted[bin]
		p('\t  %s bytes: %s (%s, %s cumulative)', bin,
				bytes(wasted[bin]), percent(wasted[bin],
				wasted_total), percent(w_cumulative,
				wasted_total))
	if alloc_pplus_c:
		p('\t  more than a page: %s (%s)', bytes(wasted_pplus),
				percent(wasted_pplus, wasted_total))

print_wasted('Conservative')
print_wasted('Precise', 4)

#print size_freq, size_freq_ti

