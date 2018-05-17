ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

LDFLAGS += -fPIC -shared  -dynamiclib
CFLAGS ?= -fPIC -O2 -Wall -Wextra -Wno-unused-parameter

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -undefined dynamic_lookup
endif
endif

NIF=priv/line.so priv/matrix.so

# calling_from_make:
# 	mix compile

all: priv $(NIF)

priv:
	mkdir -p priv

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

priv/line.so: c_src/line.o
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

priv/matrix.so: c_src/matrix.o
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	$(RM) $(NIF) src/*.o