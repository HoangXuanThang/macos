#include "AppDelegate.h"
#include "CCLuaEngine.h"
#include "SimpleAudioEngine.h"
#include "cocos2d.h"
//#include "ymextra/crypto/CCCrypto.h"


// for simulator
#include "runtime/ConfigParser.h"


using namespace CocosDenshion;

USING_NS_CC;
USING_NS_CC_EXT;
using namespace std;

const char* kCompanyShortName = "You_Mi";
const char* kCompanyName = "YouMi Information Technology Inc.";

/*
历代iPad和iPhone分辨率
	iPad 1代、iPad 2代和iPad Mini的分辨率：1024 x 768
	iPad 3代和iPad 4代的分辨率（Retina屏幕）：2048 x 1536
	iPhone 1代，iPhone3G，iPhone 3GS的分辨率：480 x 320
	iPhone 4，iPhone 4S的分辨率：960 x 640
	iPhone 5的分辨率：1136 x 640
	iPhone 5s，iPhone 5c的分辨率：1136 x 640
*/

AppDelegate::AppDelegate()
{
	_appFlag = 0;
	_assertManager = nullptr;
}

AppDelegate::~AppDelegate()
{
    SimpleAudioEngine::end();
	network::HttpClient::destroyInstance();
	ScriptEngineManager::getInstance()->destroyInstance();
	PoolManager::getInstance()->destroyInstance();
}

// if you want a different context, modify the value of glContextAttrs
// it will affect all platforms
void AppDelegate::initGLContextAttrs()
{
	// set OpenGL context attributes: red,green,blue,alpha,depth,stencil
	GLContextAttrs glContextAttrs = { 8, 8, 8, 8, 24, 8 };

	GLView::setGLContextAttrs(glContextAttrs);
}

bool AppDelegate::applicationDidFinishLaunching()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	//TestinCrashHelper::initTestinAgent("34178e9091b196510417b94c18a40532", "Channel_UM_test");
#endif
	_gameStage = GS_Launching;

    // initialize director
    auto director = Director::getInstance();
	auto glview = director->getOpenGLView();
	auto utils = FileUtils::getInstance();
	float gameWidth = 1136, gameHeight = 640;
	//float gameWidth = 960, gameHeight = 640;
	//float gameWidth = 1024, gameHeight = 768;

	if(!glview) {
		auto size = ConfigParser::getInstance()->getInitViewSize();
		glview->setFrameSize(size.width, size.height);
        //glview = GLView::createWithRect("game01", cocos2d::Rect(0,0,gameWidth,gameHeight));
		director->setOpenGLView(glview);
	}

    glview->setDesignResolutionSize(1136, 640, ResolutionPolicy::FIXED_HEIGHT);

    // turn on display FPS
    director->setDisplayStats(true);

    // set FPS. the default value is 1.0/60 if you don't call this
    director->setAnimationInterval(1.0 / 60);

	ZipUtils::setPvrEncryptionKey(0x37e2e2bc, 0x0953aced, 0xc06c1c75, 0xff4fee3b); //pvr.ccz的key
	// update
	prepareUpdate();
	didUpdateAndRun();
    
    // Override point for customization after application launch.
    
    // Override point for customization after application launch.
 
    
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
    Director::getInstance()->stopAnimation();

    SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
    Director::getInstance()->startAnimation();

    SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
}

//////////////////////////////////////////////////////////////////////////
using namespace network;

static char _toConfuse(char ch)
{
	if (ch >= 'a' && ch <= 'z') return ch - 'a' + 'A';
	else if (ch == '_') return '+';
	else if (ch == '.' || ch == '6') return ';';
	return ch;
}

static std::string _toLuaPwd(std::string version)
{
	// for code confusion
	// 1. a = _toConfuse("5A"+kCompanyShortName+"er+."+kCompanyShortName)
	// 2. b = MD5(a) + string("6A"+version+kCompanyShortName)
	// 3. c = _toConfuse(b)
	// 4. d = reverse(c)
	// 5. e = MD5(d)
	return "TODO:";
// 	int pos = version.find_last_of('.'); //把最后一位舍掉了
// 	std::string confusion = kCompanyShortName;
// 	confusion = "5A" + confusion + "er+." + confusion;
// 	std::transform(confusion.begin(), confusion.end(), confusion.begin(), _toConfuse);
// 	std::string updatePass = ymextra::CCCrypto::MD5String((void*)confusion.c_str(), confusion.length());
// 	updatePass += "6A" + version.substr(0,pos) + kCompanyShortName;
// 	std::transform(updatePass.begin(), updatePass.end(), updatePass.begin(), _toConfuse);
// 	std::reverse(updatePass.begin(), updatePass.end());
// 	return ymextra::CCCrypto::MD5String((void*)updatePass.c_str(), updatePass.length());
}


// update flow:
// get remote version.conf            +------------+
//          +                         | updater.lua|
//          |                         +------------+
//          v     yes                 |            |
//       app old?+--->exit,           |     UI     |
//          +         update in store |            |
//          |                         |            |
//          v         no              |            |
//     version old?+------+           |            |
//          +             |           |            |
//          |             |           |            |
//          v             |  callback |            |
//  download and update+---------------->  55%     |
//          +             |           |            |
//          |             |           |            |
//          v             |           |            |
//  set path and reload   |           |            |
//          +             |           |            |
//          |             |           |            |
//          v             |           |            |
//      run game <--------+           +------------+
//
bool AppDelegate::didUpdateAndRun()
{
	_gameStage = GS_VersionCheck;

	_assertManager->update();

	return true;
}

void AppDelegate::prepareUpdate()
{
	std::string storagePath = FileUtils::getInstance()->getWritablePath() + "patch/";
	_assertManager = AssetsManager::create("", "", storagePath.c_str(),
		CC_CALLBACK_1(AppDelegate::updateErrCallBack, this),
		CC_CALLBACK_4(AppDelegate::updateProgressCallBack, this),
		CC_CALLBACK_0(AppDelegate::updateSuccessCallBack, this));
	_assertManager->retain();
	_assertManager->setConnectionTimeout(8);

	auto engine = LuaEngine::getInstance();
	ScriptEngineManager::getInstance()->setScriptEngine(engine);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	//TestinLuaExceptionHandler::registerLuaExceptionHandler();
	LuaStack* stack = engine->getLuaStack();
	lua_getglobal(stack->getLuaState(), "_G");
	// tolua_anysdk_open(stack->getLuaState());
	// tolua_anysdk_manual_open(stack->getLuaState());
	lua_pop(stack->getLuaState(), 1);
#endif
	auto utils = FileUtils::getInstance();
	if (utils->isFileExist("updater.zip") || utils->isFileExist("updater_x64.zip"))
	{
		std::string pwd = _toLuaPwd(_assertManager->getLocalAppVersion()); //要取大版本号
		engine->getLuaStack()->setXXTEAKeyAndSign(pwd.c_str(), pwd.length(), kCompanyShortName, strlen(kCompanyShortName));
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
		if (sizeof(void*) == 8) {
			// 64bit x64
			engine->getLuaStack()->loadChunksFromZIP("cocos_x64.zip");
			engine->getLuaStack()->loadChunksFromZIP("updater_x64.zip");
		}
		else {
			engine->getLuaStack()->loadChunksFromZIP("cocos.zip");
			engine->getLuaStack()->loadChunksFromZIP("updater.zip");
		}
#else
		engine->getLuaStack()->loadChunksFromZIP("cocos.zip");
		engine->getLuaStack()->loadChunksFromZIP("updater.zip");
#endif
	}
	else
	{
		//正式游戏中走的都是.zip，这两项不会加进去的
		utils->addSearchResolutionsOrder("cocos");
		utils->addSearchResolutionsOrder("updater");
	}

	// load updater screen
	if (engine->executeString("require 'main'"))
	{
	}
	
}


void AppDelegate::updateErrCallBack(int errCode)
{
	//调到这函数就要保证update的lua engine还没释放
	char buf[256];
	sprintf(buf, "errorCallBack(%d)", errCode);
	auto engine = LuaEngine::getInstance();
	engine->executeString(buf);
}
void AppDelegate::setAppFlag(int flag)
{
	_appFlag = flag;
}
void AppDelegate::updateProgressCallBack(int patchIdx,int patchCount,int nowDownloaded,int totalToDownload)
{
	char buf[256];
	sprintf(buf, "progressCallBack(%d,%d,%d,%d)", patchIdx,patchCount,nowDownloaded,totalToDownload);
	auto engine = LuaEngine::getInstance();
	engine->executeString(buf);
}

void AppDelegate::updateSuccessCallBack()
{
	_gameStage = GS_RunGame;
	
	// remove old lua engine
	ScriptEngineManager::getInstance()->removeScriptEngine();

	// new lua engine and run
	auto engine = LuaEngine::getInstance();
	ScriptEngineManager::getInstance()->setScriptEngine(engine);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	//TestinLuaExceptionHandler::registerLuaExceptionHandler();
	LuaStack* stack = engine->getLuaStack();
	lua_getglobal(stack->getLuaState(), "_G");
	// tolua_anysdk_open(stack->getLuaState());
	// tolua_anysdk_manual_open(stack->getLuaState());
	lua_pop(stack->getLuaState(), 1);
#endif
	// rebuild search path
	auto utils = FileUtils::getInstance();
	std::vector<std::string> emptyVec;
	utils->setSearchPaths(emptyVec);
	_assertManager->setLocalSearchPath(true);
	_assertManager->resetSomething();

	// load lua
	if (_appFlag == 0)
	{
		if (utils->isFileExist("scripts.zip") || utils->isFileExist("scripts_x64.zip"))
		{
			std::string pwd = _toLuaPwd(_assertManager->getLocalAppVersion()); //要取大版本号
			engine->getLuaStack()->setXXTEAKeyAndSign(pwd.c_str(), pwd.length(), kCompanyShortName, strlen(kCompanyShortName));
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
//			if (sizeof(void*) == 8) {
				// 64bit x64
				engine->getLuaStack()->loadChunksFromZIP("cocos_x64.zip");
				engine->getLuaStack()->loadChunksFromZIP("scripts_x64.zip");
//			}
//			else {
//				engine->getLuaStack()->loadChunksFromZIP("cocos.zip");
//				engine->getLuaStack()->loadChunksFromZIP("scripts.zip");
//			}
#else
			engine->getLuaStack()->loadChunksFromZIP("cocos.zip");
			engine->getLuaStack()->loadChunksFromZIP("scripts.zip");
#endif
		}
		else
		{
			//正式游戏中走的都是.zip，这两项不会加进去的
			utils->addSearchResolutionsOrder("cocos");
			utils->addSearchResolutionsOrder("scripts");
		}
	}
	else if(_appFlag == 1)
	{
		//robot Test客户端
		utils->addSearchResolutionsOrder("cocos");
		utils->addSearchResolutionsOrder("robot");
	}
	else if(_appFlag == 2)
	{
		//robot Test客户端
		utils->addSearchResolutionsOrder("cocos");
		utils->addSearchResolutionsOrder("scripts_shenhe");
	}
	_assertManager->release(); // bug? or auto release
	// pop updater screen
	Director::getInstance()->popToSceneStackLevel(0);

	// run lua
	if (engine->executeString("require 'main'"))
	{
	}
}
