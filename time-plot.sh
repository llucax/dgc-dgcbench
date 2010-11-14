#!/bin/sh

test -n "$1" && fmt=$1 && shift
test -n "$1" && output=$1 && shift

files="$@"
test -z "$files" && files=build/time-*-${CPUS}cpu.csv
for f in $files
do
	p=`echo $f | sed "s,.*build/time-\\(.*\\)-${CPUS}cpu\\.csv,\\1,"`
	progs="$progs$p='$f',"
done

./templite.py "fmt='$fmt', output='$output', title='Run Time ($N runs)', cpus=$CPUS,
			progs=dict($progs)" \
		< histogram-plot.tpl.gpi | gnuplot

