---@meta

---osenv.MY_VAR = "somevalue";
---print(osenv.MY_VAR)
---
---osenv() with no arguments, returns the current environment
---with arguments, adds to (or overwrites) the environment and returns self
---
---Also allows:
---osenv[{"KEY"}] = "VALUE" -- <- set only if not set
---osenv[{}] = { "VARNAMES", "TO_UNSET" } -- <- this one works via __index only
---
---names must be valid environment variable names
---values may be strings, numbers, or nil (or anything with a __tostring metamethod)
---@alias osenv
---| table<string|{ [1]?: string }, (string|number|nil|any)>
---| fun(env?: table<string|{ [1]: string }, (string|number|any)>, overwrite?: boolean):(table<string, string>|osenv)

---@type osenv
return require("osenv")
