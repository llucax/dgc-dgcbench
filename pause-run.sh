#!/bin/sh

. ./tests-args.sh
factor_rnddata=0.1


FORMATS=${FORMATS:-png svg eps}

NAMES=${NAMES:-`echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil}

TYPES=${TYPES:-stw fork ea}

CPUS=${CPUS:-`grep '^processor' /proc/cpuinfo | wc -l`}

PLOTONLY=${PLOTONLY:-0}

NORUN=${NORUN:-}

STRIP=${STRIP:-1}

ARCH=${ARCH:-}


run() {
	name=$1
	type=$2
	prog=$3
	eval "args=\"\$args_$name\""
	if test $type = "warm"
	then
		echo "   WARM  $name"
		$prog $args > /dev/null
		return 0
	fi
	dst="./build/cdgc/pause/$name-$type-${CPUS}cpu.csv"
	if test -f $dst
	then
		echo "$NORUN" | grep -q "cdgc\\|$name" &&
			continue
		test $PLOTONLY -eq 1 &&
			continue
	fi
	gc_opts=
	test $type = "stw" && gc_opts="fork=0"
	test $type = "fork" && gc_opts="eager_alloc=0"
	test $type = "ea" && gc_opts=""
	pa="$args"
	test ${#args} -gt 40 &&
		pa="`echo $args | cut -b1-40`..."
	echo "   RUN   $name $pa > $dst"
	D_GC_OPTS="$D_GC_OPTS:collect_stats_file=$dst:$gc_opts" \
			setarch i386 $ARCH $prog $args > /dev/null
}


make -srj4 micro-gc-build dil-gc-build GC=cdgc

for name in $NAMES
do
	prog="./build/cdgc/bin/$name"
	test $STRIP -eq 1 &&
		strip $prog
	for type in warm $TYPES
	do
		run $name $type $prog
	done
done

for name in $NAMES
do
	for time in stw pause
	do
		dst=./build/$time-$name-${CPUS}cpu.csv
		if test -f $dst
		then
			echo "$NORUN" | grep -q "$name" &&
				continue
			test $PLOTONLY -eq 1 &&
				continue
			mv $dst ./build/$time-$name-${CPUS}cpu-old.csv
		fi
		col=4 # Stop-the-world data column
		test $time = "pause" && col=2 # Total pause data column
		echo -n > $dst
		for type in $TYPES
		do
			src="./build/cdgc/pause/$name-$type-${CPUS}cpu.csv"
			eval "factor=\"\$factor_$name\""
			test -z "$factor" &&
				factor=1
			(echo -n $type,; awk -F, \
					"{if (FNR > 1 && \$$col > 0)
						print \$$col*$factor}" $src \
				| ./stats.py) >> $dst
			echo "   STATS `tail -n1 $dst | tr , ' '` >> $dst"
		done
	done
done

for time in stw pause
do
	echo -n "   PLOT  $time ${CPUS}cpu > ./build/$time-${CPUS}cpu.{"
	for fmt in $FORMATS
	do
		dst=./build/$time-${CPUS}cpu.$fmt
		test -f $dst &&
			mv $dst ./build/$time-${CPUS}cpu-old.$fmt
		echo -n "$fmt,"
		files=''
		for name in $NAMES
		do
			files="$files ./build/$time-$name-${CPUS}cpu.csv"
		done
		test $time = "stw" && title="Stop-the-world Time"
		test $time = "pause" && title="Pause Time"
		./pause-plot.sh "$title" $fmt $dst $files
	done
	echo '}'
done

