#!/bin/sh

. ./tests-args.sh


export N=${N:-20}

TIME=${TIME:-/usr/bin/time}

FORMATS=${FORMATS:-png svg eps}

NAMES=${NAMES:-`echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil}

CPUS=${CPUS:-`grep '^processor' /proc/cpuinfo | wc -l`}

PLOTONLY=${PLOTONLY:-0}

NORUN=${NORUN:-}

STRIP=${STRIP:-1}

ARCH=${ARCH:-}

stats_file=/tmp/stats.csv

#for opts in basic \
#for opts in \
#		conservative=1:fork=0:early_collect=0:eager_alloc=0 \
#		conservative=0:fork=0:early_collect=0:eager_alloc=0 \
#		conservative=0:fork=1:early_collect=0:eager_alloc=0 \
#		conservative=0:fork=1:early_collect=1:eager_alloc=0 \
#		conservative=0:fork=1:early_collect=0:eager_alloc=1 \
#		conservative=0:fork=1:early_collect=1:eager_alloc=1
for min_free in 0 5 10 15 20 25 30 35 40 45 50
do
	gc=cdgc
	if [ "$opts" = "basic" ]
	then
		gc=basic
		opts=""
	else
		export D_GC_OPTS="min_free=$min_free" #:collect_stats_file=$stats_file"
		opts="-min_free=$min_free"
	fi
	#make -srj4 micro-gc-build dil-gc-build GC=$gc
	for name in $NAMES
	do
		prog="./build/$gc/bin/$name"
		dst="./results/min_free-timemem-$name-$gc${opts}-${CPUS}cpu"
		dst="$dst.csv"
		eval "args=\"\$args_$name\""
		pa="$args"
		test ${#args} -gt 40 &&
			pa="`echo $args | cut -b1-40`..."
		test $STRIP -eq 1 &&
			strip $prog
		echo -n "   RUN   $name $pa > $dst: "
		echo "Run time (sec),Memory usage (KiB)" > $dst
		for i in `seq $N`
		do
			test $(($i % 5)) -eq 0 &&
				echo -n "$i" ||
				echo -n "."
			setarch i386 $ARCH \
				$TIME -f'%e,%M' -a -o $dst \
				$prog $args > /dev/null
			#mv $stats_file $dst-$i.csv
		done
		echo
	done
done

