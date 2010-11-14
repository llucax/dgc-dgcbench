#!/bin/sh

. ./tests-args.sh


TIME=${TIME:-/usr/bin/time}

FORMATS=${FORMATS:-png svg eps}

NAMES=${NAMES:-`echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil}

GCS=${GCS:-basic cdgc-conservative=1:fork=0:early_collect=0:eager_alloc=0}

CPUS=${CPUS:-`grep '^processor' /proc/cpuinfo | wc -l`}

PLOTONLY=${PLOTONLY:-0}

NORUN=${NORUN:-}

STRIP=${STRIP:-1}

ARCH=${ARCH:-}


for CPUS in 1 2 4; do
for name in $NAMES
do
	dst=./results/to-plot/collect-stw-$name-${CPUS}cpu.csv
	#if test -f $dst
	#then
	#	echo "$NORUN" | grep -q "$name" &&
	#		continue
	#	test $PLOTONLY -eq 1 &&
	#		continue
	#	mv $dst ./build/time-$name-${CPUS}cpu-old.csv
	#fi
	echo -n > $dst
	#for gc in basic \
	for gc in \
			cdgc-conservative=1:fork=0:early_collect=0:eager_alloc=0 \
			cdgc-conservative=0:fork=0:early_collect=0:eager_alloc=0 \
			cdgc-conservative=0:fork=1:early_collect=0:eager_alloc=0 \
			cdgc-conservative=0:fork=1:early_collect=1:eager_alloc=0 \
			cdgc-conservative=0:fork=1:early_collect=0:eager_alloc=1 \
			cdgc-conservative=0:fork=1:early_collect=1:eager_alloc=1
	do
		eval "factor=\"\$factor_$name\""
		test -z "$factor" &&
			factor=1
		[ "$gc" = "basic" ] && pgc="tbgc"
		[ "$gc" = "cdgc-conservative=1:fork=0:early_collect=0:eager_alloc=0" ] && pgc="cons"
		[ "$gc" = "cdgc-conservative=0:fork=0:early_collect=0:eager_alloc=0" ] && pgc="prec"
		[ "$gc" = "cdgc-conservative=0:fork=1:early_collect=0:eager_alloc=0" ] && pgc="fork"
		[ "$gc" = "cdgc-conservative=0:fork=1:early_collect=1:eager_alloc=0" ] && pgc="ecol"
		[ "$gc" = "cdgc-conservative=0:fork=1:early_collect=0:eager_alloc=1" ] && pgc="eall"
		[ "$gc" = "cdgc-conservative=0:fork=1:early_collect=1:eager_alloc=1" ] && pgc="todo"
		echo -n "   STATS $name-$gc"
		echo -n "$pgc," >> $dst
		(
			for f in results/raw-collect/collect-$name-$gc-${CPUS}cpu-*.csv;
			do
				grep -v -- -1 "$f" | ./stats.py '$4' '%(max)f';
				#echo $((`grep -v -- -1 "$f" | wc -l`-1))
			done
		) | ./stats.py >> $dst
		echo " (`tail -n1 $dst | tr , ' '`) >> $dst"
	done
done
done

