/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2011      Zynga Inc.
Copyright (c) 2013-2016 Chukong Technologies Inc.
Copyright (c) 2017-2018 Xiamen Yaji Software Co., Ltd.

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

#include "renderer/CCTextureCache.h"

#include <errno.h>
#include <stack>
#include <cctype>
#include <list>

#include "renderer/CCTexture2D.h"
#include "base/ccMacros.h"
#include "base/ccUTF8.h"
#include "base/CCDirector.h"
#include "base/CCScheduler.h"
#include "platform/CCFileUtils.h"
#include "base/ccUtils.h"
#include "base/CCNinePatchImageParser.h"
#include "assets-manager/VersionUtils.h"
#include "2d/CCFontAtlasCache.h"
#include "platform/TJCommon.h"
#include "base/allocator/TJAllocator.h"

using namespace std;

TJ_PROFILE_DOMAIN_DEF(__TextureCache, "tianji.TextureCache");

NS_CC_BEGIN

Texture2D* TextureCache::s_404Texture = nullptr;
std::string TextureCache::s_etc1AlphaFileSuffix = "@alpha";

// implementation TextureCache

void TextureCache::setETC1AlphaFileSuffix(const std::string& suffix)
{
    s_etc1AlphaFileSuffix = suffix;
}

std::string TextureCache::getETC1AlphaFileSuffix()
{
    return s_etc1AlphaFileSuffix;
}

TextureCache * TextureCache::getInstance()
{
    return Director::getInstance()->getTextureCache();
}

TextureCache::TextureCache()
: _loadingThread(nullptr)
, _loadingThread2(nullptr)
, _loadingThread3(nullptr)
, _loadingThread4(nullptr)
, _needQuit(false)
, _asyncRefCount(0)
{
	VersionPlistInfo versionPlist = getLocalVersion();
	_forShenhe = versionPlist.forShenhe;
}

TextureCache::~TextureCache()
{
    CCLOGINFO("deallocing TextureCache: %p", this);

    for (auto& texture : _textures)
        texture.second->release();

	CC_SAFE_DELETE(_loadingThread);
	CC_SAFE_DELETE(_loadingThread2);
	CC_SAFE_DELETE(_loadingThread3);
	CC_SAFE_DELETE(_loadingThread4);
}

void TextureCache::destroyInstance()
{
}

TextureCache * TextureCache::sharedTextureCache()
{
    return Director::getInstance()->getTextureCache();
}

void TextureCache::purgeSharedTextureCache()
{
}

std::string TextureCache::getDescription() const
{
    return StringUtils::format("Textures:%6d", static_cast<int>(_textures.size()));
}

struct TextureCache::AsyncStruct
{
public:
    AsyncStruct
    ( const std::string& fn,const std::function<void(Texture2D*)>& f,
      const std::string& key )
      : filename(fn), callback(f),callbackKey( key ),
        pixelFormat(Texture2D::getDefaultAlphaPixelFormat()),
        loadSuccess(false),
		image(nullptr),
		imageAlpha(nullptr)
    {}

	~AsyncStruct()
	{
		CC_SAFE_DELETE(image);
		CC_SAFE_DELETE(imageAlpha);
	}

    std::string filename;
    std::function<void(Texture2D*)> callback;
    std::string callbackKey;
    Image* image;
    Image* imageAlpha;
    Texture2D::PixelFormat pixelFormat;
	bool loadSuccess;
};

/**
 The addImageAsync logic follow the steps:
 - find the image has been add or not, if not add an AsyncStruct to _requestQueue  (GL thread)
 - get AsyncStruct from _requestQueue, load res and fill image data to AsyncStruct.image, then add AsyncStruct to _responseQueue (Load thread)
 - on schedule callback, get AsyncStruct from _responseQueue, convert image to texture, then delete AsyncStruct (GL thread)

 the Critical Area include these members:
 - _requestQueue: locked by _requestMutex
 - _responseQueue: locked by _responseMutex

 the object's life time:
 - AsyncStruct: construct and destruct in GL thread
 - image data: new in Load thread, delete in GL thread(by Image instance)

 Note:
 - all AsyncStruct referenced in _asyncStructQueue, for unbind function use.

 How to deal add image many times?
 - At first, this situation is abnormal, we only ensure the logic is correct.
 - If the image has been loaded, the after load image call will return immediately.
 - If the image request is in queue already, there will be more than one request in queue,
 - In addImageAsyncCallback, will deduplicate the request to ensure only create one texture.

 Does process all response in addImageAsyncCallback consume more time?
 - Convert image to texture faster than load image from disk, so this isn't a
 problem.

 Call unbindImageAsync(path) to prevent the call to the callback when the
 texture is loaded.
 */
void TextureCache::addImageAsync(const std::string &path, const std::function<void(Texture2D*)>& callback)
{
    addImageAsync( path, callback, path, true );
}

/**
 The addImageAsync logic follow the steps:
 - find the image has been add or not, if not add an AsyncStruct to _requestQueue  (GL thread)
 - get AsyncStruct from _requestQueue, load res and fill image data to AsyncStruct.image, then add AsyncStruct to _responseQueue (Load thread)
 - on schedule callback, get AsyncStruct from _responseQueue, convert image to texture, then delete AsyncStruct (GL thread)
 
 the Critical Area include these members:
 - _requestQueue: locked by _requestMutex
 - _responseQueue: locked by _responseMutex
 
 the object's life time:
 - AsyncStruct: construct and destruct in GL thread
 - image data: new in Load thread, delete in GL thread(by Image instance)
 
 Note:
 - all AsyncStruct referenced in _asyncStructQueue, for unbind function use.
 
 How to deal add image many times?
 - At first, this situation is abnormal, we only ensure the logic is correct.
 - If the image has been loaded, the after load image call will return immediately.
 - If the image request is in queue already, there will be more than one request in queue,
 - In addImageAsyncCallback, will deduplicate the request to ensure only create one texture.
 
 Does process all response in addImageAsyncCallback consume more time?
 - Convert image to texture faster than load image from disk, so this isn't a
 problem.

 The callbackKey allows to unbind the callback in cases where the loading of
 path is requested by several sources simultaneously. Each source can then
 unbind the callback independently as needed whilst a call to
 unbindImageAsync(path) would be ambiguous.
 */

// support push back or front for request queue
// no support duplicate callbackKey
// modify by huangwei, 18.11.29
TJ_PROFILE_TASK_DEF(__addImageAsync);
void TextureCache::addImageAsync(const std::string &path, const std::function<void(Texture2D*)>& callback, const std::string& callbackKey, bool appendBack)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __addImageAsync);

	Texture2D *texture = nullptr;

    //std::string fullpath = FileUtils::getInstance()->fullPathForFilename(path);
	std::string fullpath = this->checkFullPath(path);

    auto it = _textures.find(fullpath);
    if (it != _textures.end())
        texture = it->second;

    if (texture != nullptr)
    {
        if (callback) callback(texture);
		TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
        return;
    }

    // check if file exists
    if (fullpath.empty() || !FileUtils::getInstance()->isFileExist(fullpath))
	{
        if (callback) callback(nullptr);
		TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
        return;
    }

    // lazy init
    if (_loadingThread == nullptr)
    {
        // create a new thread to load images
        _needQuit = false;
		_loadingThread = new (std::nothrow) std::thread(&TextureCache::loadImage, this);
		_loadingThread2 = new (std::nothrow) std::thread(&TextureCache::loadImage, this);
		_loadingThread3 = new (std::nothrow) std::thread(&TextureCache::loadImage, this);
		_loadingThread4 = new (std::nothrow) std::thread(&TextureCache::loadImage, this);
    }

    if (0 == _asyncRefCount)
    {
        Director::getInstance()->getScheduler()->schedule(CC_SCHEDULE_SELECTOR(TextureCache::addImageAsyncCallBack), this, 0, false);
    }

    ++_asyncRefCount;

    // generate async struct
    AsyncStruct *data =
      new (std::nothrow) AsyncStruct(fullpath, callback, callbackKey);
    
    // add async struct into queue
	bool first = _asyncStructMap[callbackKey].empty();
	_asyncStructMap[callbackKey].push_back(data);
	if (first)
	{
		std::unique_lock<std::mutex> ul(_requestMutex);
		if (appendBack)
			_requestQueue.push_back(data);
		else
			_requestQueue.push_front(data);
		_sleepCondition.notify_one();
	}

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
}

void TextureCache::unbindImageAsync(const std::string& callbackKey)
{
    if (_asyncStructMap.empty())
    {
        return;
    }

	auto kvIter = _asyncStructMap.find(callbackKey);
	if (kvIter != _asyncStructMap.end())
	{
		std::list<AsyncStruct*>& lst = kvIter->second;
		for (auto iter = lst.begin(); iter != lst.end(); ++iter)
		{
			(*iter)->callback = nullptr;
		}
	}
}

void TextureCache::unbindAllImageAsync()
{
    if (_asyncStructMap.empty())
    {
        return;
    }
    for (auto& kv : _asyncStructMap)
    {
		std::list<AsyncStruct*>& lst = kv.second;
		for (auto iter = lst.begin(); iter != lst.end(); ++iter)
		{
			(*iter)->callback = nullptr;
		}
    }
}

void TextureCache::loadImage()
{
	TJ_PROFILE_THREAD_DEF(__loadImage);

    AsyncStruct *asyncStruct = nullptr;
    while (!_needQuit)
    {
		{
			std::unique_lock<std::mutex> ul(_requestMutex);
			// pop an AsyncStruct from request queue
			if (_requestQueue.empty())
			{
				asyncStruct = nullptr;
			}
			else
			{
				asyncStruct = _requestQueue.front();
				_requestQueue.pop_front();
			}

			if (nullptr == asyncStruct) {
				_sleepCondition.wait(ul);
				continue;
			}
		}

		// cancel
		if (asyncStruct->callback == nullptr) {
			// push the asyncStruct to response queue
			_responseMutex.lock();
			_responseQueue.push_back(asyncStruct);
			_responseMutex.unlock();
			continue;
		}

        // load image
		asyncStruct->image = new Image();
        asyncStruct->loadSuccess = asyncStruct->image->initWithImageFileThreadSafe(asyncStruct->filename);

		// @不处理了，只是标识符，方便识别而已 by huangwei 2019/11/19
// 		if (_forShenhe)
// 		{
// 			// 如果是审核资源，则替换为相同尺寸的空白透明图
// 			std::string& fullpath = asyncStruct->filename;
// 			int pos = fullpath.find_last_of('.');
// 			if (pos > 0 && fullpath.compare(pos - 1, 1, "@") == 0)
// 			{
// 				int width = asyncStruct->image->getWidth();
// 				int height = asyncStruct->image->getHeight();
// 
// 				int bytesPerComponent = 4;
// 				int dataLen = height * width * bytesPerComponent;
// 				auto data = static_cast<unsigned char*>(malloc(dataLen * sizeof(unsigned char)));
// 				if (data == NULL)
// 				{
// 					asyncStruct->loadSuccess = false;
// 					// push the asyncStruct to response queue
// 					_responseMutex.lock();
// 					_responseQueue.push_back(asyncStruct);
// 					_responseMutex.unlock();
// 					continue;
// 				}
// 
// 				memset(data, 0x00, dataLen);
// 				bool CC_UNUSED isOK = asyncStruct->image->initWithRawDataNoCopy(data, sizeof(data), width, height, 8);
// 				CCASSERT(isOK, "The width x height empty texture was created unsuccessfully.");
// 			}
// 		}

        // ETC1 ALPHA supports.
        if (asyncStruct->loadSuccess && asyncStruct->image->getFileType() == Image::Format::ETC && !s_etc1AlphaFileSuffix.empty())
        { // check whether alpha texture exists & load it
            auto alphaFile = asyncStruct->filename + s_etc1AlphaFileSuffix;
			if (FileUtils::getInstance()->isFileExist(alphaFile))
			{
				asyncStruct->imageAlpha = new Image();
				asyncStruct->imageAlpha->initWithImageFileThreadSafe(alphaFile);
			}
        }

        // push the asyncStruct to response queue
        _responseMutex.lock();
        _responseQueue.push_back(asyncStruct);
        _responseMutex.unlock();
    }
}

TJ_PROFILE_TASK_DEF(__addImageAsyncCallBack);
void TextureCache::addImageAsyncCallBack(float /*dt*/)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __addImageAsyncCallBack);

	Director* director = Director::getInstance();
    Texture2D *texture = nullptr;
	AsyncStruct *asyncStruct = nullptr;
    while (true)
    {
        // pop an AsyncStruct from response queue
        _responseMutex.lock();
        if (_responseQueue.empty())
        {
            asyncStruct = nullptr;
        }
        else
        {
            asyncStruct = _responseQueue.front();
            _responseQueue.pop_front();
        }
        _responseMutex.unlock();

        if (nullptr == asyncStruct) {
            break;
        }

        // check the image has been convert to texture or not
        auto it = _textures.find(asyncStruct->filename);
        if (it != _textures.end())
        {
            texture = it->second;
			if (director->isDisplayStats())
			{
				std::string rawPath = FileUtils::getInstance()->getRawPathInRepoCache(asyncStruct->filename);
				CCLOG("addImageAsync %s lose %d", rawPath.c_str(), asyncStruct->loadSuccess);
			}
        }
        else
        {
			if (director->isDisplayStats())
			{
				std::string rawPath = FileUtils::getInstance()->getRawPathInRepoCache(asyncStruct->filename);
				CCLOG("addImageAsync %s succ %d", rawPath.c_str(), asyncStruct->loadSuccess);
			}

            // convert image to texture
            if (asyncStruct->loadSuccess)
            {
                Image* image = asyncStruct->image;
                // generate texture in render thread
                texture = new (std::nothrow) Texture2D();

                texture->initWithImage(image, asyncStruct->pixelFormat);
                //parse 9-patch info
                this->parseNinePatchImage(image, texture, asyncStruct->filename);
#if CC_ENABLE_CACHE_TEXTURE_DATA
                // cache the texture file name
                VolatileTextureMgr::addImageTexture(texture, asyncStruct->filename);
#endif
                // cache the texture. retain it, since it is added in the map
                _textures.emplace(asyncStruct->filename, texture);
                texture->retain();

                texture->autorelease();
                // ETC1 ALPHA supports.
                if (asyncStruct->imageAlpha && asyncStruct->imageAlpha->getFileType() == Image::Format::ETC) {
                    auto alphaTexture = new(std::nothrow) Texture2D();
                    if(alphaTexture != nullptr && alphaTexture->initWithImage(asyncStruct->imageAlpha, asyncStruct->pixelFormat)) {
                        texture->setAlphaTexture(alphaTexture);
                    }
                    CC_SAFE_RELEASE(alphaTexture);
                }
            }
            else {
                texture = nullptr;
                CCLOG("cocos2d: failed to call TextureCache::addImageAsync(%s)", asyncStruct->filename.c_str());
            }
        }

		std::string callbackKey = asyncStruct->callbackKey;
		std::list<AsyncStruct*> dataLst;
		std::list<AsyncStruct*>& lst = _asyncStructMap[callbackKey];
		lst.swap(dataLst);
		_asyncStructMap.erase(callbackKey);
		for (auto iter = dataLst.begin(); iter != dataLst.end(); ++iter)
		{
			AsyncStruct* data = *iter;
			if (data->callback)
			{
				(data->callback)(texture);
			}
			delete data;
			--_asyncRefCount;
		}
    }

    if (0 == _asyncRefCount)
    {
		size_t check = 0;
		for (auto& p : _asyncStructMap)
		{
			check += p.second.size();
		}
		if (check > 0)
			CCLOG("cocos2d: addImageAsync memory leak %d !!!", check);
		_asyncStructMap.clear();
		director->getScheduler()->unschedule(CC_SCHEDULE_SELECTOR(TextureCache::addImageAsyncCallBack), this);
    }

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
}

TJ_PROFILE_TASK_DEF(__checkFullPath);
std::string TextureCache::checkFullPath(const std::string &path) const
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __checkFullPath);

	// 如果非jpg文件，则自动搜索同名文件，优先pvr，最后png, modify by huangwei
	auto utils = FileUtils::getInstance();
	std::string fullpath = utils->getFullPathInCache(path);
	// if path already be checked, not necessary to make and find
	if (fullpath.empty())
	{
		//size_t jpgpos = path.find(".jpg");
		bool isJpg = strncmp(path.c_str() + MAX(0, path.size()-4), ".jpg", 4) == 0;
		std::string newPath = path;
		bool isExistedInLookup = false;
		// path已经在lookup表中，则不再进行探测, modify by huangwei 2017-7-27
		if (!isJpg)
		{
			isExistedInLookup = utils->isInLookupDictionary(path);
			if (!isExistedInLookup)
			{
				size_t startPos = path.find_last_of(".");
				if (startPos != std::string::npos)
				{
					std::string pvrPath = path;
					pvrPath.erase(startPos);

					// append .pvr.ccz
					pvrPath = pvrPath.append(".pvr.ccz");
					bool flag = utils->isPopupNotify();
					utils->setPopupNotify(false);
					if (utils->isFileExist(pvrPath.c_str()))
					{
						newPath = pvrPath;
					}
					utils->setPopupNotify(flag);
				}

				// 用jpg替换png的用处不多, modify by huangwei 2017-7-27
				// 		else
				// 		{
				// 			std::string jpgPath = newPath;
				// 			jpgPath.erase(startPos);
				// 
				// 			// append .jpg
				// 			jpgPath = jpgPath.append(".jpg");
				// 			if (utils->isFileExist(jpgPath.c_str()))
				// 			{
				// 				newPath = jpgPath;
				// 				jpgpos = newPath.find(".jpg");
				// 			}
				// 		}
			}
		}

		fullpath = utils->fullPathForFilename(newPath);
		if (fullpath.empty())
		{
			TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
			return fullpath;
		}

		// 使用lookup表加速png路径搜索, modify by huangwei 2017-7-27
		// isExistedInLookup保护第二次查找时newPath=path，而覆盖了旧的有效信息, fix by huangwei 2019/07/22
		if (!isExistedInLookup)
			utils->addFilenameLookup(path, newPath);
	}
	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
	return fullpath;
}

TJ_PROFILE_TASK_DEF(__addImage1);
Texture2D * TextureCache::addImage(const std::string &path)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __addImage1);
    Texture2D * texture = nullptr;
    Image* image = nullptr;
    // Split up directory and filename
    // MUTEX:
    // Needed since addImageAsync calls this method from a different thread

	// 如果在addImageAsync里了，那直接拿fullpath数据
	std::string fullpath;
	if (_asyncStructMap.find(path) != _asyncStructMap.end())
	{
		AsyncStruct* data = _asyncStructMap[path].front();
		fullpath = data->filename;
	}

	// async在thread加载后，需要在主线程执行addImageAsyncCallBack后才能加到texture cache
	// 而widgetFromJsonFile添加async任务和addImage是同一帧，所以强制处理_responseQueue
	// modify by huangwei, 2019.5.14
	if (_asyncRefCount > 0)
	{
		addImageAsyncCallBack(0.0f);
	}

	// 如果非jpg文件，则自动搜索同名文件，优先pvr，最后png, modify by huangwei
	if (fullpath.empty())
		fullpath = this->checkFullPath(path);
    auto it = _textures.find(fullpath);
    if (it != _textures.end())
        texture = it->second;

    if (!texture)
    {
        // all images are handled by UIImage except PVR extension that is handled by our own handler
        do
        {
            image = new (std::nothrow) Image();
            CC_BREAK_IF(nullptr == image);
			// @不处理了，只是标识符，方便识别而已 by huangwei 2019/11/19
// 			if (_forShenhe)
// 			{
// 				// 如果是审核资源，则替换为相同尺寸的空白透明图
// 				int pos = fullpath.find_last_of('.');
// 				if (pos > 0 && fullpath.compare(pos - 1, 1, "@") == 0)
// 				{
// 					Image* tmpImg = new (std::nothrow) Image();
// 					CC_BREAK_IF(nullptr == tmpImg);
// 					bool bRet = tmpImg->initWithImageFile(fullpath);
// 					CC_BREAK_IF(!bRet);
// 
// 					int width = tmpImg->getWidth();
// 					int height = tmpImg->getHeight();
// 					CC_SAFE_RELEASE(tmpImg);
// 
// 					int bytesPerComponent = 4;
// 					int dataLen = height * width * bytesPerComponent;
// 					auto data = static_cast<unsigned char*>(malloc(dataLen * sizeof(unsigned char)));
// 					CC_BREAK_IF(!data);
// 					memset(data, 0x00, dataLen);
// 					bool CC_UNUSED isOK = image->initWithRawDataNoCopy(data, sizeof(data), width, height, 8);
// 					CCASSERT(isOK, "The width x height empty texture was created unsuccessfully.");
// 				}
// 				else
// 				{
// 					bool bRet = image->initWithImageFile(fullpath);
// 					CC_BREAK_IF(!bRet);
// 				}
// 			}
// 			else
			{
				bool bRet = image->initWithImageFile(fullpath);
				CC_BREAK_IF(!bRet);
			}

            texture = new (std::nothrow) Texture2D();
            if (texture && texture->initWithImage(image))
            {
#if CC_ENABLE_CACHE_TEXTURE_DATA
                // cache the texture file name
                VolatileTextureMgr::addImageTexture(texture, fullpath);
#endif
                // texture already retained, no need to re-retain it
                _textures.emplace(fullpath, texture);

                //-- ANDROID ETC1 ALPHA SUPPORTS.
                std::string alphaFullPath = path + s_etc1AlphaFileSuffix;
                if (image->getFileType() == Image::Format::ETC && !s_etc1AlphaFileSuffix.empty() && FileUtils::getInstance()->isFileExist(alphaFullPath))
                {
                    Image alphaImage;
                    if (alphaImage.initWithImageFile(alphaFullPath))
                    {
                        Texture2D *pAlphaTexture = new(std::nothrow) Texture2D;
                        if(pAlphaTexture != nullptr && pAlphaTexture->initWithImage(&alphaImage)) {
                            texture->setAlphaTexture(pAlphaTexture);
                        }
                        CC_SAFE_RELEASE(pAlphaTexture);
                    }
                }

                //parse 9-patch info
                this->parseNinePatchImage(image, texture, path);
            }
            else
            {
                CCLOG("cocos2d: Couldn't create texture for file:%s in TextureCache", path.c_str());
                CC_SAFE_RELEASE(texture);
                texture = nullptr;
            }
        } while (0);
    }

    CC_SAFE_RELEASE(image);

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
    return texture;
}

void TextureCache::parseNinePatchImage(cocos2d::Image *image, cocos2d::Texture2D *texture, const std::string& path)
{
    if (NinePatchImageParser::isNinePatchImage(path))
    {
        Rect frameRect = Rect(0, 0, image->getWidth(), image->getHeight());
        NinePatchImageParser parser(image, frameRect, false);
        texture->addSpriteFrameCapInset(nullptr, parser.parseCapInset());
    }

}

TJ_PROFILE_TASK_DEF(__addImage2);
Texture2D* TextureCache::addImage(Image *image, const std::string &key)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __addImage2);

    CCASSERT(image != nullptr, "TextureCache: image MUST not be nil");
    CCASSERT(image->getData() != nullptr, "TextureCache: image MUST not be nil");

    Texture2D * texture = nullptr;

    do
    {
        auto it = _textures.find(key);
        if (it != _textures.end()) {
            texture = it->second;
            break;
        }

        texture = new (std::nothrow) Texture2D();

        if (texture)
        {
            if (texture->initWithImage(image))
            {
                _textures.emplace(key, texture);
            }
            else
            {
                CC_SAFE_RELEASE(texture);
                texture = nullptr;
                CCLOG("cocos2d: initWithImage failed!");
            }
        }
        else
        {
            CCLOG("cocos2d: Allocating memory for Texture2D failed!");
        }

    } while (0);

#if CC_ENABLE_CACHE_TEXTURE_DATA
    VolatileTextureMgr::addImage(texture, image);
#endif

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
    return texture;
}

bool TextureCache::reloadTexture(const std::string& fileName)
{
    Texture2D * texture = nullptr;
    Image * image = nullptr;

    std::string fullpath = FileUtils::getInstance()->fullPathForFilename(fileName);
    if (fullpath.size() == 0)
    {
        return false;
    }

    auto it = _textures.find(fullpath);
    if (it != _textures.end()) {
        texture = it->second;
    }

    bool ret = false;
    if (!texture) {
        texture = this->addImage(fullpath);
        ret = (texture != nullptr);
    }
    else
    {
        do {
            image = new (std::nothrow) Image();
            CC_BREAK_IF(nullptr == image);

            bool bRet = image->initWithImageFile(fullpath);
            CC_BREAK_IF(!bRet);

            ret = texture->initWithImage(image);
        } while (0);
    }

    CC_SAFE_RELEASE(image);

    return ret;
}

// TextureCache - Remove

void TextureCache::removeAllTextures()
{
    for (auto& texture : _textures) {
        texture.second->release();
    }
    _textures.clear();
}

TJ_PROFILE_TASK_DEF(__removeUnusedTextures);
int TextureCache::removeUnusedTextures(int step /*= 0*/)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __removeUnusedTextures);

	int cnt = 0;
	if (step == 0)
		step = _textures.size();
	auto fileUtils = FileUtils::getInstance();
    for (auto it = _textures.cbegin(); it != _textures.cend(); /* nothing */) {
        Texture2D *tex = it->second;
        if (tex->getReferenceCount() == 1) {
			std::string rawPath = fileUtils->getRawPathInRepoCache(it->first);
            CCLOG("cocos2d: TextureCache: removing unused texture: %s", rawPath.c_str());

            tex->release();
            it = _textures.erase(it);
			++cnt;
			if (--step <= 0) {
				TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
				return cnt;
			}
        }
        else {
            ++it;
        }
    }
	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
	return cnt;
}

TJ_PROFILE_TASK_DEF(__removeLongTimeUnusedTextures);
int TextureCache::removeLongTimeUnusedTextures(int step /*= 0*/, float time /*= 10 * 60.f*/)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __removeLongTimeUnusedTextures);

	int cnt = 0;
	auto now = Director::getInstance()->getLastUpdateTime();
	if (step == 0)
		step = _textures.size();
	auto fileUtils = FileUtils::getInstance();
	for (auto it = _textures.cbegin(); it != _textures.cend(); /* nothing */) {
		Texture2D *tex = it->second;
		if (tex->getReferenceCount() == 1) {
			float delta = std::chrono::duration_cast<std::chrono::seconds>(now - tex->_lastTime).count();
			if (delta > time) {
				std::string rawPath = fileUtils->getRawPathInRepoCache(it->first);
				CCLOG("cocos2d: TextureCache: removing long time unused texture: %s", rawPath.c_str());

				tex->release();
				it = _textures.erase(it);
				++cnt;
				if (--step <= 0) {
					TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
					return cnt;
				}
			}
			else {
				++it;
			}
		}
		else {
			++it;
		}
	}
	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
	return cnt;
}

TJ_PROFILE_TASK_DEF(__removeLongTimeUnusedTexturesWithCallback);
int TextureCache::removeLongTimeUnusedTexturesWithCallback(const RemoveCallbackFunc& f, int step /*= 0*/, float time /*= 10 * 60.f*/)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __removeLongTimeUnusedTexturesWithCallback);

	int cnt = 0;
	auto now = Director::getInstance()->getLastUpdateTime();
	if (step == 0)
		step = _textures.size();
	auto fileUtils = FileUtils::getInstance();
	for (auto it = _textures.cbegin(); it != _textures.cend(); /* nothing */) {
		Texture2D *tex = it->second;
		if (tex->getReferenceCount() == 1) {
			float delta = std::chrono::duration_cast<std::chrono::seconds>(now - tex->_lastTime).count();
			if (delta > time && f(delta, tex)) {
				std::string rawPath = fileUtils->getRawPathInRepoCache(it->first);
				CCLOG("cocos2d: TextureCache: removing long time unused texture: %s", rawPath.c_str());

				tex->release();
				it = _textures.erase(it);
				++cnt;
				if (--step <= 0) {
					TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
					return cnt;
				}
			}
			else {
				++it;
			}
		}
		else {
			++it;
		}
	}
	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
	return cnt;
}


TJ_PROFILE_TASK_DEF(__removeTexture);
void TextureCache::removeTexture(Texture2D* texture)
{
    if (!texture)
    {
        return;
    }

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __removeTexture);

    for (auto it = _textures.cbegin(); it != _textures.cend(); /* nothing */) {
        if (it->second == texture) {
            it->second->release();
            it = _textures.erase(it);
            break;
        }
        else
            ++it;
    }

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
}

TJ_PROFILE_TASK_DEF(__removeTextureForKey);
void TextureCache::removeTextureForKey(const std::string &textureKeyName)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__TextureCache, __removeTextureForKey);

    std::string key = textureKeyName;
    auto it = _textures.find(key);

    if (it == _textures.end()) {
        //key = FileUtils::getInstance()->fullPathForFilename(textureKeyName);
		key = checkFullPath(textureKeyName);
        it = _textures.find(key);
    }

    if (it != _textures.end()) {
        it->second->release();
        _textures.erase(it);
    }

	TJ_PROFILE_DOMAIN_TASK_END(__TextureCache);
}

Texture2D* TextureCache::getTextureForKey(const std::string &textureKeyName) const
{
    std::string key = textureKeyName;
    auto it = _textures.find(key);

    if (it == _textures.end()) {
        //key = FileUtils::getInstance()->fullPathForFilename(textureKeyName);
		key = checkFullPath(textureKeyName);
        it = _textures.find(key);
    }

    if (it != _textures.end())
        return it->second;
    return nullptr;
}

void TextureCache::reloadAllTextures()
{
    //will do nothing
    // #if CC_ENABLE_CACHE_TEXTURE_DATA
    //     VolatileTextureMgr::reloadAllTextures();
    // #endif
}

std::string TextureCache::getTextureFilePath(cocos2d::Texture2D* texture) const
{
    for (auto& item : _textures)
    {
        if (item.second == texture)
        {
            return item.first;
            break;
        }
    }
    return "";
}

void TextureCache::waitForQuit()
{
    // notify sub thread to quick
    std::unique_lock<std::mutex> ul(_requestMutex);
    _needQuit = true;
    _sleepCondition.notify_all();
    ul.unlock();
	if (_loadingThread) _loadingThread->join();
	if (_loadingThread2) _loadingThread2->join();
	if (_loadingThread3) _loadingThread3->join();
	if (_loadingThread4) _loadingThread4->join();
}

std::string TextureCache::getCachedTextureInfo() const
{
    std::string buffer;
    char buftmp[4096];

    unsigned int count = 0;
    unsigned int totalBytes = 0;

	auto fileUtils  = FileUtils::getInstance();
    for (auto& texture : _textures) {
		buftmp[0] = 0;

        Texture2D* tex = texture.second;
		std::string rawPath = fileUtils->getRawPathInRepoCache(texture.first);
        unsigned int bpp = tex->getBitsPerPixelForFormat();
        // Each texture takes up width * height * bytesPerPixel bytes.
        auto bytes = tex->getPixelsWide() * tex->getPixelsHigh() * bpp / 8;
        totalBytes += bytes;
        count++;
        snprintf(buftmp, sizeof(buftmp) - 1, "\"%s\" rc=%lu id=%lu %lu x %lu @ %ld bpp => %lu KB\n",
			rawPath.c_str(),
            (long)tex->getReferenceCount(),
            (long)tex->getName(),
            (long)tex->getPixelsWide(),
            (long)tex->getPixelsHigh(),
            (long)bpp,
            (long)bytes / 1024);

        buffer += buftmp;
    }

    snprintf(buftmp, sizeof(buftmp) - 1, "TextureCache dumpDebugInfo: %ld textures, for %lu KB (%.2f MB)\n", (long)count, (long)totalBytes / 1024, totalBytes / (1024.0f*1024.0f));
    buffer += buftmp;

    return buffer;
}

// 获取cache总大小, modify by huangwei 2016-8-2
float TextureCache::getCachedTextureMemSize() const
{
	unsigned int count = 0;
	unsigned int totalBytes = 0;

	for (auto it = _textures.begin(); it != _textures.end(); ++it) {
		Texture2D* tex = it->second;
		unsigned int bpp = tex->getBitsPerPixelForFormat();
		// Each texture takes up width * height * bytesPerPixel bytes.
		auto bytes = tex->getPixelsWide() * tex->getPixelsHigh() * bpp / 8;
		totalBytes += bytes;
		count++;
	}

	return totalBytes / (1024.0f*1024.0f);
}


std::vector<std::string> TextureCache::getCachedTextureKeys() const
{
	std::vector<std::string> ret;
	for (auto it = _textures.begin(); it != _textures.end(); ++it) {
		ret.push_back(it->first);
	}
	return ret;
}

std::string TextureCache::getCachedFontTextureInfo() const
{
	return FontAtlasCache::getCachedTextureInfo();
}

float TextureCache::getCachedFontTextureMemSize() const
{
	return FontAtlasCache::getCachedTextureMemSize();
}

void TextureCache::renameTextureWithKey(const std::string& srcName, const std::string& dstName)
{
    std::string key = srcName;
    auto it = _textures.find(key);

    if (it == _textures.end()) {
		//key = FileUtils::getInstance()->fullPathForFilename(srcName);
		key = checkFullPath(srcName);
        it = _textures.find(key);
    }

    if (it != _textures.end()) {
		//std::string fullpath = FileUtils::getInstance()->fullPathForFilename(dstName);
		std::string fullpath = checkFullPath(dstName);
        Texture2D* tex = it->second;

        Image* image = new (std::nothrow) Image();
        if (image)
        {
            bool ret = image->initWithImageFile(dstName);
            if (ret)
            {
                tex->initWithImage(image);
                _textures.emplace(fullpath, tex);
                _textures.erase(it);
            }
            CC_SAFE_DELETE(image);
        }
    }
}


Texture2D* TextureCache::get404Texture()
{
	if (s_404Texture == nullptr)
	{
		s_404Texture = addImage("res/img/placeholder.png");
		if (s_404Texture)
			s_404Texture->retain();
	}
	return s_404Texture;
}



#if CC_ENABLE_CACHE_TEXTURE_DATA

std::list<VolatileTexture*> VolatileTextureMgr::_textures;
bool VolatileTextureMgr::_isReloading = false;

VolatileTexture::VolatileTexture(Texture2D *t)
: _texture(t)
, _uiImage(nullptr)
, _cashedImageType(kInvalid)
, _textureData(nullptr)
, _pixelFormat(Texture2D::PixelFormat::RGBA8888)
, _fileName("")
, _hasMipmaps(false)
, _text("")
{
    _texParams.minFilter = GL_LINEAR;
    _texParams.magFilter = GL_LINEAR;
    _texParams.wrapS = GL_CLAMP_TO_EDGE;
    _texParams.wrapT = GL_CLAMP_TO_EDGE;
}

VolatileTexture::~VolatileTexture()
{
    CC_SAFE_RELEASE(_uiImage);
}

void VolatileTextureMgr::addImageTexture(Texture2D *tt, const std::string& imageFileName)
{
    if (_isReloading)
    {
        return;
    }

    VolatileTexture *vt = findVolotileTexture(tt);

    vt->_cashedImageType = VolatileTexture::kImageFile;
    vt->_fileName = imageFileName;
    vt->_pixelFormat = tt->getPixelFormat();
}

void VolatileTextureMgr::addImage(Texture2D *tt, Image *image)
{
    if (tt == nullptr || image == nullptr)
        return;
    
    VolatileTexture *vt = findVolotileTexture(tt);
    image->retain();
    vt->_uiImage = image;
    vt->_cashedImageType = VolatileTexture::kImage;
}

VolatileTexture* VolatileTextureMgr::findVolotileTexture(Texture2D *tt)
{
    VolatileTexture *vt = nullptr;
    for (const auto& texture : _textures)
    {
        VolatileTexture *v = texture;
        if (v->_texture == tt)
        {
            vt = v;
            break;
        }
    }

    if (!vt)
    {
        vt = new (std::nothrow) VolatileTexture(tt);
        _textures.push_back(vt);
    }

    return vt;
}

void VolatileTextureMgr::addDataTexture(Texture2D *tt, void* data, int dataLen, Texture2D::PixelFormat pixelFormat, const Size& contentSize)
{
    if (_isReloading)
    {
        return;
    }

    VolatileTexture *vt = findVolotileTexture(tt);

    vt->_cashedImageType = VolatileTexture::kImageData;
    vt->_textureData = data;
    vt->_dataLen = dataLen;
    vt->_pixelFormat = pixelFormat;
    vt->_textureSize = contentSize;
}

void VolatileTextureMgr::addStringTexture(Texture2D *tt, const char* text, const FontDefinition& fontDefinition)
{
    if (_isReloading)
    {
        return;
    }

    VolatileTexture *vt = findVolotileTexture(tt);

    vt->_cashedImageType = VolatileTexture::kString;
    vt->_text = text;
    vt->_fontDefinition = fontDefinition;
}

void VolatileTextureMgr::setHasMipmaps(Texture2D *t, bool hasMipmaps)
{
    VolatileTexture *vt = findVolotileTexture(t);
    vt->_hasMipmaps = hasMipmaps;
}

void VolatileTextureMgr::setTexParameters(Texture2D *t, const Texture2D::TexParams &texParams)
{
    VolatileTexture *vt = findVolotileTexture(t);

    if (texParams.minFilter != GL_NONE)
        vt->_texParams.minFilter = texParams.minFilter;
    if (texParams.magFilter != GL_NONE)
        vt->_texParams.magFilter = texParams.magFilter;
    if (texParams.wrapS != GL_NONE)
        vt->_texParams.wrapS = texParams.wrapS;
    if (texParams.wrapT != GL_NONE)
        vt->_texParams.wrapT = texParams.wrapT;
}

void VolatileTextureMgr::removeTexture(Texture2D *t)
{
    for (auto& item : _textures)
    {
        VolatileTexture *vt = item;
        if (vt->_texture == t)
        {
            _textures.remove(vt);
            delete vt;
            break;
        }
    }
}

void VolatileTextureMgr::reloadAllTextures()
{
    _isReloading = true;

    // we need to release all of the glTextures to avoid collisions of texture id's when reloading the textures onto the GPU
    for (auto& item : _textures)
    {
        item->_texture->releaseGLTexture();
    }

    CCLOG("reload all texture");

    for (auto& texture : _textures)
    {
        VolatileTexture *vt = texture;

        switch (vt->_cashedImageType)
        {
        case VolatileTexture::kImageFile:
        {
            reloadTexture(vt->_texture, vt->_fileName, vt->_pixelFormat);

            // etc1 support check whether alpha texture exists & load it
            auto alphaFile = vt->_fileName + TextureCache::getETC1AlphaFileSuffix();
            reloadTexture(vt->_texture->getAlphaTexture(), alphaFile, vt->_pixelFormat);
        }
        break;
        case VolatileTexture::kImageData:
        {
            vt->_texture->initWithData(vt->_textureData,
                vt->_dataLen,
                vt->_pixelFormat,
                vt->_textureSize.width,
                vt->_textureSize.height,
                vt->_textureSize);
        }
        break;
        case VolatileTexture::kString:
        {
            vt->_texture->initWithString(vt->_text.c_str(), vt->_fontDefinition);
        }
        break;
        case VolatileTexture::kImage:
        {
            vt->_texture->initWithImage(vt->_uiImage);
        }
        break;
        default:
            break;
        }
        if (vt->_hasMipmaps) {
            vt->_texture->generateMipmap();
        }
        vt->_texture->setTexParameters(vt->_texParams);
    }

    _isReloading = false;
}

void VolatileTextureMgr::reloadTexture(Texture2D* texture, const std::string& filename, Texture2D::PixelFormat pixelFormat)
{
    if (!texture)
        return;

    Image* image = new (std::nothrow) Image();
    Data data = FileUtils::getInstance()->getDataFromFile(filename);

    if (image && image->initWithImageData(data.getBytes(), data.getSize()))
        texture->initWithImage(image, pixelFormat);

    CC_SAFE_RELEASE(image);
}

#endif // CC_ENABLE_CACHE_TEXTURE_DATA

NS_CC_END

