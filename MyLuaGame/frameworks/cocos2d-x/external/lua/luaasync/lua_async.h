/**
 * Async Task for LUA
 *
 * Copyright (c) 2018 TianJi Information Technology Inc.
 *
 * May you do good and not evil.
 * May you find forgiveness for yourself and forgive others.
 * May you share freely, never taking more than you give.
 */

#ifndef _ASYNC_
#define _ASYNC_

#if __cplusplus
extern "C" {
#endif 

#include "lua.h"
#include "lauxlib.h"
#include "tolua/tolua++.h"

#if __cplusplus
}
#endif 

#ifndef LUAASYNC_API
#if __cplusplus
#define LUAASYNC_API extern "C"
#else
#define LUAASYNC_API extern 
#endif 
#endif

LUAASYNC_API int luaopen_async(lua_State *L);
LUAASYNC_API int luaclose_async(lua_State *L);

#endif // _ASYNC_