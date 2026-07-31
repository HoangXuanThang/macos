#ifndef __Difflist__
#define __Difflist__

#include "Manifest.h"

NS_CC_EXT_BEGIN

class CC_EX_DLL Difflist : public Manifest
{
public:
    friend class AssetsManagerEx;

	bool isUpdateClose() const { return _updateClose; }
    std::string getPatch() const { return _patch; }

protected:
	Difflist();

	void genResumeAssetsList(DownloadUnits *units);
	void prependSearchPaths();
	void parse(const std::string& manifestUrl);
	void loadVersion(const rapidjson::Document &json);
	void loadManifest(const rapidjson::Document &json);

	std::string _patch;
	std::string _shenheVersion;
	bool _updateClose;
};

NS_CC_EXT_END
#endif /* defined(__Difflist__) */
