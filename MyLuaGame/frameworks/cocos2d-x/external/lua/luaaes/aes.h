/**
 * Export AES to LUA
 *
 * Copyright (c) 2014 YouMi Information Technology Inc.
 *
 * May you do good and not evil.
 * May you find forgiveness for yourself and forgive others.
 * May you share freely, never taking more than you give.
 */

#ifndef _AES_
#define _AES_

#include "lua.h"

#define LUAAES_VERSION    "LuaAES 1.0"
#define LUAAES_COPYRIGHT  "Copyright (C) Information Technology Inc."
#define LUAAES_AUTHORS    "1024"

#ifndef LUAAES_API
#define LUAAES_API extern
#endif

LUAAES_API int luaopen_aes(lua_State *L);

#endif // _AES_