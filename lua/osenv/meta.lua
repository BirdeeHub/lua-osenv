---@meta

---osenv.MY_VAR = "somevalue";
---print(osenv.MY_VAR)
---
---osenv() with no arguments, returns the current environment
---with arguments, adds to (or overwrites) the environment and returns self
---
---Also allows:
---osenv[nil] = { "VARNAMES", "TO_UNSET" }
---@alias osenv
---| table<string, string|number|nil>
---| fun(env?: table<string, string|number>, overwrite?: boolean):(table<string, string>|osenv)

---@type osenv
return require('osenv')
