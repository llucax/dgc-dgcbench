
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
args_conalloc="40 4 micro/bible.txt"
args_concpu="40 4 micro/bible.txt"

tango_files=`find ../tango/tango -name '*.d' -o -name '*.di' | grep -v invariant`
args_dil="ddoc /tmp/tangodoc -hl --kandil -version=Tango -version=TangoDoc"
args_dil="$args_dil -version=Posix -version=linux $tango_files"
factor_dil=0.1

