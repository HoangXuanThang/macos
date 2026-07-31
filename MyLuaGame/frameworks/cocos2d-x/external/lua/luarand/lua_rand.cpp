#include "lua_rand.h"

#include "Rand.h"
#include <map>
#include <unordered_map>

std::unordered_map <lua_State*, RakNetRandom*> mapRandom;

extern "C" {

int _randomseed(lua_State* L)
{
	int nargs = lua_gettop(L);

	// may be in lua coroutine, lua_State is different with main thread
	// but its ok, crash would be alert you, DONT CALL YMRAND IN COROUTINE!!!
	// by huangwei 19/12/5
	if (mapRandom.find(L) == mapRandom.end())
		return 0;

	RakNetRandom* rand = mapRandom[L];
	rand->SeedMT(lua_tonumber(L, 1));
	return 0;
}

int _random(lua_State* L)
{
	int nargs = lua_gettop(L);

	RakNetRandom* rand = mapRandom[L];
	if (nargs == 0)
	{
		lua_pushnumber(L, rand->FrandomMT());
	}
	else if (nargs == 1)
	{
		int m = lua_tointeger(L, 1);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, 1 + (r % m));
	}
	else
	{
		int m = lua_tointeger(L, 1);
		int n = lua_tointeger(L, 2);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, m + (r % (n - m + 1)));
	}

	return 1;
}

int _randomcount(lua_State* L)
{
	int nargs = lua_gettop(L);

	if (mapRandom.find(L) == mapRandom.end())
		return 0;

	RakNetRandom* rand = mapRandom[L];
	lua_pushinteger(L, rand->RandomCount());
	return 1;
}


static lua_Integer ObjectCounter = 1;

int _obj_new(lua_State* L)
{
	int nargs = lua_gettop(L);
	lua_Integer objid = ObjectCounter++;
	while (mapRandom.find((lua_State*)objid) != mapRandom.end())
	{
		objid = ObjectCounter++;
		if (ObjectCounter >= INT_MAX)
			ObjectCounter = 1;
	}

	mapRandom[(lua_State*)objid] = new RakNetRandom();
	lua_pushinteger(L, objid);
	return 1;
}

int _obj_delete(lua_State* L)
{
	int nargs = lua_gettop(L);
	lua_State* objid = (lua_State*)lua_tointeger(L, 1);

	if (mapRandom.find(objid) == mapRandom.end())
		return 0;

	delete mapRandom[objid];
	mapRandom.erase(objid);
	return 0;
}

int _obj_randomseed(lua_State* L)
{
	int nargs = lua_gettop(L);
	lua_State* objid = (lua_State*)lua_tointeger(L, 1);

	if (mapRandom.find(objid) == mapRandom.end())
		return 0;

	RakNetRandom* rand = mapRandom[objid];
	rand->SeedMT(lua_tonumber(L, 2));
	return 0;
}

int _obj_random(lua_State* L)
{
	int nargs = lua_gettop(L);
	lua_State* objid = (lua_State*)lua_tointeger(L, 1);
	nargs--;

	RakNetRandom* rand = mapRandom[objid];
	if (nargs == 0)
	{
		lua_pushnumber(L, rand->FrandomMT());
	}
	else if (nargs == 1)
	{
		int m = lua_tointeger(L, 2);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, 1 + (r % m));
	}
	else
	{
		int m = lua_tointeger(L, 2);
		int n = lua_tointeger(L, 3);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, m + (r % (n - m + 1)));
	}

	return 1;
}

int _obj_randomcount(lua_State* L)
{
	int nargs = lua_gettop(L);
	lua_State* objid = (lua_State*)lua_tointeger(L, 1);

	if (mapRandom.find(objid) == mapRandom.end())
		return 0;

	RakNetRandom* rand = mapRandom[objid];
	lua_pushinteger(L, rand->RandomCount());
	return 1;
}

/* code support functions */
static luaL_Reg func[] = {
	{ "randomseed",  _randomseed },
	{ "random",      _random },
	{ "randomcount",      _randomcount },

	// for anti-cheat, one lua state more rand objs by huangwei 2020/5/21
	{ "obj_new",         _obj_new },
	{ "obj_delete",      _obj_delete },
	{ "obj_randomseed",  _obj_randomseed },
	{ "obj_random",      _obj_random },
	{ "obj_randomcount",      _obj_randomcount },
	{ NULL,          NULL }
};

int luaopen_random(lua_State* L)
{
#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "ymrand", func, 0);
#endif
	/* make version string available to scripts */
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, LUARANDOM_VERSION);
	lua_rawset(L, -3);
	lua_pushstring(L, "_COPYRIGHT");
	lua_pushstring(L, LUARANDOM_COPYRIGHT);
	lua_rawset(L, -3);
	lua_pushstring(L, "_AUTHORS");
	lua_pushstring(L, LUARANDOM_AUTHORS);
	lua_rawset(L, -3);
	/* initialize lookup tables */

	mapRandom[L] = new RakNetRandom();
	return 1;
}

int luaclose_random(lua_State* L)
{
	if (mapRandom.find(L) == mapRandom.end())
		return 0;

	delete mapRandom[L];
	mapRandom.erase(L);
	return 0;
}

}
