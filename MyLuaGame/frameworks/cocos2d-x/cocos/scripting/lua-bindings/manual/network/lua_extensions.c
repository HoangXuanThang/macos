
#include "platform/CCPlatformConfig.h"
#include "scripting/lua-bindings/manual/network/lua_extensions.h"

#include "luarand/lua_rand.h"
#include "luadump/lua_dump.h"
#include "luaasync/lua_async.h"

#if __cplusplus
extern "C" {
#endif
// socket
#include "luasocket/luasocket.h"
#include "luasocket/luasocket_scripts.h"
#include "luasocket/mime.h"

#include "luaaes/aes.h"
#include "lualz/lualz.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
#include "iuplua.h"
#include "iupluacontrols.h"
#include "iupluagl.h"
#include "iupluaglcontrols.h"
#include "iupluaim.h"
#include "iupluamatrixex.h"
#include "iupluaole.h"
#include "iupluascripterdlg.h"
#include "iupluatuio.h"
#include "iupluaweb.h"
#include "iuplua_mglplot.h"
#include "iuplua_plot.h"
#include "iuplua_scintilla.h"
#endif

static luaL_Reg luax_exts[] = {
    {"socket.core", luaopen_socket_core},
    {"mime.core", luaopen_mime_core},

	{ "aes", luaopen_aes },
	{ "lz4", luaopen_lz4 },
	{ "ymrand", luaopen_random },
	{ "ymdump", luaopen_dump },
	{ "ymasync", luaopen_async },

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	{ "iuplua", iuplua_open },
	{ "iupluacontrols", iupcontrolslua_open },
	{ "iupluagl", iupgllua_open },
	{ "iupluaglcontrols", iupglcontrolslua_open },
	{ "iupluaim", iupimlua_open },
	{ "iupluamatrixex", iupmatrixexlua_open },
	{ "iupluaole", iupolelua_open },
	{ "iupluascripterdlglua", iupluascripterdlglua_open },
	{ "iupluatuio", iuptuiolua_open },
	{ "iupluaweb", iupweblua_open },
	{ "iupluamglplot", iup_mglplotlua_open },
	{ "iupluaplot", iup_plotlua_open },
	{ "iupluascintilla", iup_scintillalua_open },
#endif
    {NULL, NULL}
};

void luaopen_lua_extensions(lua_State *L)
{
    // load extensions
    luaL_Reg* lib = luax_exts;
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lua_pushcfunction(L, lib->func);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);

    luaopen_luasocket_scripts(L);
}

#if __cplusplus
} // extern "C"
#endif
