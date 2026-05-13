#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#endif

static void clear_process_env(void) {
#ifdef _WIN32
    LPCH env = GetEnvironmentStringsA();
    if (!env)
        return;

    for (LPCH p = env; *p; p += strlen(p) + 1) {
        const char *eq = strchr(p, '=');

        // skip hidden vars like "=C:=..."
        if (!eq || eq == p)
            continue;

        char key[32768];
        size_t len = (size_t)(eq - p);

        memcpy(key, p, len);
        key[len] = '\0';

        SetEnvironmentVariableA(key, NULL);
    }

    FreeEnvironmentStringsA(env);
#else
    clearenv();
#endif
}

static int env_unset(lua_State *L, const char *key) {
#ifdef _WIN32
    if (!SetEnvironmentVariableA(key, NULL))
        return luaL_error(L, "failed to unset env var");
#else
    if (unsetenv(key) != 0)
        return luaL_error(L, "failed to unset env var");
#endif
    return 0;
}

static int env_set(lua_State *L, const char *key, const char *val) {
#ifdef _WIN32
    if (!SetEnvironmentVariableA(key, val))
        return luaL_error(L, "failed to set env var");
#else
    if (setenv(key, val, 1) != 0)
        return luaL_error(L, "failed to set env var");
#endif
    return 0;
}

static int env_get_all(lua_State *L) {
    lua_newtable(L);
#ifdef _WIN32
    LPCH env = GetEnvironmentStringsA();
    if (!env) return 1;
    for (LPCH p = env; *p; p += strlen(p) + 1) {
        const char *eq = strchr(p, '=');
        if (!eq || eq == p) continue;
        lua_pushlstring(L, p, eq - p);
        lua_pushstring(L, eq + 1);
        lua_settable(L, -3);
    }
    FreeEnvironmentStringsA(env);
#else
    extern char **environ;
    if (environ && *environ) {
        for (char **p = environ; *p; p++) {
            const char *eq = strchr(*p, '=');
            if (!eq) continue;
            lua_pushlstring(L, *p, eq - *p);
            lua_pushstring(L, eq + 1);
            lua_settable(L, -3);
        }
    }
#endif
    return 1;
}

static int has_tostring(lua_State *L, int idx) {
    if (!lua_getmetatable(L, idx)) return 0;
    int has = 0;
    lua_getfield(L, -1, "__tostring");
    has = !lua_isnil(L, -1);
    lua_pop(L, 2);
    return has;
}

static int env__newindex(lua_State *L) {
    // CASE 1: bulk unset via env[nil] = {...} or env[nil] = "VAR"
    if (lua_isnil(L, 2)) {
        if (lua_type(L, 3) == LUA_TSTRING) {
            const char *key = lua_tostring(L, 3);
            return env_unset(L, key);
        } else if (lua_type(L, 3) == LUA_TTABLE) {
            lua_pushnil(L);
            while (lua_next(L, 3) != 0) {
                const char *key = luaL_checkstring(L, -1);
                int code = env_unset(L, key);
                if (code != 0) return code;
                lua_pop(L, 1);
            }
            return 0;
        }
        return luaL_error(L, "expected string or string[] of variable names to unset when key is nil. Received a value of type: %s", lua_typename(L, lua_type(L, 3)));
    }

    // CASE 2: normal assignment env["KEY"] = value
    const char *key = luaL_checkstring(L, 2);
    const int vt = lua_type(L, 3);
    if (vt == LUA_TNIL) {
        return env_unset(L, key);
    } else if (vt == LUA_TSTRING || vt == LUA_TNUMBER) {
        return env_set(L, key, lua_tostring(L, 3));
    } else if (has_tostring(L, 3)) {
        lua_getglobal(L, "tostring");
        if (!lua_isfunction(L, -1)) return luaL_error(L, "using the __tostring metamethod depends on the 'tostring' global function being available");
        lua_insert(L, 3);
        lua_call(L, 1, 1);
        return env_set(L, key, lua_tostring(L, 3));
    } else {
        return luaL_error(L, "env values must be nil to unset, or be strings or numbers, or have a __tostring metamethod. Received a value of type: %s", lua_typename(L, lua_type(L, 3)));
    }
    return 0;
}

static int env__index(lua_State *L) {
    const char *key = luaL_checkstring(L, 2);
    const char *val = getenv(key);
    if (val)
        lua_pushstring(L, val);
    else
        lua_pushnil(L);
    return 1;
}

// -- implicit self param and then:
//@param: table? -- new environment values
//@param: boolean? -- overwrite process env
//@returns: table -- current environment if no args, otherwise self
static int env__call(lua_State *L) {
    int nargs = lua_gettop(L);
    // env()
    if (nargs == 1) return env_get_all(L);

    // env(table)
    luaL_checktype(L, 2, LUA_TTABLE);

    if (nargs > 2 && lua_toboolean(L, 3)) clear_process_env();

    lua_pushnil(L);
    while (lua_next(L, 2) != 0) {
        const char *key = luaL_checkstring(L, -2);
        int vt = lua_type(L, -1);
        if (vt == LUA_TSTRING || vt == LUA_TNUMBER) {
            env_set(L, key, lua_tostring(L, -1));
        } else if (has_tostring(L, -1)) {
            lua_getglobal(L, "tostring");
            if (!lua_isfunction(L, -1)) return luaL_error(L, "using the __tostring metamethod depends on the 'tostring' global function being available");
            lua_insert(L, -2);
            lua_call(L, 1, 1);
            env_set(L, key, lua_tostring(L, -1));
        } else {
            return luaL_error(L, "env values must be strings or numbers, or have a __tostring metamethod. Received a value of type: %s", lua_typename(L, lua_type(L, -1)));;
        }
        lua_pop(L, 1);
    }
    lua_settop(L, 1);
    return 1;
}

int luaopen_osenv(lua_State *L) {
    lua_newtable(L); // module table
    lua_newtable(L); // metatable
    lua_pushcfunction(L, env__index);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, env__call);
    lua_setfield(L, -2, "__call");
    lua_pushcfunction(L, env__newindex);
    lua_setfield(L, -2, "__newindex");
    lua_setmetatable(L, -2); // setmetatable(t, mt)
    return 1; // return env table
}
