#!/bin/sh
cpus="1 2 4"
test -n "$1" && cpus="$@"
for c in $cpus
do
	./bench.sh $c ./time-run.sh
	./bench.sh $c ./pause-run.sh
done

