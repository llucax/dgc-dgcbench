#!/bin/sh

echo -n "ddoc /tmp/tangodoc -hl --kandil -version=Tango -version=TangoDoc -version=Posix -version=linux "
files=`find ../tango/tango -name '*.d' -o -name '*.di' | grep -v invariant`
test -n "$1" &&
	files=`echo $files | cut -d' ' -f1-$1`
echo $files

