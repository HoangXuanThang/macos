#include "cocos2d.h"
#include "Difflist.h"
#include <unordered_set>

#include "VersionUtils.h"
#include "ymextra/crypto/CCCrypto.h"

// {"app_version":"1.3.0.888","version":"1.3.0.888","patch":4,"patch_url":"http://192.168.1.96:8008/","update_close":false,"files":[]}

NS_CC_EXT_BEGIN

Difflist::Difflist()
: _updateClose(false)
{
}

void Difflist::genResumeAssetsList(DownloadUnits *units)
{
	for (auto it = _assets.begin(); it != _assets.end(); ++it)
	{
		Asset& asset = it->second;

		//if (asset.downloadState != DownloadState::SUCCESSED && asset.downloadState != DownloadState::UNMARKED)
		{
			DownloadUnit unit;
			unit.customId = it->first;
			// for shenhe to avoid cdn cache by huangwei 19/11/20
			if (asset.patch.compare("0") == 0 && !_shenheVersion.empty())
			{
				unit.srcUrl = _packageUrl + "0/" + _shenheVersion + "/" + asset.path;
			}
			else
			{
				unit.srcUrl = _packageUrl + asset.patch + "/" + asset.path;
			}
			unit.storagePath = _manifestRoot + asset.path;
			unit.size = asset.size;
            
            //unit.srcUrl = UrlEncode(unit.srcUrl);
            if (_fileUtils->isFileExist(unit.storagePath))
            {
				// read raw file content
				Data cdata = _fileUtils->getRawDataFromFile(unit.storagePath);
                //Data cdata = _fileUtils->getDataFromFile(unit.storagePath);
                if (cdata.getSize() == unit.size)
                {
                    std::string md5str = CCCrypto::MD5String((void*)cdata.getBytes(), cdata.getSize());
                    if (md5str == asset.md5)
                    {
                        asset.downloadState = Manifest::DownloadState::SUCCESSED;
                        continue;
                    }
                }
            }
            
			units->emplace(unit.customId, unit);
            asset.downloadState = Manifest::DownloadState::UNSTARTED;
		}
	}
}

void Difflist::prependSearchPaths()
{
	// no use it
	// see AssetsManagerEx::prepareLocalManifest()
}

void Difflist::parse(const std::string& manifestUrl)
{
	loadJson(manifestUrl);

	if (!_json.HasParseError() && _json.IsObject())
	{
		// Register the local manifest root
		size_t found = manifestUrl.find_last_of("/\\");
		if (found != std::string::npos)
		{
			_manifestRoot = manifestUrl.substr(0, found + 1);
		}
		loadVersion(_json);
		loadManifest(_json);
	}
}

void Difflist::loadVersion(const rapidjson::Document &json)
{
	// Retrieve package url
	_packageUrl = json["patch_url"].GetString();
	const char* psz = json["shenhe_version"].GetString();
	if (psz)
		_shenheVersion = psz;

	// Append automatically "/"
	if (_packageUrl.size() > 0 && _packageUrl.back() != '/')
	{
		_packageUrl.append("/");
	}

	char buf[256];
	_version = json["app_version"].GetString();
	int patch = json["patch"].GetInt();
	sprintf(buf, "%d", patch);
	_patch = buf;
	if (json["update_close"].IsBool())
		_updateClose = json["update_close"].GetBool();

	_versionLoaded = true;
}


void Difflist::loadManifest(const rapidjson::Document &json)
{
	char buf[256];
	auto filesArray = json["files"].GetArray();
	for (rapidjson::Value::ConstValueIterator it = filesArray.Begin(); it != filesArray.End(); ++it)
	{
		const auto& obj = it->GetObject();
		ManifestAsset asset;
		asset.path = obj["name"].GetString();
		asset.md5 = obj["md5"].GetString();
		asset.size = obj["size"].GetInt();
		int patch = obj["patch"].GetInt();
		// 0 is shenhe, <0 is test, >0 is normal. by huangwei 19/11/22
		if (patch < 0)
			sprintf(buf, "t%d", -patch);
		else
			sprintf(buf, "%d", patch);
		asset.patch = buf;
		asset.compressed = false;
		asset.downloadState = DownloadState::UNSTARTED;
		_assets.emplace(asset.path, asset);
	}
    
    _loaded = true;
	_json = rapidjson::Document();
}

NS_CC_EXT_END
