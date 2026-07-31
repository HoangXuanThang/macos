/**
 * Export thread safe random to LUA
 *
 * Copyright (c) 2014 YouMi Information Technology Inc.
 *
 * May you do good and not evil.
 * May you find forgiveness for yourself and forgive others.
 * May you share freely, never taking more than you give.
 */

#ifndef _RANDOM_
#define _RANDOM_

#if __cplusplus
extern "C" {
#endif 

#include "lua.h"
#include "lauxlib.h"

#if __cplusplus
}
#endif 

#define LUARANDOM_VERSION    "LuaRandom 2.0"
#define LUARANDOM_COPYRIGHT  "Copyright (C) Information Technology Inc."
#define LUARANDOM_AUTHORS    "1024"

#ifndef LUARANDOM_API
#if __cplusplus
#define LUARANDOM_API extern "C"
#else
#define LUARANDOM_API extern 
#endif 
#endif

LUARANDOM_API int luaopen_random(lua_State *L);
LUARANDOM_API int luaclose_random(lua_State *L);

#endif // _RANDOM_