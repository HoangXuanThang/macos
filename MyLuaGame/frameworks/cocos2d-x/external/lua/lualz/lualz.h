/**
 * Export AES to LUA
 *
 * Copyright (c) 2014 YouMi Information Technology Inc.
 *
 * May you do good and not evil.
 * May you find forgiveness for yourself and forgive others.
 * May you share freely, never taking more than you give.
 */

#ifndef _LZ4_
#define _LZ4_

#include "lua.h"

#define LUALZ4_VERSION    "LuaLZ4 1.0"
#define LUALZ4_COPYRIGHT  "Copyright (C) Information Technology Inc."
#define LUALZ4_AUTHORS    "1024"

#ifndef LUALZ4_API
#define LUALZ4_API extern
#endif

LUALZ4_API int luaopen_lz4(lua_State *L);

#endif // _LZ4_