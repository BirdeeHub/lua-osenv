local _MODREV, _SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = "osenv"
version = _MODREV .. _SPECREV

source = {
   url = "https://github.com/BirdeeHub/"..package,
}

description = {
   summary = "Manages process environment variables. A `vim.env` polyfill with extra features.",
   homepage = "https://github.com/BirdeeHub/lua-"..package,
   license = "MIT"
}

dependencies = {
   "lua >= 5.1"
}

build = {
   type = "builtin",
   modules = { [package] = package .. ".c" }
}
