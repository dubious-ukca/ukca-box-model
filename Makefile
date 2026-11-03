# Disable the default rules
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# Configuration settings
FC := gfortran
FLAGS := ar rcs
LD := $(FC)
RM := rm -f

PROG := my_prog

OBJS := $(addsuffix .o, $(SRCS))

.PHONY: all clean

all: $(PROG)
	@echo Box Model Compiled

$(PROG): $(OBJS)
	$(FC) $(FLAGS) -o $@ $^

$(OBJS): %.o: %.f90
	$(FC) $(FLAGS) -c -o $@ $<

# rebuild all object files in case this Makefile changes
$(OBJS): $(MAKEFILE_LIST)

clean:
	$(RM) $(filter %.o, $(OBJS)) $(wildcard *.mod) $(PROG)