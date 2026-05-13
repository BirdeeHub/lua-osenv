# osenv - lua module for managing os environment variables

`os.getenv` exists by default. `os.setenv` does not.

A `vim.env` polyfill with extra features.

`require('osenv').MY_VAR = "MY_VALUE"`

## Installation

### Using LuaRocks

```bash
luarocks install osenv
```

### Using Nix

* Flake or flakeless support, both methods return according to the [flake outputs schema](https://wiki.nixos.org/wiki/Flakes).
* Overlay and packages available for Lua versions 5.1+, as well as a neovim plugin.
* Dev shell included for building via `make`.

### Using Make

Requires a C compiler (GCC, Clang, MinGW). If not gcc, set `CC` as well.
Run from the root of the repository.

If you don't know where your Lua headers are, find them with:

```bash
gcc -xc -E -v - <<< '#include <lua.h>' 2>&1 | grep lua.h | head -n 1 | awk '{print $3}' | tr -d '"' | xargs dirname
```

**Build the library:**

Build outputs to `DESTDIR`, which defaults to `./lua`, creating `./lua/osenv.so`

```bash
make build LUA_INCDIR=/path/to/lua/includes
```

**Add to Lua's `package.cpath` after building:**

```bash
export LUA_CPATH="$LUA_CPATH;/path/to/osenv/lua/?.so"
```

### Usage

```lua
package.cpath = package.cpath .. ";/path/to/osenv/lib/?.so"
-- mark it like this for lsp type info! (sorry, C compiled module)
---@module 'osenv.meta'
os.env = require("osenv")

-- set the variable
os.env.MY_VAR = "somevalue"
os.env.MY_NUMBER_VAR = 1
os.env.MY_META_VAR = setmetatable({}, { __tostring = function(self) return "my meta var" end })

-- get the variable (always a string value, nil if unset)
print(os.env.MY_VAR)
print(os.env.MY_NUMBER_VAR)
print(os.env.MY_META_VAR)

-- unset the variable
os.env.MY_VAR = nil

---Special mass unset syntax:
osenv[nil] = { "MY_NUMBER_VAR", "MY_META_VAR" }

-- with no arguments, returns the current environment
local current_env = os.env()
for k, v in pairs(current_env) do
    print(k.."="..v)
end

local new_env_vars = {
    PATH = os.env.PATH..":/home/"..os.env.USER.."/.bin",
    HOME = "/home/"..os.env.USER,
    EXTRA_VAR = "extra"
}

os.env(new_env_vars) -- add the variables to the current environment

for k, v in pairs(new_env_vars) do
    current_env[k] = v
end
os.env(current_env, true) -- OVERWRITE the current environment (careful!)
```
