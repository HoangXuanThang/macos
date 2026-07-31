#include "lua_dump.h"


extern "C" {

int _setUserInfo(lua_State* L)
{
	int nargs = lua_gettop(L);

	if (nargs == 2)
	{

	}

	return 0;
}

int _sendException(lua_State* L)
{
	int nargs = lua_gettop(L);

	if (nargs == 1)
	{

	}

	return 0;
}

/* code support functions */
static luaL_Reg func[] = {
	{"setUserInfo",   _setUserInfo},
	{"sendException",  _sendException},
	{NULL,         NULL}
};

int luaopen_dump(lua_State* L)
{
#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "ymdump", func, 0);
#endif
	/* make version string available to scripts */
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, LUADUMP_VERSION);
	lua_rawset(L, -3);
	lua_pushstring(L, "_COPYRIGHT");
	lua_pushstring(L, LUADUMP_COPYRIGHT);
	lua_rawset(L, -3);
	lua_pushstring(L, "_AUTHORS");
	lua_pushstring(L, LUADUMP_AUTHORS);
	lua_rawset(L, -3);
	/* initialize lookup tables */

	return 1;
}

int luaclose_dump(lua_State* L)
{
	return 0;
}

}
