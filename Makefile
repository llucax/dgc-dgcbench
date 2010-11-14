
GC       := cdgc
B        := build
O        := $B/$(GC)
DC       := ../dmd/src/dmd
LD       := ../dmd/src/dmd
LN       := ln
TIME     := /usr/bin/time
override DFLAGS ?= -release -inline -O -gc
LDFLAGS  := -defaultlib=tango-$(GC) -debuglib=tango-$(GC)
LIBTANGO := ../lib/libtango-$(GC).a

ifndef V
P      = @
P_DC   = @printf '   DC    %- 40s <-  %s\n' '$@' '$(if \
		$(subst 1,,$(words $^)),$< ... $(lastword $^),$<)';
P_PLOT = @printf '   PLOT  %- 40s <-  %s\n' '$@' '$(notdir $(filter %.csv,$^))';
P_AWK  = @printf '   AWK   %- 40s <-  %s\n' '$@' '$<';
P_RUN  = @printf '   RUN   $< $(args)\n';
P_MAKE = @printf '   MAKE  $@\n';
P_RM   = @printf '   RM    $^\n';
P_LN   = @printf '   LN    %- 40s <-  %s\n' '$@' '$<';
endif

# create build directories if they don't already exist
dummy_mkdir := $(shell mkdir -p $O $O/bin $O/time $O/stats)


########################################################
# general rules that doesn't depend on the GC variable #
########################################################

.PHONY: all
all: basic cdgc

.PHONY: micro-time
micro: micro-time

.PHONY: dil
dil:
	# TODO

.PHONY: micro-time
micro-time: $B/time.eps $B/time.svg
$B/time.%: $(patsubst micro/%.d,$B/time-%.csv,$(wildcard micro/*.d)) \
			time-plot.tpl-gpi time-plot.sh templite.py
	$(P_PLOT) ./time-plot.sh $* $@ $(filter %.csv,$^)

.PRECIOUS: $B/time-%.csv
$B/time-%.csv: $B/basic/time/%.csv | basic cdgc
	$P echo -n > $@
	$P for t in basic cdgc; do \
		(echo -n $$t,; ./stats.py < $B/$$t/time/$*.csv) >> $@; \
		echo "   STATS `tail -n1 $@` >> $@"; \
	   done

.PHONY: cdgc basic
cdgc basic:
	$(P_MAKE) $(MAKE) --no-print-directory micro-gc-build dil-gc-build GC=$@


.PHONY: clean-all clean-cdgc clean-basic
clean-all: clean-cdgc clean-basic
clean-cdgc:
	$(P_MAKE) $(MAKE) --no-print-directory clean GC=cdgc
clean-basic:
	$(P_MAKE) $(MAKE) --no-print-directory clean GC=basic


#########################################
# rules that depends on the GC variable #
#########################################

# micro
########

micro-src := $(wildcard micro/*.d)

.PHONY: micro-gc-build
micro-gc-build: $(patsubst micro/%.d,$O/bin/%,$(wildcard micro/*.d))

.PRECIOUS: $O/bin/%
$O/bin/%: $O/micro/%.o $(LIBTANGO)
	$(P_DC) $(DC) $(LDFLAGS) -of$@ $^

.PHONY: micro-gc-time
micro-gc-time: $(patsubst micro/%.d,$O/time/%.csv,$(wildcard micro/*.d))

.PHONY: micro-gc-stats
micro-gc-stats: $(patsubst micro/%.d,$O/stats/%.eps,$(wildcard micro/*.d))

# special command line arguments for 'shootout_binarytrees' micro benchmark
$O/time/shootout_binarytrees.csv $O/stats/shootout_binarytrees.c.csv \
		$O/stats/shootout_binarytrees.a.csv: \
	override args := 16

# special command line arguments for 'split' micro benchmark
$O/time/split.csv $O/stats/split.c.csv $O/stats/split.a.csv: \
	override args := micro/bible.txt 2

# special command line arguments for 'voronoi' micro benchmark
$O/time/voronoi.csv $O/stats/voronoi.c.csv $O/voronoi/split.a.csv: \
	override args := -n 30000


# dil
######

DIL_SRC = $(wildcard dil/src/*.d dil/src/cmd/*.d dil/src/util/*.d \
			dil/src/dil/*.d dil/src/dil/*/*.d)

.PHONY: dil-gc-build
dil-gc-build: $O/bin/dil
$O/bin/dil: override DFLAGS += -Idil/src
$O/bin/dil: $(patsubst %.d,$O/%.o,$(DIL_SRC)) $(LIBTANGO)
	$(P_DC) $(DC) $(LDFLAGS) -L-lmpfr -L-lgmp -of$@ $^

.PHONY: dil-gc-time
dil-gc-time: $O/time/dil.csv


# common rules
###############

.PRECIOUS: $O/%.o
$O/%.o: %.d
	$(P_DC) $(DC) -c $(DFLAGS) -of$@ $^

I := 3
.PRECIOUS: $O/time/%.csv
ifeq ($F,1)
.PHONY: $(patsubst micro/%.d,$O/bin/%,$(wildcard micro/*.d))
endif
$O/time/%.csv: $O/bin/%
	$P echo -n '   RUN   $* $(args) > $@ ($I)'
	$P echo -n > $@
	$P for i in `seq $I`; do \
		echo -n " $$i"; \
		$(TIME) -f%e -a -o $@ ./$< $(args); \
	done; echo

.PRECIOUS: $O/stats/%.c.csv $O/stats/%.a.csv
$O/stats/%.c.csv $O/stats/%.a.csv: $O/bin/%
	$(P_RUN) D_GC_STATS=1 ./$< $(args)
	$P mv gc-collections.csv $O/stats/$*.c.csv
	$P mv gc-mallocs.csv $O/stats/$*.a.csv

.PRECIOUS: $O/stats/%.h.csv
$O/stats/%.h.csv: $O/stats/%.a.csv hist.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

.PRECIOUS: $O/stats/%.tics
$O/stats/%.tics: $O/stats/%.h.csv tics.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

$O/stats/%.eps: $O/stats/%.c.csv $O/stats/%.a.csv $O/stats/%.h.csv \
			 $O/stats/%.tics plot.gpi
	$(P_PLOT) sed "s|@@PRG@@|$(*F)|g; s|@@COL@@|$(GC)|g; \
			s|@@INC@@|$(word 1,$^)|g; s|@@INA@@|$(word 2,$^)|g; \
			s|@@INH@@|$(word 3,$^)|g; s|@@OUT@@|$@|g; \
			s|@@TICS@@|$(shell cat $(word 4,$^))|g" $(word 5,$^) \
		| $(GNUPLOT)

.PHONY: clean
clean: $O/
	$(P_RM) $(RM) -r $^

