/**
 * Export dump.cpp to LUA
 *
 * Copyright (c) 2018 TianJi Information Technology Inc.
 *
 * May you do good and not evil.
 * May you find forgiveness for yourself and forgive others.
 * May you share freely, never taking more than you give.
 */

#ifndef _DUMP_
#define _DUMP_

#if __cplusplus
extern "C" {
#endif 

#include "lua.h"
#include "lauxlib.h"

#if __cplusplus
}
#endif 

#define LUADUMP_VERSION    "LuaDump 1.0"
#define LUADUMP_COPYRIGHT  "Copyright (C) Information Technology Inc."
#define LUADUMP_AUTHORS    "1024"

#ifndef LUADUMP_API
#if __cplusplus
#define LUADUMP_API extern "C"
#else
#define LUADUMP_API extern 
#endif 
#endif

LUADUMP_API int luaopen_dump(lua_State *L);
LUADUMP_API int luaclose_dump(lua_State *L);

#endif // _DUMP_