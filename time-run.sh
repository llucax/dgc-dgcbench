#!/bin/sh

. ./tests-args.sh


export N=${N:-3}

TIME=${TIME:-/usr/bin/time}

FORMATS=${FORMATS:-png svg eps}

NAMES=${NAMES:-`echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil}

GCS=${GCS:-basic cdgc}

CPUS=${CPUS:-`grep '^processor' /proc/cpuinfo | wc -l`}

PLOTONLY=${PLOTONLY:-0}

NORUN=${NORUN:-}

STRIP=${STRIP:-1}

ARCH=${ARCH:-}


for gc in $GCS
do
	make -srj4 micro-gc-build dil-gc-build GC=$gc
	for name in $NAMES
	do
		prog="./build/$gc/bin/$name"
		dst="./build/$gc/time/$name-${CPUS}cpu.csv"
		if test -f $dst
		then
			echo "$NORUN" | grep -q "$gc\\|$name" &&
				continue
			test $PLOTONLY -eq 1 &&
				continue
		fi
		eval "args=\"\$args_$name\""
		pa="$args"
		test ${#args} -gt 40 &&
			pa="`echo $args | cut -b1-40`..."
		test $STRIP -eq 1 &&
			strip $prog
		echo -n "   RUN   $name $pa > $dst: "
		echo -n > $dst
		for i in `seq $N`
		do
			test $(($i % 5)) -eq 0 &&
				echo -n "$i" ||
				echo -n "."
			setarch i386 $ARCH \
				$TIME -f%e -a -o $dst \
				$prog $args > /dev/null
		done
		echo
	done
done

for name in $NAMES
do
	dst=./build/time-$name-${CPUS}cpu.csv
	if test -f $dst
	then
		echo "$NORUN" | grep -q "$name" &&
			continue
		test $PLOTONLY -eq 1 &&
			continue
		mv $dst ./build/time-$name-${CPUS}cpu-old.csv
	fi
	echo -n > $dst
	for gc in $GCS
	do
		src=./build/$gc/time/$name-${CPUS}cpu.csv
		eval "factor=\"\$factor_$name\""
		test -z "$factor" &&
			factor=1
		(echo -n $gc,; awk "{print \$1*$factor}" $src | ./stats.py) >> $dst
		echo "   STATS `tail -n1 $dst | tr , ' '` >> $dst"
	done
done

echo -n "   PLOT  ${CPUS}cpu > ./build/time-${CPUS}cpu.{"
for fmt in $FORMATS
do
	dst=./build/time-${CPUS}cpu.$fmt
	test -f $dst &&
		mv $dst ./build/time-${CPUS}cpu-old.$fmt
	echo -n "$fmt,"
	files=''
	for name in $NAMES
	do
		files="$files ./build/time-$name-${CPUS}cpu.csv"
	done
	./time-plot.sh $fmt $dst $files
done
echo '}'

