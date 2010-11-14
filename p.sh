#!/bin/sh

for CPUS in 1 2 4; do
	for name in `echo ./micro/*.d | xargs -n1 sh -c 'basename $0 .d'` dil
	do
		dst=../informe/source/plots/mem-$name-${CPUS}cpu.pdf
		src=./results/to-plot/collect-mem-$name-${CPUS}cpu.csv
		echo "   PLOT $dst"
		cp "$src" /tmp/input.csv &&
			gnuplot p.gpi &&
			epstopdf /tmp/output.eps &&
			mv /tmp/output.pdf "$dst"
	done
done

