#include "lua_async.h"

#include "base/CCAsyncTaskPool.h"

#include "scripting/lua-bindings/manual/CCLuaEngine.h"
#include "scripting/lua-bindings/manual/CCLuaValue.h"
#include "scripting/lua-bindings/manual/LuaBasicConversions.h"

#include "socket.h"

#define SELECT_ITAB "__ymasync_SELECT_ITAB_%p__"
#define SELECT_RTAB "__ymasync_SELECT_RTAB_%p__"
#define SELECT_WTAB "__ymasync_SELECT_WTAB_%p__"

extern "C" {

struct SelectInfo {
    t_socket max_fd;
    int select_ret;
	fd_set rset;
	fd_set wset;

	char itab_name[48];
	char rtab_name[48];
	char wtab_name[48];
	LUA_FUNCTION select_lua_handler;
	t_timeout tm;
	char* last_err;
};

static LUA_FUNCTION s_select_lua_handler = 0;
static SelectInfo s_info;
static t_timeout tm;

int _new_selector(lua_State* tolua_S)
{
	SelectInfo* info = (SelectInfo*)malloc(sizeof(SelectInfo));
	info->select_lua_handler = 0;
	info->last_err = NULL;
	sprintf(info->itab_name, SELECT_ITAB, info);
	sprintf(info->rtab_name, SELECT_RTAB, info);
	sprintf(info->wtab_name, SELECT_WTAB, info);

	lua_pushlightuserdata(tolua_S, info);
	return 1;
}

// like global_select
// select(select_id, recv_sockets, timeout, callback({sockets}, err))
int _select(lua_State* tolua_S)
{
	int argc = 0;
	cocos2d::AsyncTaskPool* cobj = cocos2d::AsyncTaskPool::getInstance();
	tolua_Error tolua_err;
    
	argc = lua_gettop(tolua_S);

	SelectInfo* info = nullptr;
	int wtab, rtab, itab, ndirty;
	double t = 1;

	do {
		if (argc == 5) {
            if (!lua_isuserdata(tolua_S, 1) || !lua_isnumber(tolua_S, 4))
                goto tolua_lerror;

			// init sockets
			SelectInfo* info = (SelectInfo*)lua_touserdata(tolua_S, 1);
			info->max_fd = SOCKET_INVALID;
			info->select_ret = -1;
			FD_ZERO(&(info->rset));
			FD_ZERO(&(info->wset));

			if (info->select_lua_handler < 0)
			{
				luaL_error(tolua_S, "_select running\n");
				return 0;
			}

            t = lua_tonumber(tolua_S, 4);

			lua_newtable(tolua_S); itab = lua_gettop(tolua_S);
			lua_newtable(tolua_S); rtab = lua_gettop(tolua_S);
			lua_newtable(tolua_S); wtab = lua_gettop(tolua_S);
			collect_fd(tolua_S, 2, itab, &info->rset, &info->max_fd);
			collect_fd(tolua_S, 3, itab, &info->wset, &info->max_fd);
			ndirty = check_dirty(tolua_S, 2, rtab, &info->rset);

			// because in LUA, we had only one socket usually, so return immediately in here
			if (ndirty > 0)
			{
				if (lua_isfunction(tolua_S, 5))
				{
					lua_pushvalue(tolua_S, 5); // copy to the top
					make_assoc(tolua_S, rtab);
					lua_pushnil(tolua_S);
					lua_pushnil(tolua_S);
					LuaEngine::getInstance()->getLuaStack()->executeFunction(3);
					return 1;
				}
				else
				{
					goto tolua_lerror;
				}
			}

			t = ndirty > 0 ? 0.0 : t; // wait in fixed 1s period
			timeout_init(&info->tm, t, -1);
			timeout_markstart(&info->tm);
            
            // when std::function callback be invoked, the stack be changed
            lua_pushstring(tolua_S, info->itab_name);
            lua_pushvalue(tolua_S, itab);
            lua_rawset(tolua_S, LUA_REGISTRYINDEX);
            
            lua_pushstring(tolua_S, info->rtab_name);
            lua_pushvalue(tolua_S, rtab);
            lua_rawset(tolua_S, LUA_REGISTRYINDEX);

			lua_pushstring(tolua_S, info->wtab_name);
			lua_pushvalue(tolua_S, wtab);
			lua_rawset(tolua_S, LUA_REGISTRYINDEX);

			LUA_FUNCTION handler = toluafix_ref_function(tolua_S, 5, info->select_lua_handler);
            info->select_lua_handler = -handler;
			std::function<void(void*)> arg1 = [tolua_S, info, handler](void*) {
                lua_pushstring(tolua_S, info->itab_name);
                lua_rawget(tolua_S, LUA_REGISTRYINDEX);
                int itab = lua_gettop(tolua_S);
                lua_pushstring(tolua_S, info->rtab_name);
                lua_rawget(tolua_S, LUA_REGISTRYINDEX);
                int rtab = lua_gettop(tolua_S);
				lua_pushstring(tolua_S, info->wtab_name);
				lua_rawget(tolua_S, LUA_REGISTRYINDEX);
				int wtab = lua_gettop(tolua_S);
                
				if (info->select_ret > 0)
				{
					return_fd(tolua_S, &info->rset, info->max_fd + 1, itab, rtab, 0);
					return_fd(tolua_S, &info->wset, info->max_fd + 1, itab, wtab, 0);
					make_assoc(tolua_S, rtab);
					make_assoc(tolua_S, wtab);
					lua_pushnil(tolua_S);
				}
				else if (info->select_ret == 0)
				{
					lua_pushnil(tolua_S);
					lua_pushnil(tolua_S);
					lua_pushstring(tolua_S, "timeout");
				}
				else
				{
					lua_pushnil(tolua_S);
					lua_pushnil(tolua_S);
					lua_pushstring(tolua_S, info->last_err ? info->last_err : "failed");
				}
				info->select_lua_handler = handler; // its flag for reenter
				LuaEngine::getInstance()->getLuaStack()->executeFunctionByHandler(handler, 3);
			};

			std::function<void()> task = [info, t]() {
				info->select_ret = socket_select(info->max_fd + 1, &info->rset, &info->wset, nullptr, &info->tm);
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
				if (info->select_ret < 0)
				{
					info->last_err = (char*)socket_strerror(WSAGetLastError());
					CCLOG(info->last_err);
				}
#endif // CC_TARGET_PLATFORM == CC_PLATFORM_WIN32

			};
			cobj->enqueue(cocos2d::AsyncTaskPool::TaskType::TASK_LUA_NETWORK, arg1, nullptr, task);
			lua_settop(tolua_S, 1);
			return 1;
		}
	} while (0);
	luaL_error(tolua_S, "_select has wrong number of arguments: %d, was expecting 5 \n", argc);
	return 0;

tolua_lerror:
	tolua_error(tolua_S, "#ferror in function '_select'.", &tolua_err);
	return 0;
}


/* code support functions */
static luaL_Reg func[] = {
	{ "new_selector", _new_selector },
	{ "select", _select },
	{NULL, NULL}
};

int luaopen_async(lua_State* L)
{
#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "ymasync", func, 0);
#endif

	return 1;
}

int luaclose_async(lua_State* L)
{
	return 0;
}

}
