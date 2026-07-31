/****************************************************************************
 Copyright (c) 2011-2012 cocos2d-x.org
 Copyright (c) 2013-2017 Chukong Technologies Inc.

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
#include "scripting/lua-bindings/manual/Cocos2dxLuaLoader.h"
#include <string>
#include <algorithm>

#include "cocos2d.h"
#include "scripting/lua-bindings/manual/CCLuaStack.h"
#include "scripting/lua-bindings/manual/CCLuaEngine.h"
#include "platform/CCFileUtils.h"
#include "base/allocator/TJAllocator.h"


using namespace cocos2d;

extern "C"
{
    int cocos2dx_lua_loader(lua_State *L)
    {
        //static const std::string BYTECODE_FILE_EXT    = ".luac";
        static const std::string NOT_BYTECODE_FILE_EXT = ".lua";

		// only check .lua, modify by huangwei
        std::string filename(luaL_checkstring(L, 1));
		size_t pos = 0;
		
		// flat place "config.yyhuodong.drawXX" file in directory, modify by huangwei 18.3.20
		if (LuaEngine::isFlatPath)
		{
			// only special "cocos" directory, like "cocos.cocos2d.Cocos2d", it mean "cocos/cocos2d.Cocos2d"
			// because "cocos" in lua search path, so remove prefix
			if (filename.compare(0, 6, "cocos.") == 0)
			{
				filename = filename.substr(6);
			}
		}
		else
		{
			pos = filename.rfind(NOT_BYTECODE_FILE_EXT);
			if (pos == filename.length() - NOT_BYTECODE_FILE_EXT.length())
			{
				filename = filename.substr(0, pos);
			}
			pos = filename.find_first_of(".");
			while (pos != std::string::npos)
			{
				filename.replace(pos, 1, "/");
				pos = filename.find_first_of(".");
			}
		}

        // search file in package.path
        allocator::TJFixedMem chunk;
        std::string chunkName;
        FileUtils* utils = FileUtils::getInstance();
		bool flag = utils->isPopupNotify();
		utils->setPopupNotify(false);

        lua_getglobal(L, "package");
        lua_getfield(L, -1, "path");
        std::string searchpath(lua_tostring(L, -1));
        lua_pop(L, 1);
        size_t begin = 0;
        size_t next = searchpath.find_first_of(";", 0);

        do
        {
            if (next == std::string::npos)
                next = searchpath.length();
            std::string prefix = searchpath.substr(begin, next);
            if (prefix[0] == '.' && prefix[1] == '/')
            {
                prefix = prefix.substr(2);
            }

            pos = prefix.find("?.lua");
			if (LuaEngine::isFlatPath)
			{
				chunkName = prefix.substr(0, pos) + filename;
			}
			else
			{
				chunkName = prefix.substr(0, pos) + filename + NOT_BYTECODE_FILE_EXT;
			}
			if (utils->isFileExist(chunkName))
			{
				chunk = utils->tjGetDataFromFile(chunkName);
				break;
			}

            begin = next + 1;
            next = searchpath.find_first_of(";", begin);
        } while (begin < (int)searchpath.length());

		utils->setPopupNotify(flag);
        if (chunk.size > 0)
        {
            LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
            stack->luaLoadBuffer(L, reinterpret_cast<const char*>(chunk.bytes),
                                 static_cast<int>(chunk.size), chunkName.c_str());
        }
        else
        {
            CCLOG("can not get file data of %s", chunkName.c_str());
			// no lua error, otherwise main xpcall will goto protected mode 
			return 0;
        }
		chunk.clear();

        return 1;
    }


	// 支持win本地热加载
	int cocos2dx_lua_loader_win(lua_State *L)
	{
		//static const std::string BYTECODE_FILE_EXT    = ".luac";
		static const std::string NOT_BYTECODE_FILE_EXT = ".lua";

		// only check .lua, modify by huangwei
		std::string filename(luaL_checkstring(L, 1));
		std::string filename2;
		size_t pos = 0;

		// flat place "config.yyhuodong.drawXX" file in directory, modify by huangwei 18.3.20
		if (LuaEngine::isFlatPath)
		{
			// only special "cocos" directory, like "cocos.cocos2d.Cocos2d", it mean "cocos/cocos2d.Cocos2d"
			// because "cocos" in lua search path, so remove prefix
			if (filename.compare(0, 6, "cocos.") == 0)
			{
				filename = filename.substr(6);
			}
		}
		
		pos = filename.rfind(NOT_BYTECODE_FILE_EXT);
		if (pos == filename.length() - NOT_BYTECODE_FILE_EXT.length())
		{
			filename = filename.substr(0, pos);
		}
		filename2 = filename;

		pos = filename.find_first_of(".");
		while (pos != std::string::npos)
		{
			filename.replace(pos, 1, "/");
			pos = filename.find_first_of(".");
		}

		// search file in package.path
		allocator::TJFixedMem chunk;
		std::string chunkName;
		FileUtils* utils = FileUtils::getInstance();
		bool flag = utils->isPopupNotify();
		utils->setPopupNotify(false);

		lua_getglobal(L, "package");
		lua_getfield(L, -1, "path");
		std::string searchpath(lua_tostring(L, -1));
		lua_pop(L, 1);
		size_t begin = 0;
		size_t next = searchpath.find_first_of(";", 0);

		do
		{
			if (next == std::string::npos)
				next = searchpath.length();
			std::string prefix = searchpath.substr(begin, next);
			if (prefix[0] == '.' && prefix[1] == '/')
			{
				prefix = prefix.substr(2);
			}

			pos = prefix.find("?.lua");
			size_t pos2 = prefix.find(";");
			if (pos2 != std::string::npos) {
				pos = std::min(pos, pos2);
			}
			chunkName = prefix.substr(0, pos) + filename2;
			if (utils->isFileExist(chunkName))
			{
				chunk = utils->tjGetDataFromFile(chunkName);
				break;
			}

			chunkName = prefix.substr(0, pos) + filename + NOT_BYTECODE_FILE_EXT;
			if (utils->isFileExist(chunkName))
			{
				chunk = utils->tjGetDataFromFile(chunkName);
				break;
			}

			begin = next + 1;
			next = searchpath.find_first_of(";", begin);
		} while (begin < (int)searchpath.length());

		utils->setPopupNotify(flag);
		if (chunk.size > 0)
		{
			LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
			stack->luaLoadBuffer(L, reinterpret_cast<const char*>(chunk.bytes),
				static_cast<int>(chunk.size), chunkName.c_str());
		}
		else
		{
			CCLOG("can not get file data of %s", chunkName.c_str());
			// no lua error, otherwise main xpcall will goto protected mode 
			return 0;
		}
		// clean code buff in mem for anti cheat by huangwei 2020/4/7
		memset(chunk.bytes, '?', chunk.size);
		chunk.clear();

		return 1;
	}
}
