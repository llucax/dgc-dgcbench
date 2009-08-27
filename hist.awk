#!/usr/bin/env awk -F, -f

BEGIN {
	MAX_SAMPLES = 50
	# output CSV header
	print "Size,Scan,No Scan";
}

NR == 2 {
	min = max = int($3)
}

NR > 1 { # skip the input CVS header
	n = int($3)
	if (int($6) > 0) { # cell has the NO_SCAN bit
		no_scan[n]++
		if (!(n in scan))
			scan[n] = 0
	} else { # cell doesn't have the NO_SCAN bit
		scan[n]++
		if (!(n in no_scan))
			no_scan[n] = 0
	}
	if (n < min)
		min = n
	else if (n > max)
		max = n
}

function h(val) {
	if (val >= 1048576) # 1 M
		r = sprintf("%uM", val / 1048576)
	else if (val >= 1024) # 1 K
		r = sprintf("%uK", val / 1024)
	else
		r = sprintf("%u", val)
	return r
}

function p(s, ns, o, n) {
	for (i = 1; i <= n; i++)
		print o[i] "," s[o[i]] "," ns[o[i]]
}

END {
	# reduce the number of elements in the histogram if there are too many
	if (length(scan) > MAX_SAMPLES) {
		step = int((max - min) / MAX_SAMPLES) + 1
		for (i in scan) {
			i = int(i)
			for (from = min; from < max; from += step) {
				to = from + step
				if ((from <= i) && (i < to)) {
					j = sprintf("%s-%s", h(from), h(to))
					scan2[j] += scan[i]
					no_scan2[j] += no_scan[i]
					break
				}
			}
		}
		n = 1
		for (from = min; from < max; from += step) {
			v = sprintf("%s-%s", h(from), h(from + step))
			if (v in scan2)
				order[n++] = v
		}
	}
	# print output data
	if (length(scan2)) {
		p(scan2, no_scan2, order, n)
	} else {
		for (i in scan)
			order[i++] = int(i)
		n = asort(order)
		p(scan, no_scan, order, n)
	}
}

