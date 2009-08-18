
VERS    := naive
DC      := dmd
DL      := dmd
GNUPLOT := gnuplot
DFLAGS  += -release -inline -O
DFLAGS  += -defaultlib=tango-base-dmd-$(VERS) -debuglib=tango-base-dmd-$(VERS) \
		-L-ltango-user-dmd-$(VERS)

BASE_DIR  := build
BUILD_DIR := $(BASE_DIR)/$(VERS)
BIN_DIR   := $(BUILD_DIR)/bin
PLOT_DIR  := $(BUILD_DIR)/plot

sources  := $(wildcard *.d)
programs := $(addprefix $(BIN_DIR)/,$(sources:.d=))
graphs_c := $(addprefix $(PLOT_DIR)/,$(addsuffix .c.eps,$(sources:.d=)))
graphs   := $(graphs_c)

ifndef V
P      = @
P_DC   = @echo '  DC	$@';
P_LD   = @echo '  LD	$@';
P_CP   = @echo '  CP	$@';
P_PLOT = @echo '  PLOT	$@';
P_MAKE = @echo '  MAKE	$@';
P_RUN  = @echo '  RUN	$<';
endif

# create build directories if they don't already exist
ifneq ($(wildcard $(BIN_DIR) $(PLOT_DIR)),$(BIN_DIR) $(PLOT_DIR))
dummy_mkdir := $(shell mkdir -p $(BIN_DIR) $(PLOT_DIR))
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

.INTERMEDIATE: $(BIN_DIR)/%.o
$(BIN_DIR)/%.o: %.d
	$(P_DC) $(DC) $(DFLAGS) -c -of$@ $<

.PHONY: plot
plot: $(graphs)

$(PLOT_DIR)/%.c.eps: $(PLOT_DIR)/%.c.csv plot-c.gpi
	$(P_PLOT) \
	sed 's|@@PRG@@|$(*F)|g; s|@@COL@@|$(VERS)|g; s|@@IN@@|$<|g; s|@@OUT@@|$@|g' \
	$(word 2,$^) | $(GNUPLOT)

.PRECIOUS: $(PLOT_DIR)/%.c.csv $(PLOT_DIR)/%.a.csv
$(PLOT_DIR)/%.c.csv $(PLOT_DIR)/%.a.csv: $(BIN_DIR)/%
	$(P_RUN) ./$<
	$P mv gc-collections.csv $(PLOT_DIR)/$*.c.csv
	$P mv gc-mallocs.csv $(PLOT_DIR)/$*.a.csv

$(PLOT_DIR)/split.c.csv $(PLOT_DIR)/split.a.csv: $(BIN_DIR)/bible.txt

$(BIN_DIR)/bible.txt: bible.txt
	$(P_CP) cp -l $< $@

.PHONY: dist-clean
dist-clean:
	$(RM) -r $(BASE_DIR)

.PHONY: clean
clean:
	$(RM) -r $(BUILD_DIR)

