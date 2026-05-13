---@meta

---osenv.MY_VAR = "somevalue";
---print(osenv.MY_VAR)
---
---osenv() with no arguments, returns the current environment
---with arguments, adds to (or overwrites) the environment and returns self
---
---Also allows:
---osenv[{}] = { "VARNAMES", "TO_UNSET" }
---
---names must be valid environment variable names
---values may be strings, numbers, or nil (or anything with a __tostring metamethod)
---@alias osenv
---| table<string|nil, (string|number|nil|any)>
---| fun(env?: table<string, (string|number|any)>, overwrite?: boolean):(table<string, string>|osenv)

---@type osenv
return require("osenv")
