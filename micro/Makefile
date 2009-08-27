
VERS    := naive
DC      := dmd
DL      := dmd
GNUPLOT := gnuplot
DFLAGS  += -release -inline -O
DFLAGS  += -defaultlib=tango-base-dmd-$(VERS) -debuglib=tango-base-dmd-$(VERS) \
		-L-ltango-user-dmd-$(VERS)

BUILD_DIR := $(VERS)
BIN_DIR   := $(BUILD_DIR)/bin
STAT_DIR  := $(BUILD_DIR)/stat
PLOT_DIR  := $(BUILD_DIR)/plot
DIRS      := $(BIN_DIR) $(STAT_DIR) $(PLOT_DIR)

sources  := $(wildcard *.d)
programs := $(addprefix $(BIN_DIR)/,$(sources:.d=))
stat_c   := $(addprefix $(STAT_DIR)/,$(addsuffix .c.csv,$(sources:.d=)))
stat_a   := $(addprefix $(STAT_DIR)/,$(addsuffix .a.csv,$(sources:.d=)))
stat_h   := $(addprefix $(STAT_DIR)/,$(addsuffix .h.csv,$(sources:.d=)))
stat     := $(stat_c) $(stat_a) $(stat_h)
graphs_c := $(addprefix $(PLOT_DIR)/,$(addsuffix .c.eps,$(sources:.d=)))
graphs   := $(graphs_c)


ifndef V
P      = @
P_DC   = @echo '  DC	$@';
P_LD   = @echo '  LD	$@';
P_PLOT = @echo '  PLOT	$@';
P_MAKE = @echo '  MAKE	$@';
P_RUN  = @echo '  RUN	$< $(arg1) $(arg2) $(arg3)';
P_AWK  = @echo '  AWK	$@';
endif

# create build directories if they don't already exist
ifneq ($(wildcard $(DIRS)),$(DIRS))
dummy_mkdir := $(shell mkdir -p $(DIRS))
endif

# don't use Gold with old DMDs
ifneq ($(shell ld --version | grep gold),)
export LD_ := /usr/bin/ld.single
endif

.PHONY: all
all: basic naive

.PHONY: naive basic
naive basic:
	$(P_MAKE) $(MAKE) --no-print-directory build VERS=$@

.PHONY: build
build: $(programs)

$(BIN_DIR)/%: $(BIN_DIR)/%.o
	$(P_LD) $(DC) $(DFLAGS) -of$@ $^

$(BIN_DIR)/%.o: %.d
	$(P_DC) $(DC) $(DFLAGS) -c -of$@ $<

.PHONY: stat
stat: $(stat)

.PRECIOUS: $(STAT_DIR)/%.c.csv $(STAT_DIR)/%.a.csv
$(STAT_DIR)/%.c.csv $(STAT_DIR)/%.a.csv: $(BIN_DIR)/%
	$(P_RUN) ./$< $(args)
	$P mv gc-collections.csv $(STAT_DIR)/$*.c.csv
	$P mv gc-mallocs.csv $(STAT_DIR)/$*.a.csv

# special command line arguments for benchmarks
$(STAT_DIR)/split.c.csv $(STAT_DIR)/split.a.csv: override args := bible.txt

.PRECIOUS: $(STAT_DIR)/%.h.csv
$(STAT_DIR)/%.h.csv: $(STAT_DIR)/%.a.csv hist.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

.PHONY: plot
plot: $(graphs)

.PRECIOUS: $(PLOT_DIR)/%.tics
$(PLOT_DIR)/%.tics: $(STAT_DIR)/%.h.csv tics.awk
	$(P_AWK) awk -F, -f $(lastword $^) $< > $@

$(PLOT_DIR)/%.c.eps: $(STAT_DIR)/%.c.csv $(STAT_DIR)/%.a.csv \
			$(STAT_DIR)/%.h.csv $(PLOT_DIR)/%.tics plot-c.gpi
	$(P_PLOT) sed "s|@@PRG@@|$(*F)|g; s|@@COL@@|$(VERS)|g; \
			s|@@INC@@|$(word 1,$^)|g; s|@@INA@@|$(word 2,$^)|g; \
			s|@@INH@@|$(word 3,$^)|g; s|@@OUT@@|$@|g; \
			s|@@TICS@@|$(shell cat $(word 4,$^))|g" $(word 5,$^) \
		| $(GNUPLOT)

.PHONY: clean
clean:
	$(RM) -r $(BUILD_DIR)

