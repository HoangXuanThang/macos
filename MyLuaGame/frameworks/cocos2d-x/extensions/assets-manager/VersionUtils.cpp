#include "cocos2d.h"
#include "VersionUtils.h"

#include "external/json/document-wrapper.h"
#include "ymextra/crypto/CCCrypto.h"

using namespace cocos2d;
using namespace std;


// Multiple key names
char* keyWithHash(const char* key)
{
	static char buf[256];
	sprintf(buf, "%s", CCCrypto::MD5String((void*)key, strlen(key)).c_str());
	//sprintf(buf,"%X", std::hash<const char*>()(key));
	return buf;
}

std::vector<std::string> & split(const std::string &s, char delim, std::vector<std::string> &elems)
{
	std::stringstream ss(s);
	std::string item;
	while (std::getline(ss, item, delim)) {
		elems.push_back(item);
	}
	return elems;
}

std::string trim(const std::string& str)
{
	if (str.empty())
		return str;
	auto len = str.length();
	char c = str[len - 1];
	while (c == '\r' || c == '\n')
	{
		len--;
		c = str[len - 1];
	}
	return str.substr(0, len);
}

// 优先读取UserDefault，并非原始version.plist
VersionPlistInfo getLocalVersion()
{
	auto userDefault = UserDefault::getInstance();
	auto utils = FileUtils::getInstance();
	VersionPlistInfo info;
	ValueMap vm = utils->getValueMapFromFile("res/version.plist");

	// app_version
	info.app_version = userDefault->getStringForKey(keyWithHash(KEY_OF_APPVERSION));
	if (info.app_version.empty())
	{
		userDefault->setStringForKey(keyWithHash(KEY_OF_APPVERSION), vm["app_version"].asString());
		info.app_version = userDefault->getStringForKey(keyWithHash(KEY_OF_APPVERSION));
	}

	// patch
	info.patch = userDefault->getIntegerForKey(keyWithHash(KEY_OF_VERSION));
	if (info.patch == 0)
	{
		userDefault->setIntegerForKey(keyWithHash(KEY_OF_VERSION), vm["patch"].asInt());
		info.patch = userDefault->getIntegerForKey(keyWithHash(KEY_OF_VERSION));
	}

	// versionUrl
	info.versionUrl = vm["versionUrl"].asString();

	// reportUrl
	info.reportUrl = vm["reportUrl"].asString();

	// forShenhe
	info.forShenhe = vm["forShenhe"].asBool();

	// forOBB
	info.forOBB = vm["forOBB"].asBool();
	return info;
}

ChannelPlistInfo getChannelAndTag()
{
	auto utils = FileUtils::getInstance();
	ValueMap vm = utils->getValueMapFromFile("res/channel.plist");
	ChannelPlistInfo info;
	info.channel = vm["channel"].asString();
	info.tag = vm["tag"].asString();
	return info;
}

unsigned int getIntValueByAppVersion(const char* key)
{
	std::vector<std::string> vec;
	std::string ss;
	ss = key;
	split(ss, '.', vec);
	unsigned int ret = 0;
	int left = 0;
	for (int i = vec.size() - 2; i >= 0; i--) //把最后一位舍掉
	{
		int t = atoi(vec[i].c_str());
		ret += (t << left);
		left += 8;
	}
	return ret;
}

std::string getAppMajorVersion(const std::string& app_version)
{
	//把最后一位舍掉了
	int pos = app_version.find_last_of('.');
	return app_version.substr(0, pos);
}

std::string getMicroPathInStorage()
{
	char buf[256];
	VersionPlistInfo versionPlist = getLocalVersion();
	std::string majorVersion = getAppMajorVersion(versionPlist.app_version);

	//sprintf(buf, "%s_%d/", majorVersion.c_str(), 0);
    sprintf(buf, "%d/", 0);
	return buf;
}

bool parseDiff(const std::string& diffdata, DiffInfo& info)
{
	shared_ptr<rapidjson::Document> doc(new rapidjson::Document);
	doc->Parse<rapidjson::kParseDefaultFlags>(diffdata.data());
	if (doc->HasParseError())
		return false;

	info.patch = (*doc)["patch"].GetInt();
	info.patch_url = (*doc)["patch_url"].GetString();
	info.app_version = (*doc)["app_version"].GetString();
	info.update_close = false;
	if ((*doc)["update_close"].IsBool())
		info.update_close = (*doc)["update_close"].GetBool();
	auto filesArray = (*doc)["files"].GetArray();
	for (rapidjson::Value::ConstValueIterator it = filesArray.Begin(); it != filesArray.End(); ++it)
	{
		const auto& obj = it->GetObject();
		PatchFileInfo fileInfo;
		fileInfo.name = obj["name"].GetString();
		fileInfo.md5 = obj["md5"].GetString();
		fileInfo.patch = obj["patch"].GetInt();
		fileInfo.size = obj["size"].GetInt();
		info.files.push_back(fileInfo);
	}
	return true;
}

// urlencode
unsigned char ToHex(unsigned char x)
{
    return  x > 9 ? x + 55 : x + 48;
}

unsigned char FromHex(unsigned char x)
{
    unsigned char y;
    if (x >= 'A' && x <= 'Z') y = x - 'A' + 10;
    else if (x >= 'a' && x <= 'z') y = x - 'a' + 10;
    else if (x >= '0' && x <= '9') y = x - '0';
    else assert(0);
    return y;
}

std::string UrlEncode(const std::string& str)
{
    std::string strTemp = "";
    size_t length = str.length();
    for (size_t i = 0; i < length; i++)
    {
        if (isalnum((unsigned char)str[i]) ||
            (str[i] == '-') ||
            (str[i] == '_') ||
            (str[i] == '.') ||
            (str[i] == '~'))
            strTemp += str[i];
        else if (str[i] == ' ')
            strTemp += "+";
        else
        {
            strTemp += '%';
            strTemp += ToHex((unsigned char)str[i] >> 4);
            strTemp += ToHex((unsigned char)str[i] % 16);
        }
    }
    return strTemp;
}

std::string UrlDecode(const std::string& str)
{
    std::string strTemp = "";
    size_t length = str.length();
    for (size_t i = 0; i < length; i++)
    {
        if (str[i] == '+') strTemp += ' ';
        else if (str[i] == '%')
        {
            assert(i + 2 < length);
            unsigned char high = FromHex((unsigned char)str[++i]);
            unsigned char low = FromHex((unsigned char)str[++i]);
            strTemp += high*16 + low;
        }
        else strTemp += str[i];
    }
    return strTemp;
}

