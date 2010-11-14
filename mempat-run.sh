#!/bin/sh

args_voronoi="-n 30000"
args_sbtree="16"
args_split="micro/bible.txt 2"
args_em3d="-n 4000 -d 300 -i 74"
args_bh="-b 4000"
# Using up to -c 1048575 takes ~2.5s (and uses ~256KiB),
# using -c 1048576 takes ~9s (and uses ~512KiB)
args_tsp="-c 1000000"
# Same as tsp but the limit is between 209000 and 2100000,
# the memory usage and time doubles (from ~3s/~128KiB to ~6s/256KiB)
args_bisort="-s 2000000"

tango_files=`find ../tango/tango -name '*.d' -o -name '*.di' | grep -v invariant`
args_dil="ddoc /tmp/tangodoc -hl --kandil -version=Tango -version=TangoDoc"
args_dil="$args_dil -version=Posix -version=linux $tango_files"

NAMES=${NAMES:-`echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil}

gc=cdgc

mkdir -p ./build/$gc/mempat

make -srj4 micro-gc-build dil-gc-build
for name in $NAMES
do
	prog="./build/$gc/bin/$name"
	log="/tmp/$name.malloc.csv"
	dst_txt="./build/$gc/mempat/$name.txt"
	dst_tsv="./build/$gc/mempat/$name.tsv"
	eval "args=\"\$args_$name\""
	pa="$args"
	test ${#args} -gt 40 &&
		pa="`echo $args | cut -b1-40`..."
	echo -n "   RUN     $name $pa"
	D_GC_OPTS=malloc_stats_file=$log $prog $args > /dev/null
	echo
	echo -n "   MEMPAT  $dst_txt"
	./mempat.py $log > $dst_txt
	echo
	echo -n "   MEMPAT  $dst_tsv"
	./mempat-tsv.py $log > $dst_tsv
	echo
done

