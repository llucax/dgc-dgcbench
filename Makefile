
VERS    := naive
DC      := dmd
DL      := dmd
GNUPLOT := gnuplot
DFLAGS  += -defaultlib=tango-base-dmd-$(VERS) -debuglib=tango-base-dmd-$(VERS)
DFLAGS  += -release -inline -O

O := $(VERS)

ifndef V
P      = @
P_DC   = @printf '   DC    %- 40s <-  %s\n' '$@' '$(if \
		$(subst 1,,$(words $^)),$< ... $(lastword $^),$<)';
P_PLOT = @printf '   PLOT  %- 40s <-  %s\n' '$@' '$(filter %.csv,$^)';
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


# micro
########

.PHONY: build-micro
build-micro: $(patsubst %.d,$O/%,$(wildcard micro/*.d))

.PHONY: micro
micro: $(patsubst %.d,$O/%.eps,$(wildcard micro/*.d))

# special command line arguments 'split' micro benchmark
$O/micro/split.c.csv $O/micro/split.a.csv: override args := micro/bible.txt


# common rules
###############

.PRECIOUS: $O/%
$O/%: %.d
	$(P_DC) $(DC) $(DFLAGS) -of$@ $^

.PRECIOUS: $O/%.c.csv $O/%.a.csv
$O/%.c.csv $O/%.a.csv: $O/%
	$(P_RUN) D_GC_STATS=1 ./$< $(args)
	$P mv gc-collections.csv $O/$*.c.csv
	$P mv gc-mallocs.csv $O/$*.a.csv

.PRECIOUS: $O/%.h.csv
$O/%.h.csv: $O/%.a.csv hist.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

.PRECIOUS: $O/%.tics
$O/%.tics: $O/%.h.csv tics.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

$O/%.eps: $O/%.c.csv $O/%.a.csv $O/%.h.csv $O/%.tics plot.gpi
	$(P_PLOT) sed "s|@@PRG@@|$(*F)|g; s|@@COL@@|$(VERS)|g; \
			s|@@INC@@|$(word 1,$^)|g; s|@@INA@@|$(word 2,$^)|g; \
			s|@@INH@@|$(word 3,$^)|g; s|@@OUT@@|$@|g; \
			s|@@TICS@@|$(shell cat $(word 4,$^))|g" $(word 5,$^) \
		| $(GNUPLOT)

.PHONY: clean
clean: $O/
	$(P_RM) $(RM) -r $^

