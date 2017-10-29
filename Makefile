MIX = mix
CFLAGS = -O3

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
#ERLANG_DIRTY_SCHEDULERS = $(shell erl -eval 'io:format("~s", [try erlang:system_info(dirty_cpu_schedulers), true catch _:_ -> false end])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)

ifndef MIX_ENV
	MIX_ENV = dev
endif

ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC

	ifeq ($(shell uname),Darwin)
		LDFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
endif

ifeq ($(ERLANG_DIRTY_SCHEDULERS),true)
	CFLAGS += -DERTS_DIRTY_SCHEDULERS
endif

ifdef DEBUG
	CFLAGS += -DNIFSY_DEBUG -pedantic -Weverything -Wall -Wextra -Wno-unused-parameter -Wno-gnu
endif

ifeq ($(MIX_ENV),dev)
	CFLAGS += -g
endif

.PHONY: all clean

all: priv/$(MIX_ENV)/matrix.so priv/$(MIX_ENV)/line.so

SRC_LINE 		= c_src/line.c c_src/erl_utils.c 
SRC_MATRIX 	= c_src/matrix.c c_src/erl_utils.c 

priv/$(MIX_ENV)/matrix.so: $(SRC_MATRIX)
	mkdir -p priv/$(MIX_ENV)
	$(CC) $(CFLAGS) -shared -o $@ $(SRC_MATRIX) $(LDFLAGS)

priv/$(MIX_ENV)/line.so: $(SRC_LINE)
	mkdir -p priv/$(MIX_ENV)
	$(CC) $(CFLAGS) -shared -o $@ $(SRC_LINE) $(LDFLAGS)

clean:
	$(RM) -r priv/dev
	$(RM) -r priv/test
	$(RM) -r priv/prod