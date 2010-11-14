#!/bin/sh
set -e

export CPUS="$1"
shift

cpu_list=`seq 0 $(($CPUS-1))`

bye() {
	for n in $cpu_list
	do
		cpufreq-set -c $n -g ondemand
	done
}

trap bye EXIT
trap bye INT

for n in $cpu_list
do
	cpufreq-set -c $n -g performance
done

nice -n-19 ionice -c 1 taskset -c `echo $cpu_list | tr ' ' ,` "$@"

