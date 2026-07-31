/****************************************************************************
 Copyright (c) 2013 cocos2d-x.org
 
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
#include "AssetsManager.h"
#include "VersionUtils.h"
#include "cocos2d.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include <stdio.h>
#include <vector>
#include <thread>
#include "time.h"
#include "string.h"
#include "unzip.h"
#include "external/json/document.h"
#include "ymextra/crypto/CCCrypto.h"

#if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32) && (CC_TARGET_PLATFORM != CC_PLATFORM_WP8) && (CC_TARGET_PLATFORM != CC_PLATFORM_WINRT)
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <dirent.h>
#endif

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) || (CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
#include <ftw.h>
#endif

using namespace cocos2d;
using namespace std;
USING_NS_YM_EXTRA;
NS_CC_EXT_BEGIN;

#define BUFFER_SIZE			8192
#define MAX_FILENAME		512

#define LOW_SPEED_LIMIT 1L
#define LOW_SPEED_TIME 10L


// Message type
#define ASSETSMANAGER_MESSAGE_UPDATE_SUCCEED                0
#define ASSETSMANAGER_MESSAGE_RECORD_DOWNLOADED_VERSION     1
#define ASSETSMANAGER_MESSAGE_PROGRESS                      2
#define ASSETSMANAGER_MESSAGE_ERROR                         3

// Some data struct for sending messages
static AssetsManager *s_SharedAssetsManager = nullptr;

struct ErrorMessage
{
    AssetsManager::ErrorCode code;
    AssetsManager* manager;
};

struct ProgressMessage
{
    int percent;
    AssetsManager* manager;
};

AssetsManager* AssetsManager::getInstance()
{
	if (!s_SharedAssetsManager)
	{
		CCASSERT(s_SharedAssetsManager, "FATAL: Not enough memory");
	}

	return s_SharedAssetsManager;
}

// Implementation of AssetsManager

AssetsManager::AssetsManager(const char* packageUrl/* =nullptr */, const char* versionFileUrl/* =nullptr */, const char* storagePath/* =nullptr */)
:  _storagePath(storagePath)
, _version("")
, _packageUrl(packageUrl)
, _versionFileUrl(versionFileUrl)
, _downloadedVersion("")
, _cur_appVersion("")
, _cur_patchVersion("")
, _curl(nullptr)
, _connectionTimeout(0)
, _delegate(nullptr)
, _isDownloading(false)
, _shouldDeleteDelegateWhenExit(false)
, _curlError(0)
, _patch_min_version(0)
, _isMicro(false)
, _isMicroDownloaded(false)
{
	if (!s_SharedAssetsManager)
	{
		s_SharedAssetsManager = this;
	}
	else
	{
		CCASSERT(false,"AssetsManager is Instance!!");
	}
    checkStoragePath();
	_updateOpen = true;
	_serverData.appVersion = "";
	_serverData.patchVersion = "";
}

AssetsManager::~AssetsManager()
{
    if (_shouldDeleteDelegateWhenExit)
    {
        delete _delegate;
    }
}

void AssetsManager::checkStoragePath()
{
    if (_storagePath.size() > 0 && _storagePath[_storagePath.size() - 1] != '/')
    {
        _storagePath.append("/");
    }
}

size_t getVersionCode(void *ptr, size_t size, size_t nmemb, void *userdata)
{
	AssetsManager *assetsManager = (AssetsManager*)userdata;
	assetsManager->_downBuff.append((char*)ptr, size * nmemb);

	return (size * nmemb);
}

bool AssetsManager::checkUpdate()
{
	if (_versionFileUrl.size() == 0) return false;

	_curl = curl_easy_init();
	if (! _curl)
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::CHECK_INITCURL);
			this->release();
		});
		CCLOG("can not init curl");
		return false;
	}

	// Clear _version before assign new value.
	_downBuff.clear();
	unsigned int serverappversion = 0;
	if (_serverData.appVersion != "") serverappversion = getIntValueByAppVersion(_serverData.appVersion.c_str());
	unsigned int appversion = getIntValueByAppVersion(_cur_appVersion.c_str());
	if (_serverData.appVersion != "" && serverappversion != appversion)
	{
		//需要引导玩家去appStore去下载一个最新的客户端
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::CHECK_NOT_APP_VERSION);
			this->release();
		});
		CCLOG("need goto appStore to update the lastest appVersion. it's old app: %s, new app: %s",_cur_appVersion.c_str(),_serverData.appVersion.c_str());
		return false;
	}
	else if (_serverData.patchVersion != "" && _serverData.patchVersion != _cur_patchVersion)
	{
		int localVersion = atoi(_cur_patchVersion.c_str());
		int serviceVersion = atoi(_serverData.patchVersion.c_str());
		if (localVersion > serviceVersion)
		{
			this->retain();
			Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
				if (this->_delegate)
					this->_delegate->onError(ErrorCode::CHECK_VERSION_ERROR);
				this->release();
			});
			CCLOG("localVersion %d, bigger serviceVersion %d !!!!!!!!!!!!!!!!!!!!!!!!!!!!!", localVersion,serviceVersion);
			return false;
		}
	}

	char timebuf[256], minverbuf[256];
	sprintf(timebuf, "&t=%.2f", (float)time(NULL));
	sprintf(minverbuf, "&min_patch=%d", _patch_min_version);
	std::string versionFileReqUrl = _versionFileUrl + "?channel=" + _channel + "&tag=" + _tag + "&app=" + _cur_appVersion + "&patch=" + _cur_patchVersion + minverbuf + timebuf;

	curl_easy_setopt((CURL*)_curl, CURLOPT_URL, versionFileReqUrl.c_str());
	curl_easy_setopt((CURL*)_curl, CURLOPT_SSL_VERIFYPEER, 0L);
	curl_easy_setopt((CURL*)_curl, CURLOPT_WRITEFUNCTION, getVersionCode);
	curl_easy_setopt((CURL*)_curl, CURLOPT_WRITEDATA, this);
	if (_connectionTimeout) curl_easy_setopt((CURL*)_curl, CURLOPT_CONNECTTIMEOUT, _connectionTimeout);
	curl_easy_setopt((CURL*)_curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt((CURL*)_curl, CURLOPT_LOW_SPEED_LIMIT, LOW_SPEED_LIMIT);
	curl_easy_setopt((CURL*)_curl, CURLOPT_LOW_SPEED_TIME, LOW_SPEED_TIME);
	curl_easy_setopt((CURL*)_curl, CURLOPT_FOLLOWLOCATION, 1 );
	_curlError = curl_easy_perform((CURL*)_curl);

	if ((CURL*)_curlError != 0)
	{
		_updateOpen = false;
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
			{
				if (this->_curlError == CURLE_COULDNT_CONNECT || this->_curlError == CURLE_COULDNT_RESOLVE_HOST)
					this->_delegate->onError(ErrorCode::CHECK_CONNECT);
				else
					this->_delegate->onError(ErrorCode::CHECK_NETWORK);
			}
			this->release();
		});
		CCLOG("can not get version file content, error code is %d", _curlError);
		return false;
	}

	// check version.conf
	shared_ptr<rapidjson::Document> doc(new rapidjson::Document);
	doc->Parse<rapidjson::kParseDefaultFlags>(_downBuff.data());
	if (doc->HasParseError())
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
			{
				this->_delegate->onError(ErrorCode::CHECK_NETWORK);
			}
			this->release();
		});
		CCLOG("doc HasParseError %s !!!!!!!!!!!", doc->GetParseError());
		return false;
	}
	_versionPatch = (*doc)["patch"].GetString();
	_patchUrl = (*doc)["patch_url"].GetString();
	std::string downAppVersion = (*doc)["app_version"].GetString();
	_updateOpen = true;
	if ((*doc)["_update_close_"].IsBool())
		_updateOpen = !(*doc)["_update_close_"].GetBool();
	//_updateOpen = true; // debug for update
	if (_serverData.appVersion != "")
	{
		downAppVersion = _serverData.appVersion;
	}
	if (_serverData.patchVersion != "")
	{
		_versionPatch = _serverData.patchVersion;
	}
	unsigned int downappversion =  getIntValueByAppVersion(downAppVersion.c_str());
	if (downappversion < appversion) //有可能是缓存 在login层判断
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::NO_NEW_VERSION);
		});
		CCLOG("11111 %s < %s there is already no new version",downAppVersion.c_str(),_cur_appVersion.c_str());
		return false;
	}
	else if (downappversion > appversion) //即使是缓存的数据 也比本地大，说明也要更新
	{
		//需要引导玩家去appStore去下载一个最新的客户端
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::CHECK_NOT_APP_VERSION);
			this->release();
		});
		CCLOG("22222 need goto appStore to update the lastest appVersion. it's old app: %s, new app: %s",_cur_appVersion.c_str(),downAppVersion.c_str());
		return false;
	}

	int localVersion = atoi(_cur_patchVersion.c_str());
	int serviceVersion = atoi(_versionPatch.c_str());
	// 没有更新
	// 本地版本大于等于线上版本，非微端，微端且已下载完成后
	bool noUpdate = true;
	if (_isMicro)
		noUpdate = _isMicroDownloaded;
	if (noUpdate)
		noUpdate = localVersion >= serviceVersion || !isOpen();
	if (noUpdate)
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::NO_NEW_VERSION);
		});
		CCLOG("there is already no new version");
		return false;
	}

	CCLOG("there is a new patch version: %s, local is %s, update is %s, %smicro is %s", _versionPatch.c_str(), _cur_patchVersion.c_str(), _updateOpen ? "open" : "closed", _isMicro ? "" : "non-", _isMicroDownloaded ? "downloaded" : (_isMicro ? "need" : "ok"));
	return true;
}


void AssetsManager::update()
{
	//android下 在downloadAndUpdate里面不能访问userDefault
	//SimpleAudioEngine和UserDefault能有什么共同点呢？Jni调用。没错，这两个接口底层要适配多个平台，
	//而对于Android 平台，他们都用到了Jni提供的接口去调用Java中的方法。
	//而Jni对多线程是有约束的。Android开发者官网上有这么一段话： 
	// All threads are Linux threads, scheduled by the kernel. 
	//They're usually started from managed code (using Thread.start), 
	//but they can also be created elsewhere and then attached to the JavaVM. 
	//For example, a thread started with pthread_create can be attached with the 
	//JNI AttachCurrentThread or AttachCurrentThreadAsDaemon functions.
	//Until a thread is attached, it has no JNIEnv, and cannot make JNI calls.
	VersionPlistInfo versionPlist = getLocalVersion();
	_cur_appVersion = versionPlist.app_version;
	_cur_patchVersion = versionPlist.patch;
	ChannelPlistInfo channelPlist = getChannelAndTag();
	_channel = channelPlist.channel;
	_tag = channelPlist.tag;

	_serverData.appVersion = UserDefault::getInstance()->getStringForKey(keyWithHash(KEY_OF_SERVERAPP),"");
	_serverData.patchVersion = UserDefault::getInstance()->getStringForKey(keyWithHash(KEY_OF_SERVERPATCH),"");

	_isMicro = this->isMicroPackage();
	_isMicroDownloaded = this->isMicroPackageDownloaded();
	_microUrl = this->getMicroUrl();

	curl_global_init(CURL_GLOBAL_ALL);
	auto t = std::thread(&AssetsManager::downloadAndUpdate, this);
	t.detach();
	CCLOG("AssetsManager update end");
}

bool AssetsManager::uncompress(string outFileName)
{
	// Open the zip file
	unzFile zipfile = unzOpen(outFileName.c_str());
	if (! zipfile)
	{
		CCLOG("can not open downloaded zip file %s", outFileName.c_str());
		return false;
	}

	// Get info about the zip file
	unz_global_info global_info;
	if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
	{
		CCLOG("can not read file global info of %s", outFileName.c_str());
		unzClose(zipfile);
		return false;
	}

	// Buffer to hold data read from the zip file
	char readBuffer[BUFFER_SIZE];
	std::vector<std::string> fileLists;

	CCLOG("start uncompressing");

	// Loop to extract all files.
	uLong i;
	for (i = 0; i < global_info.number_entry; ++i)
	{
		// Get info about current file.
		unz_file_info fileInfo;
		char fileName[MAX_FILENAME];
		if (unzGetCurrentFileInfo(zipfile,
			&fileInfo,
			fileName,
			MAX_FILENAME,
			NULL,
			0,
			NULL,
			0) != UNZ_OK)
		{
			CCLOG("can not read file info");
			unzClose(zipfile);
			return false;
		}

		const string fullPath = _realFileStoragePath + fileName;

		// Check if this entry is a directory or a file.
		const size_t filenameLength = strlen(fileName);
		if (fileName[filenameLength-1] == '/')
		{
			// Entry is a direcotry, so create it.
			// If the directory exists, it will failed scilently.
			if (!createDirectory(fullPath.c_str()))
			{
				CCLOG("can not create directory %s", fullPath.c_str());
				unzClose(zipfile);
				return false;
			}
		}
		else
		{
			//There are not directory entry in some case.
			//So we need to test whether the file directory exists when uncompressing file entry
			//, if does not exist then create directory
			const string fileNameStr(fileName);

			size_t startIndex=0;

			size_t index=fileNameStr.find("/",startIndex);

			while(index != std::string::npos)
			{
				const string dir = _realFileStoragePath + fileNameStr.substr(0,index);

				FILE *out = fopen(dir.c_str(), "r");

				if(!out)
				{
					if (!createDirectory(dir.c_str()))
					{
						CCLOG("can not create directory %s", dir.c_str());
						unzClose(zipfile);
						return false;
					}
					else
					{
						// CCLOG("create directory %s",dir.c_str());
					}
				}
				else
				{
					fclose(out);
				}

				startIndex=index+1;

				index=fileNameStr.find("/",startIndex);

			}

			// Entry is a file, so extract it.

			// Open current file.
			if (unzOpenCurrentFile(zipfile) != UNZ_OK)
			{
				CCLOG("can not open file %s", fileName);
				unzClose(zipfile);
				return false;
			}

			// Create a file to store current file.
			FILE *out = fopen(fullPath.c_str(), "wb");
			if (! out)
			{
				CCLOG("can not open destination file %s", fullPath.c_str());
				unzCloseCurrentFile(zipfile);
				unzClose(zipfile);
				return false;
			}

			// Write current file content to destinate file.
			int error = UNZ_OK;
			do
			{
				error = unzReadCurrentFile(zipfile, readBuffer, BUFFER_SIZE);
				if (error < 0)
				{
					CCLOG("can not read zip file %s, error code is %d", fileName, error);
					unzCloseCurrentFile(zipfile);
					unzClose(zipfile);
					return false;
				}

				if (error > 0)
				{
					fwrite(readBuffer, error, 1, out);
				}
			} while(error > 0);

			fclose(out);
			fileLists.push_back(fileName);
		}

		unzCloseCurrentFile(zipfile);

		// Goto next entry listed in the zip file.
		if ((i+1) < global_info.number_entry)
		{
			if (unzGoToNextFile(zipfile) != UNZ_OK)
			{
				CCLOG("can not read next file");
				unzClose(zipfile);
				return false;
			}
		}
	}

	const string filelist = _realFileStoragePath + "filelist";
	FILE* fp = fopen(filelist.c_str(), "wb");
	if (fp)
	{
		for (auto it = fileLists.begin(); it != fileLists.end(); it ++)
		{
			fprintf(fp, "%s\n", it->c_str());
		}
		fclose(fp);
		CCLOG("write filelist ok");
	}

	CCLOG("end uncompressing");
	unzClose(zipfile);

	return true;
}
void AssetsManager::resetSomething()
{
	UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_SERVERAPP),"");
	UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_SERVERPATCH),"");
}
void AssetsManager::seccessOver()
{
	Director::getInstance()->getScheduler()->performFunctionInCocosThread([=] {
		if (this->_delegate)
			this->_delegate->onSuccess();
		this->release();
	});
}

std::string AssetsManager::getMicroPath()
{
	char buf[256];
	VersionPlistInfo versionPlist = getLocalVersion();
	int pos = versionPlist.app_version.find_last_of('.'); //把最后一位舍掉了
	string sVersion = versionPlist.app_version.substr(0,pos);

	sprintf(buf, "%s_%d", sVersion.c_str(), 0);
	string pathPath = _storagePath + buf + "/";
	return pathPath;
}

std::string AssetsManager::getMicroUrl()
{
	// read from micro.plist
	ValueMap vm = FileUtils::getInstance()->getValueMapFromFile("res/micro.plist");
	return vm["url"].asString();
}

// NOTE: 不予许在thread调用JNI相关函数
// 否则线程结束时会有Native thread exiting without having called DetachCurrentThread报错
// 更新包在apk之外用的是fopen函数，在apk内部就会使用JNI接口
bool AssetsManager::isMicroPackage()
{
	ValueMap vm = FileUtils::getInstance()->getValueMapFromFile("res/micro.plist");
	return vm["micro"].asBool();
}

bool AssetsManager::isMicroPackageDownloaded()
{
	return FileUtils::getInstance()->isFileExist(getMicroPath() + "filelist");
}

void AssetsManager::setLocalSearchPath(bool inMain)
{
	char buf[256];
	VersionPlistInfo versionPlist = getLocalVersion();
	int oldVersion = atoi(versionPlist.patch.c_str());
	vector<string> localVersionPath;
	std::set<string> patchSearchPath;

	int pos = versionPlist.app_version.find_last_of('.'); //把最后一位舍掉了
	string sVersion = versionPlist.app_version.substr(0,pos);

	for (int iVersion = _patch_min_version+1; iVersion <= oldVersion; ++ iVersion)
	{
		sprintf(buf, "%s_%d", sVersion.c_str(),iVersion);
		string pathPath = _storagePath + buf + "/";
		localVersionPath.push_back(pathPath);

		// filelist
		if (inMain)
		{
			string data = FileUtils::getInstance()->getStringFromFile(pathPath + "filelist");
			// filelist lost?
			if (data.empty())
			{
				CCLOG("%sfilelist lost !!!", pathPath.c_str());
			}
			else
			{
				vector<string> pathFiles;
				split(data, '\n', pathFiles);
				for (auto it = pathFiles.begin(); it != pathFiles.end(); it ++)
					FileUtils::getInstance()->addPatchSearchPath(trim(*it), pathPath);
				patchSearchPath.insert(pathPath);
			}
		}
	}

	vector<string> searchPaths = FileUtils::getInstance()->getSearchPaths();
	searchPaths.insert(searchPaths.begin(), localVersionPath.rbegin(), localVersionPath.rend());
	// 0代表分包，优先级最低，并且不参与slim search
	if (inMain)
	{
		string pathPath = getMicroPath();
		searchPaths.push_back(pathPath);
	}

	vector<string> slimSearchPaths;
	if (!patchSearchPath.empty())
	{
		for (auto it = searchPaths.begin(); it != searchPaths.end(); it ++)
		{
			if (patchSearchPath.count(*it) > 0)
				CCLOG("patch %s search path ignore", it->c_str());
			else
				slimSearchPaths.push_back(*it);
		}
	}
	FileUtils::getInstance()->setSearchPaths(searchPaths);
	if (!slimSearchPaths.empty())
		FileUtils::getInstance()->setSlimSearchPaths(slimSearchPaths);

	vector<string> searchResolutionsOrders;
	searchResolutionsOrders.clear();
	FileUtils::getInstance()->setSearchResolutionsOrder(searchResolutionsOrders);
}

/*
 * Create a direcotry is platform depended.
 */
bool AssetsManager::createDirectory(const char *path)
{
#if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
    mode_t processMask = umask(0);
    int ret = mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO);
    umask(processMask);
    if (ret != 0 && (errno != EEXIST))
    {
        return false;
    }
    
    return true;
#else
    BOOL ret = CreateDirectoryA(path, nullptr);
	if (!ret && ERROR_ALREADY_EXISTS != GetLastError())
	{
		return false;
	}
    return true;
#endif
}

void AssetsManager::setSearchPath()
{
	vector<string> searchPaths = FileUtils::getInstance()->getSearchPaths();
	searchPaths.insert(searchPaths.begin(), _updateSearchs.rbegin(), _updateSearchs.rend());
	if (isMicroPackageDownloaded())
		searchPaths.push_back(getMicroPath());
	FileUtils::getInstance()->setSearchPaths(searchPaths);
	vector<string> searchResolutionsOrders;
	searchResolutionsOrders.clear();
	FileUtils::getInstance()->setSearchResolutionsOrder(searchResolutionsOrders);
}

static size_t downLoadPackage(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    FILE *fp = (FILE*)userdata;
    size_t written = fwrite(ptr, size, nmemb, fp);
	fflush(fp);
    return written;
}

int assetsManagerProgressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded)
{
	static int percent = 0;
	static double preDownloaded = 0.;
	if (totalToDownload < 1.)
		return 0;

	int tmp = (int)(nowDownloaded / totalToDownload * 100);
	auto manager = static_cast<AssetsManager*>(ptr);

	// 1% 或者 10K 刷新进度条
	if (percent != tmp || (nowDownloaded - preDownloaded) > 10*1000)
	{
		preDownloaded = nowDownloaded;
		manager->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]{
			if (manager->_delegate)
			{
				manager->_delegate->onProgress(manager->_patchIdx,manager->_patchCount,int(nowDownloaded/1000),int(totalToDownload/1000));
			}
			manager->release();
		});

		if (percent != tmp)
		{
			percent = tmp;
			CCLOG("downloading... %d/%d %d%%", manager->_patchIdx, manager->_patchCount, percent);
		}
	}

	return 0;
}
void AssetsManager::downloadAndUpdate()
{
	//checkUpdate 需要放到线程里做 不然update界面可能都出不来
	if (checkUpdate() == false)
	{
		if ((CURL*)_curl)
			curl_easy_cleanup((CURL*)_curl);
		CCLOG("AssetsManager downloadAndUpdate quick end");
		return;
	}
	this->retain();

	char buf[256];
	createDirectory(_storagePath.c_str());

	// update version one by one
	int retryErr = 0;
	int retryCount = 3;
	int oldVersion = atoi(_cur_patchVersion.c_str());
	int maxVersion = atoi(_versionPatch.c_str());
	int iVersion = std::max(oldVersion, _patch_min_version);
	string app_version = _cur_appVersion;
	vector<int> versions;

	_patchCount = maxVersion - iVersion;
	_patchIdx = 1;
	CCLOG("need %d patch to download", _patchCount);
	if (_isMicro && !_isMicroDownloaded)
	{
		CCLOG("need micro patch to download");
		versions.push_back(0); // 0 是微端包
		_patchCount ++;
	}

	// 只更新微端包，不更新普通包
	if (!isOpen())
		maxVersion = iVersion;
	for (int i = iVersion + 1; i <= maxVersion; i ++)
		versions.push_back(i);
	

	for (; _patchIdx <= versions.size() && retryErr < retryCount; ++ _patchIdx)
	{
		iVersion = versions[_patchIdx - 1];
		CCLOG("%d patch downloading...", iVersion);

		int pos = app_version.find_last_of('.'); //把最后一位舍掉了
		string nversion = app_version.substr(0,pos);
		sprintf(buf, "%s_%d", nversion.c_str(), iVersion);
		string outFileName = _storagePath + buf + ".zip";
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
		if (sizeof(void*) == 8) {
			// 64bit x64
			_realFileUrl = _patchUrl + buf + "_x64.zip";
			outFileName = _storagePath + buf + "_x64.zip";
		}
		else {
			_realFileUrl = _patchUrl + buf + ".zip";
		}
#else
		_realFileUrl = _patchUrl + buf + ".zip";
#endif
		// 如果是微端包，直接用micro.plist里的url
		if (iVersion == 0)
		{
			_realFileUrl = _microUrl;
		}

		_realFileStoragePath = _storagePath + buf + "/";
		if (! createDirectory(_realFileStoragePath.c_str()))
		{
			CCLOG("can not create directory %s", _realFileStoragePath.c_str());
			break;
		}

		if (! downLoad(outFileName))
		{
			retryErr ++;
			_patchIdx --;
			continue;
		}

		// Uncompress zip file.
		if (! uncompress(outFileName))
		{
			// Delete unloaded zip file.
			//加层防护，由于现在是断线续传，如果中间文件写烂了解压不成功，就删掉重下
			if (remove(outFileName.c_str()) != 0)
			{
				CCLOG("can not remove uncompress zip file %s", outFileName.c_str());
			}
			retryErr ++;
			_patchIdx --;
			continue;
		}

		// Delete unloaded zip file.
		if (remove(outFileName.c_str()) != 0)
		{
			CCLOG("can not remove downloaded zip file %s", outFileName.c_str());
		}
		
		// 验证里面version.plist里的app_version 以及patch 是不是符合
		std::string tmp_path = _realFileStoragePath + "res/version.plist";
		ValueMap vm = FileUtils::getInstance()->getValueMapFromFile(tmp_path); //第一次读大版本以及patch需要读原始目录下的
		std::string tmp_version = vm["app_version"].asString();
		int t_pos = tmp_version.find_last_of('.'); //把最后一位舍掉了
		std::string t_version = tmp_version.substr(0,t_pos);
		int patchVersion = atoi(vm["patch"].asString().c_str());
		if (patchVersion != iVersion || t_version != nversion)
		{
			retryErr ++;
			_patchIdx --;
			CCLOG("zip file %s is so strange !!!!!!", outFileName.c_str());
			continue;
		}
		// 成功保存版本号，在主线程
		// 微端包0版本号不保存
		if (iVersion > 0)
		{
			Director::getInstance()->getScheduler()->performFunctionInCocosThread([=] {
				char tmp[16];
				sprintf(tmp, "%d", iVersion);
				std::string tt = tmp;
				UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_VERSION), tt);
				UserDefault::getInstance()->flush();
			});
		}
		else if (iVersion == 0)
		{
			_isMicroDownloaded = true;
		}
	}

	curl_easy_cleanup((CURL*)_curl);

	if (retryErr >= retryCount || _patchIdx != versions.size() + 1)
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([=]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::UNCOMPRESS);
			this->release();
		});

		this->release();
		return;
	}

	// 不包含0微端版本
	_updateSearchs.clear();
	for (iVersion = oldVersion + 1; iVersion <= maxVersion; ++ iVersion)
	{
		int pos = app_version.find_last_of('.'); //把最后一位舍掉了
		string nversion = app_version.substr(0,pos);
		sprintf(buf, "%s_%d", nversion.c_str(),iVersion);
		_updateSearchs.push_back(_storagePath + buf + "/");
	}

	this->retain(); // release when call seccessOver from lua
	Director::getInstance()->getScheduler()->performFunctionInCocosThread([=] {
		char tmp[16];
		sprintf(tmp, "%d", maxVersion);
		std::string tt = tmp;
		UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_VERSION), tt);
		UserDefault::getInstance()->flush();

		// Set resource search path.
		this->setSearchPath();
		if (this->_delegate)
			this->_delegate->onError(ErrorCode::NO_NEW_VERSION);
	});

	this->release();
	CCLOG("AssetsManager downloadAndUpdate end");
}

bool AssetsManager::downLoad(string outFileName)
{
	// Create a file to save package.
	// FILE *fp = fopen(outFileName.c_str(), "wb");
	ssize_t outFileLength = 0;
	FILE *fp = fopen(outFileName.c_str(), "ab");
	if (fp)
	{
		fseek(fp, 0, SEEK_END);
		outFileLength = ftell(fp);
		// 小于10M的重新下
		if (outFileLength < 10 * 1024 * 1024)
		{
			fclose(fp);
			fp = fopen(outFileName.c_str(), "wb");
			outFileLength = 0;
		}
	}
	if (!fp)
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this] {
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::CREATE_FILE);
			this->release();
		});
		CCLOG("can not create file %s", outFileName.c_str());
		return false;
	}

	// Download pacakge
	CURLcode res;
	curl_easy_setopt((CURL*)_curl, CURLOPT_URL, _realFileUrl.c_str());
	curl_easy_setopt((CURL*)_curl, CURLOPT_WRITEFUNCTION, downLoadPackage);
	curl_easy_setopt((CURL*)_curl, CURLOPT_WRITEDATA, fp);
	curl_easy_setopt((CURL*)_curl, CURLOPT_NOPROGRESS, false);
	curl_easy_setopt((CURL*)_curl, CURLOPT_PROGRESSFUNCTION, assetsManagerProgressFunc);
	curl_easy_setopt((CURL*)_curl, CURLOPT_PROGRESSDATA, this);
	curl_easy_setopt((CURL*)_curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt((CURL*)_curl, CURLOPT_LOW_SPEED_LIMIT, LOW_SPEED_LIMIT);
	curl_easy_setopt((CURL*)_curl, CURLOPT_LOW_SPEED_TIME, LOW_SPEED_TIME);
	curl_easy_setopt((CURL*)_curl, CURLOPT_FOLLOWLOCATION, 1);
	curl_easy_setopt((CURL*)_curl, CURLOPT_RESUME_FROM, outFileLength); //多个包的时候 第二次进来需要重置为0

	res = curl_easy_perform((CURL*)_curl);
	if (res != 0)
	{
		this->retain();
		Director::getInstance()->getScheduler()->performFunctionInCocosThread([&, this]{
			if (this->_delegate)
				this->_delegate->onError(ErrorCode::NETWORK);
			this->release();
		});
		CCLOG("error %d when download package %s", res, _realFileUrl.c_str());
		fclose(fp);
		return false;
	}

	CCLOG("succeed downloading package %s", _realFileUrl.c_str());

	fclose(fp);
	return true;
}

const char* AssetsManager::getPackageUrl() const
{
    return _packageUrl.c_str();
}

void AssetsManager::setPackageUrl(const char *packageUrl)
{
    _packageUrl = packageUrl;
}

const char* AssetsManager::getStoragePath() const
{
    return _storagePath.c_str();
}

void AssetsManager::setStoragePath(const char *storagePath)
{
    _storagePath = storagePath;
    checkStoragePath();
}

const char* AssetsManager::getVersionFileUrl() const
{
    return _versionFileUrl.c_str();
}

void AssetsManager::setVersionFileUrl(const char *versionFileUrl)
{
    _versionFileUrl = versionFileUrl;
}
void AssetsManager::setPatchMinVersion(int patchMinV)
{
	_patch_min_version = patchMinV;
}
int AssetsManager::getPatchMinVersion()
{
	return _patch_min_version;
}

void AssetsManager::setDelegate(AssetsManagerDelegateProtocol *delegate)
{
    _delegate = delegate;
}

void AssetsManager::setConnectionTimeout(unsigned int timeout)
{
    _connectionTimeout = timeout;
}

unsigned int AssetsManager::getConnectionTimeout()
{
    return _connectionTimeout;
}

AssetsManager* AssetsManager::create(const char* packageUrl, const char* versionFileUrl, const char* storagePath, ErrorCallback errorCallback, ProgressCallback progressCallback, SuccessCallback successCallback )
{
    class DelegateProtocolImpl : public AssetsManagerDelegateProtocol 
    {
    public :
        DelegateProtocolImpl(ErrorCallback aErrorCallback, ProgressCallback aProgressCallback, SuccessCallback aSuccessCallback)
        : errorCallback(aErrorCallback), progressCallback(aProgressCallback), successCallback(aSuccessCallback)
        {}

        virtual void onError(AssetsManager::ErrorCode errorCode) { errorCallback(int(errorCode)); }
        virtual void onProgress(int patchIdx,int patchCount,int nowDownloaded,int totalToDownload) { progressCallback(patchIdx,patchCount,nowDownloaded,totalToDownload); }
        virtual void onSuccess() { successCallback(); }

    private :
        ErrorCallback errorCallback;
        ProgressCallback progressCallback;
        SuccessCallback successCallback;
    };
    auto* manager = new AssetsManager(packageUrl,versionFileUrl,storagePath);
    auto* delegate = new DelegateProtocolImpl(errorCallback,progressCallback,successCallback);
    manager->setDelegate(delegate);
    manager->_shouldDeleteDelegateWhenExit = true;
    manager->autorelease();

	//重新打包大版本更新后直接下载下来 不会把原有旧的用户信息目录全删了，这样会导致
	//UserDefault.xml 还是旧的保存在那里 ，这样里面保存的patch等信息就会有问题
	//刚开启客户端检测下UserDefault里的app_version与version.plist里的app_version是否一致，不一致就把UserDefault里的个别信息重置
	//还有种情况，玩家当前版本更新了一个版本后 不删掉重新去下载覆盖，这样是没问题的，因为本地文件原来的 更新包 userdefault(在ios下改名了，在library下)等文件都不会删掉
	auto utils = FileUtils::getInstance();
	ValueMap vm = utils->getValueMapFromFile("res/version.plist"); //第一次读大版本以及patch需要读原始目录下的
	manager->setPatchMinVersion(atoi(vm["patch"].asString().c_str()));
	VersionPlistInfo versionPlist = getLocalVersion();
	unsigned int localappversion = getIntValueByAppVersion(versionPlist.app_version.c_str());
	unsigned int appversion = getIntValueByAppVersion(vm["app_version"].asString().c_str());
	if (localappversion != appversion)
	{
		manager->destroyStoragePath();
		UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_APPVERSION),vm["app_version"].asString());
		UserDefault::getInstance()->setStringForKey(keyWithHash(KEY_OF_VERSION),vm["patch"].asString());
		manager->resetSomething();
	}
	manager->setLocalSearchPath(false);

	vm = utils->getValueMapFromFile("res/version.plist");
	manager->setVersionFileUrl(vm["versionUrl"].asString().c_str());

    return manager;
}

void AssetsManager::createStoragePath()
{
    // Remove downloaded files
// #if (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
//     DIR *dir = nullptr;
//     
//     dir = opendir (_storagePath.c_str());
//     if (!dir)
//     {
//         mkdir(_storagePath.c_str(), S_IRWXU | S_IRWXG | S_IRWXO);
//     }
// #else    
//     if ((GetFileAttributesA(_storagePath.c_str())) == INVALID_FILE_ATTRIBUTES)
//     {
//         CreateDirectoryA(_storagePath.c_str(), 0);
//     }
// #endif
}
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) || (CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
static int unlink_cb(const char *fpath, const struct stat *sb, int typeflag, struct FTW *ftwbuf)
{
	auto ret = remove(fpath);
	if (ret)
	{
		log("Fail to remove: %s ",fpath);
	}

	return ret;
}
#endif
void AssetsManager::destroyStoragePath()
{
    // Delete recorded version codes.
    //deleteVersion();
    
    // Remove downloaded files
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS) || (CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
	if (nftw(_storagePath.c_str(),unlink_cb, 64, FTW_DEPTH | FTW_PHYS))
	{
		CCLOG("ios nftw failed!!");
	}
	else
	{
		CCLOG("ios nftw ok!!");
	}
#elif (CC_TARGET_PLATFORM != CC_PLATFORM_WIN32)
    string command = "rm -r ";
    // Path may include space.
    command += "\"" + _storagePath + "\"";
    int ret = system(command.c_str());    
	CCLOG("command = %s,ret = %d", command.c_str(),ret);
#else
    string command = "rd /s /q ";
    // Path may include space.
    command += "\"" + _storagePath + "\"";
    system(command.c_str());
#endif
}
NS_CC_EXT_END;
