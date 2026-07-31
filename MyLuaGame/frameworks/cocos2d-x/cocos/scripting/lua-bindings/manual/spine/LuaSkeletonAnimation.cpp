 /****************************************************************************
 Copyright (c) 2013      Edward Zhou
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

#include "scripting/lua-bindings/manual/spine/LuaSkeletonAnimation.h"

#include "scripting/lua-bindings/manual/cocos2d/LuaScriptHandlerMgr.h"
#include "scripting/lua-bindings/manual/CCLuaStack.h"
#include "scripting/lua-bindings/manual/CCLuaEngine.h"

#include "base/ccMacros.h"

using namespace spine;

TJ_PROFILE_DOMAIN_LINK(__spine);

USING_NS_CC;

static int SpineObjCount = 0;

LuaSkeletonAnimation::LuaSkeletonAnimation ()
: spine::SkeletonAnimation()
{
	SpineObjCount++;
}


LuaSkeletonAnimation::~LuaSkeletonAnimation()
{
	SpineObjCount--;
    ScriptHandlerMgr::getInstance()->removeObjectAllHandlers((void*)this);
}

TJ_PROFILE_TASK_DEF(__createWithFile);
LuaSkeletonAnimation* LuaSkeletonAnimation::createWithFile (const char* skeletonDataFile, const char* atlasFile, float scale)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__spine, __createWithFile);
	LuaSkeletonAnimation* node = new (std::nothrow) LuaSkeletonAnimation();
	if (strstr(skeletonDataFile, ".json") != nullptr)
	{
		node->initWithJsonFile(skeletonDataFile, atlasFile, scale);
	}
	else
	{
		node->initWithBinaryFile(skeletonDataFile, atlasFile, scale);
	}
	node->autorelease();
#if COCOS2D_DEBUG >= 1
	node->filename = skeletonDataFile;
#endif
	TJ_PROFILE_DOMAIN_TASK_END(__spine);
	return node;
}
