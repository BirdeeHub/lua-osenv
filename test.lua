#!/usr/bin/env lua
local cfg = string.gmatch(package.config, "(%S+)")
local dirsep, pathsep, pathmark = cfg() or "/", cfg() or ";", cfg() or "?"
local function cwd()
	local sep = dirsep
	local info = debug.getinfo(1, "S")
	local source = info.source
	if source:sub(1, 1) == "@" then
		local realpath = ((vim or {}).uv or (vim or {}).loop or {}).fs_realpath
		local path = source:sub(2)
		path = realpath and realpath(path) or path
		local dir, file = path:match("^(.*[" .. sep .. "])([^" .. sep .. "]+)$")
		return dir or ("." .. sep), file
	end
	return "." .. sep, nil
end
local here = cwd()
local dircat = function(...)
	return table.concat({ ... }, dirsep)
end
local pathcat = function(...)
	return table.concat({ ... }, pathsep)
end
package.path = pathcat(here .. pathmark .. ".lua", package.path)
local test = require("gambiarra")

if arg[1] then
	package.cpath = pathcat(dircat(arg[1], pathmark .. ".so"), package.cpath)
else
	package.cpath = pathcat(dircat(here .. "lua", pathmark .. ".so"), package.cpath)
end

---

test("osenv: environment clearing and restoration", function()
	local osenv = require("osenv")
	local oldenv = osenv()
	ok(type(oldenv) == "table", "osenv() should return a table")
	osenv({}, true)
	ok(next(osenv()) == nil, "env should be empty after osenv({}, true)")
	osenv(oldenv)
end)

test("osenv: get and set with various types", function()
	local osenv = require("osenv")
	local oldenv = osenv()
	osenv.REBUILD_TEST = "testvar"
	osenv.TEST_1 = 1
	osenv.TEST__TOSTRING = setmetatable({}, {
		__tostring = function()
			return "teststring"
		end,
	})
	osenv.TEST__CALL__TOSTRING = setmetatable({}, {
		__tostring = setmetatable({}, {
			__call = function()
				return "teststring"
			end,
		}),
	})
	osenv.TEST__CALL__CALL__TOSTRING = setmetatable({ val = 0 }, {
		__tostring = setmetatable({ val = 1 }, {
			__call = setmetatable({ val = 2 }, {
				__call = function(self, og)
					return "teststring"..tostring(self.val)..tostring(og.val)
				end,
			}),
		}),
	})
	osenv({ EXTRA_TEST = "extra" })
	ok(eq(osenv.REBUILD_TEST, "testvar"), "should read back string env var")
	ok(eq(osenv.TEST_1, "1"), "should read back number env var as string")
	ok(eq(osenv.TEST__TOSTRING, "teststring"), "should use __tostring metamethod")
	ok(
		eq(osenv.TEST__CALL__TOSTRING, "teststring"),
		"should use __tostring metamethod even if it is a table with a __call metamethod"
	)
	ok(
		eq(osenv.TEST__CALL__CALL__TOSTRING, "teststring20"),
		"should use __tostring metamethod even if it is a table with a __call metamethod with a __call metamethod"
	)
	ok(osenv.HAHAHAHA == nil, "should return nil for missing env var")
	ok(eq(osenv.EXTRA_TEST, "extra"), "function should append by default")
	local env = osenv()
	ok(eq(env.REBUILD_TEST, "testvar"), "osenv() table should contain REBUILD_TEST")
	ok(eq(env.TEST_1, "1"), "osenv() table should contain TEST_1")
	ok(eq(env.TEST__TOSTRING, "teststring"), "osenv() table should contain TEST__TOSTRING")
	ok(eq(env.EXTRA_TEST, "extra"), "osenv() table should contain EXTRA_TEST")
	osenv(oldenv)
end)

test("require('osenv') tests", function()
	local env = require("osenv")
	env.TESTVARIABLE = "HELLO"
	ok(env.TESTVARIABLE == os.getenv("TESTVARIABLE"), "osenv should get the env var")
	env[{}] = "TESTVARIABLE"
	ok(env.TESTVARIABLE == nil, "osenv should be removed (via the special syntax)")
	env.TESTVARIABLE = "HELLO"
	env[{}] = { "TESTVARIABLE" }
	ok(env.TESTVARIABLE == nil, "osenv should be removed (via the special syntax again)")
	ok(os.getenv("TESTVARIABLE") == nil, "os.getenv('thevar') should be removed just like the env var")
end)

---

test.await(function(self)
	self.report()
	if (self.tests_failed or 0) > 0 then
		os.exit(1)
	else
		os.exit(0)
	end
end)
