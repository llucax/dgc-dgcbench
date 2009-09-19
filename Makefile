
VERS    := naive
DC      := dmd
DL      := dmd
GNUPLOT := gnuplot
DFLAGS  += -defaultlib=tango-base-dmd-$(VERS) -debuglib=tango-base-dmd-$(VERS)
DFLAGS  += -release -inline -O

O := $(VERS)

micro_src := $(wildcard micro/*.d)

ifndef V
P      = @
P_DC   = @printf '   DC    %- 40s <-  %s\n' '$@' '$<';
P_LD   = @printf '   LD    %- 40s <-  %s\n' '$@' '$^';
P_PLOT = @printf '   PLOT  %- 40s <-  %s\n' '$@' '$< ...';
P_AWK  = @printf '   AWK   %- 40s <-  %s\n' '$@' '$<';
P_RUN  = @printf '   RUN   $< $(args)\n';
P_MAKE = @printf '   MAKE  $@\n';
P_RM   = @printf '   RM    $^\n';
endif

# create build directories if they don't already exist
ifneq ($(wildcard $O),$O)
dummy_mkdir := $(shell mkdir -p $O)
endif

# don't use Gold with old DMDs
ifneq ($(shell ld --version | grep gold),)
export LD_ := /usr/bin/ld.single
endif

.PHONY: all
all: naive

.PHONY: naive basic
naive basic:
	$(P_MAKE) $(MAKE) --no-print-directory micro VERS=$@

$O/%: $O/%.o
	$(P_LD) $(DC) $(DFLAGS) -of$@ $^

$O/%.o: %.d
	$(P_DC) $(DC) $(DFLAGS) -c -of$@ $<

.PRECIOUS: $O/%.c.csv $O/%.a.csv
$O/%.c.csv $O/%.a.csv: $O/%
	$(P_RUN) ./$< $(args)
	$P mv gc-collections.csv $O/$*.c.csv
	$P mv gc-mallocs.csv $O/$*.a.csv

# special command line arguments for benchmarks
$O/micro/split.c.csv $O/micro/split.a.csv: override args := micro/bible.txt

.PRECIOUS: $O/%.h.csv
$O/%.h.csv: $O/%.a.csv hist.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

.PHONY: micro
micro: $(patsubst %.d,$O/%.eps,$(micro_src))

.PRECIOUS: $O/%.tics
$O/%.tics: $O/%.h.csv tics.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

$O/%.eps: $O/%.c.csv $O/%.a.csv \
			$O/%.h.csv $O/%.tics plot.gpi
	$(P_PLOT) sed "s|@@PRG@@|$(*F)|g; s|@@COL@@|$(VERS)|g; \
			s|@@INC@@|$(word 1,$^)|g; s|@@INA@@|$(word 2,$^)|g; \
			s|@@INH@@|$(word 3,$^)|g; s|@@OUT@@|$@|g; \
			s|@@TICS@@|$(shell cat $(word 4,$^))|g" $(word 5,$^) \
		| $(GNUPLOT)

.PHONY: clean
clean: $O/
	$(P_RM) $(RM) -r $^

