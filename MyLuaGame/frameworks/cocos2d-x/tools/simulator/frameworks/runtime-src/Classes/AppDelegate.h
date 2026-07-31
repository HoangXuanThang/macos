#ifndef __APP_DELEGATE_H__
#define __APP_DELEGATE_H__

#include "cocos2d.h"

#include "network/HttpClient.h"
#include "network/HttpRequest.h"

#include "assets-manager/AssetsManager.h"

enum GameStartStage
{
	GS_Launching = 0,
	GS_VersionCheck,
	GS_DownloadScripts,
	GS_RunGame,
};

/**
@brief    The cocos2d Application.

The reason for implement as private inheritance is to hide some interface call by Director.
*/
class  AppDelegate : private cocos2d::Application
{
public:
    AppDelegate();
    virtual ~AppDelegate();

    virtual void initGLContextAttrs();

    /**
    @brief    Implement Director and Scene init code here.
    @return true    Initialize success, app continue.
    @return false   Initialize failed, app terminate.
    */
    virtual bool applicationDidFinishLaunching();

    /**
    @brief  The function be called when the application enter background
    @param  the pointer of the application
    */
    virtual void applicationDidEnterBackground();

    /**
    @brief  The function be called when the application enter foreground
    @param  the pointer of the application
    */
    virtual void applicationWillEnterForeground();

	/**
    @brief  YouMi Game update
    */
	void prepareUpdate();
	bool didUpdateAndRun();
	void updateErrCallBack(int errCode);
	void updateProgressCallBack(int patchIdx,int patchCount,int nowDownloaded,int totalToDownload);
	void updateSuccessCallBack();
	void setAppFlag(int flag);

protected:
	GameStartStage _gameStage;
	std::string _scriptMd5;
	std::string _updateMd5;
	int _appFlag;
	cocos2d::extension::AssetsManager* _assertManager;
};

#endif  // __APP_DELEGATE_H__

