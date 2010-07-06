
GC       := cdgc
O        := build/$(GC)
DC       := dmd
LD       := dmd
LN       := ln
GNUPLOT  := gnuplot
override DFLAGS ?= -release -inline -O -gc
LDFLAGS  := -defaultlib=tango-$(GC) -debuglib=tango-$(GC)
LIBTANGO := ../lib/libtango-$(GC).a

ifndef V
P      = @
P_DC   = @printf '   DC    %- 40s <-  %s\n' '$@' '$(if \
		$(subst 1,,$(words $^)),$< ... $(lastword $^),$<)';
P_PLOT = @printf '   PLOT  %- 40s <-  %s\n' '$@' '$(filter %.csv,$^)';
P_AWK  = @printf '   AWK   %- 40s <-  %s\n' '$@' '$<';
P_RUN  = @printf '   RUN   $< $(args)\n';
P_MAKE = @printf '   MAKE  $@\n';
P_RM   = @printf '   RM    $^\n';
P_LN   = @printf '   LN    %- 40s <-  %s\n' '$@' '$<';
endif

# create build directories if they don't already exist
ifneq ($(wildcard $O),$O)
dummy_mkdir := $(shell mkdir -p $O $O/bin $O/stats)
endif

# don't use Gold with old DMDs
ifeq ($(subst dmd,,$(DC)),)
ifneq ($(strip $(shell ld --version | grep gold)),)
export LD_ := /usr/bin/ld.single
endif
endif

.PHONY: all
all: cdgc basic

.PHONY: cdgc basic
cdgc basic:
	$(P_MAKE) $(MAKE) --no-print-directory micro-build dil-build GC=$@


# micro
########

.PHONY: micro-build
micro-build: $(patsubst micro/%.d,$O/bin/%,$(wildcard micro/*.d))

.PRECIOUS: $O/bin/%
$O/bin/%: $O/micro/%.o
	$(P_DC) $(DC) $(LDFLAGS) -of$@ $^

.PHONY: micro-stats
micro-stats: $(patsubst micro/%.d,$O/stats/%.eps,$(wildcard micro/*.d))

# special command line arguments 'split' micro benchmark
$O/micro/split.c.csv $O/micro/split.a.csv: override args := micro/bible.txt


# dil
######

DIL_SRC = $(wildcard dil/src/*.d dil/src/cmd/*.d dil/src/util/*.d \
			dil/src/dil/*.d dil/src/dil/*/*.d)

.PHONY: dil-nop-stats
dil-nop-stats: $O/stats/dil-nop.eps

.PHONY: dil-build
dil-build: $O/bin/dil
$O/bin/dil: override DFLAGS += -Idil/src
$O/bin/dil: $(patsubst %.d,$O/%.o,$(DIL_SRC)) $(LIBTANGO)
	$(P_DC) $(DC) $(LDFLAGS) -L-lmpfr -L-lgmp -of$@ $^

$O/bin/dil-nop: $O/bin/dil
	@$(P_LN) $(LN) -sf $(<F) $@


# common rules
###############

.PRECIOUS: $O/%.o
$O/%.o: %.d
	$(P_DC) $(DC) -c $(DFLAGS) -of$@ $^

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

.PHONY: clean-all
clean-all: clean-cdgc clean-basic
clean-cdgc:
	$(P_MAKE) $(MAKE) --no-print-directory clean GC=cdgc
clean-basic:
	$(P_MAKE) $(MAKE) --no-print-directory clean GC=basic

