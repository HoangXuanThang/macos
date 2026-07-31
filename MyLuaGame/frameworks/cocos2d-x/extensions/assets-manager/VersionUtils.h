#pragma once

#ifndef __VersionUtils__
#define __VersionUtils__

#include <string>
#include <vector>

#include "cocos2d.h"
#include "extensions/ExtensionExport.h"
#include "ymextra/ymextra.h"

#define KEY_OF_APPVERSION			"tianji_app1"
#define KEY_OF_VERSION				"tianji_version2"
#define KEY_OF_SERVERAPP			"tianji_serv_app3"
#define KEY_OF_SERVERPATCH			"tianji_serv_patch4"

CC_EX_DLL char* keyWithHash(const char* key);
CC_EX_DLL std::vector<std::string>& split(const std::string &s, char delim, std::vector<std::string> &elems);
CC_EX_DLL std::string trim(const std::string& str);

struct CC_EX_DLL ChannelPlistInfo
{
	std::string channel;
	std::string tag;
};

struct CC_EX_DLL VersionPlistInfo
{
	std::string app_version;
	int patch;
	std::string versionUrl;
	std::string reportUrl;
	bool forShenhe;
	bool forOBB;
};

struct CC_EX_DLL PatchFileInfo
{
	std::string name;
	std::string md5;
	int patch;
	size_t size;
};

struct CC_EX_DLL DiffInfo
{
	std::string app_version;
	int patch;
	std::string patch_url;
	bool update_close;
	std::vector<PatchFileInfo> files;
};


CC_EX_DLL VersionPlistInfo getLocalVersion();
CC_EX_DLL ChannelPlistInfo getChannelAndTag();
CC_EX_DLL unsigned int getIntValueByAppVersion(const char* key);
CC_EX_DLL std::string getAppMajorVersion(const std::string& app_version);
CC_EX_DLL std::string getMicroPathInStorage();
CC_EX_DLL bool parseDiff(const std::string& diffdata, DiffInfo& info);
CC_EX_DLL std::string UrlEncode(const std::string& str);
CC_EX_DLL std::string UrlDecode(const std::string& str);

#endif // __VersionUtils__
