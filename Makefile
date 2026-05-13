ROOT          := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
src           ?= $(ROOT)
SRC           ?= $(src)
DESTDIR       ?= ./lua
BEAR          ?= bear
LUA           ?= lua

CC            ?= gcc
LIBFLAG       ?= -shared
CFLAGS        ?= -fPIC -x c -O2
LDFLAGS       ?= -Wl,-s

ifdef LUA_INC
LUA_INCDIR    ?= $(LUA_INC)
endif
ifdef LUA_DIR
LUA_INCDIR    ?= $(LUA_DIR)/include
endif

CFLAGS        += -I$(LUA_INCDIR)

SRC           := $(abspath $(SRC))
SRCS          := $(SRC)/osenv.c

LIB_BUILD_DIR := $(DESTDIR)
LIB_BUILD_DIR := $(abspath $(DESTDIR))
LIB_BUILD_OUT ?= $(LIB_BUILD_DIR)/osenv.so

check_lua_incdir = \
	@if [ -z "$(LUA_INCDIR)" ]; then \
		echo "Error: LUA_INCDIR not set. Please pass or export LUA_INCDIR=/path/to/lua/include"; \
		false; \
	fi

check_so_was_built = \
	@if [ ! -f "$(LIB_BUILD_OUT)" ]; then \
		echo "Error: $(LIB_BUILD_OUT) not built. Run make build first."; \
		false; \
	fi

define newline


endef
define FIX_BEAR_RESULT
local input, tmp = "compile_commands.json", "compile_commands.tmp";
local infile = assert(io.open(input, "r"));
local outfile = assert(io.open(tmp, "w"));
for line in infile:lines() do
  if not line:find("-###", 1, true) then
    outfile:write(line, "\n");
  end
end
infile:close();
outfile:close();
assert(os.rename(tmp, input));
endef

build: $(SRCS)
	$(check_lua_incdir)
	@mkdir -p $(LIB_BUILD_DIR)
	$(CC) $(LIBFLAG) $(LDFLAGS) $(CFLAGS) -o $(LIB_BUILD_OUT) $(SRCS)
install: # nix compat install phase
ifdef out
	@cp -rn $(DESTDIR) $(out)
	@mkdir -p $(out)/doc
	@cp README.md $(out)/doc
endif

bear:   # used to generate compile_commands.json, which editor tools such as clangd and ccls use
	$(check_lua_incdir)
	@$(BEAR) -- $(CC) -### $(LIBFLAG) $(LDFLAGS) $(CFLAGS) -o $(LIB_BUILD_OUT) $(SRCS) > /dev/null 2>&1;
	@echo '$(subst $(newline), ,$(FIX_BEAR_RESULT))' | $(LUA) -;
	@echo "Created compile_commands.json";

test: $(SRCS)
	$(check_so_was_built)
	$(LUA) "$(SRC)/test.lua" "$(LIB_BUILD_DIR)"

clean:
	rm -f $(LIB_BUILD_OUT) compile_commands.json compile_commands.tmp
