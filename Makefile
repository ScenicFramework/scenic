# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries
# MIX_COMPILE_PATH path to the build's ebin directory

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj

# Look for the EI library and header files
# For crosscompiled builds, ERL_EI_INCLUDE_DIR and ERL_EI_LIBDIR must be
# passed into the Makefile.

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

LDFLAGS += -fPIC -shared  -dynamiclib
CFLAGS ?= -fPIC -O2 -Wall -Wextra -Wno-unused-parameter -std=c99

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup
endif
endif

NIF=$(PREFIX)/line.so $(PREFIX)/matrix.so

calling_from_make:
	mix compile

all: $(PREFIX) $(BUILD) $(NIF)

pull_deps:
	mix local.hex --force
	mix local.rebar --force
	mix deps.get
	mkdir -p priv/static/font_metrics
	cp -r deps/font_metrics/test/metrics/*.ttf.metrics priv/static/font_metrics

linter:
	mix format --check-formatted
	# mix credo

unit_test:
	mix coveralls.json

docs_report:
	MIX_ENV=docs mix inch.report

$(BUILD)/%.o: c_src/%.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

$(PREFIX)/line.so: $(BUILD)/line.o
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

$(PREFIX)/matrix.so: $(BUILD)/matrix.o
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

$(PREFIX) $(BUILD):
	mkdir -p $@

clean:
	$(RM) $(NIF) c_src/*.o

