#pragma once

#ifndef __TJ_COMMON_H__
#define __TJ_COMMON_H__

#include <unordered_set>
#include <unordered_map>
#include <string>
#include <functional>
#include <memory>
#include <chrono>
#include <thread>
#include <cstdio>
#include <ctime>
#include <vector>

inline size_t bkrhash(const char* p)
{
	size_t seed = 131; // 31 131 1313 13131 131313 etc..
	size_t hash = 0;
	while (*p)
		hash = hash * seed + (*p++);
	return hash;
}

inline size_t simplehash(const char* p)
{
	size_t hash = 0;
	while (*p) {
		hash = hash + (*p++);
	}
	return hash;
}


struct StringKey
{
	std::string str;
	const char* sz;
	size_t h;

	StringKey()
	{
		sz = nullptr;
		h = 0;
	}
	StringKey(const std::string& s)
	{
		str = s;
		sz = nullptr;
		h = bkrhash(s.c_str());
	}
	StringKey(const char* s)
	{
		sz = s;
		h = bkrhash(sz);
	}
	void store()
	{
		if (sz)
		{
			str = sz;
			sz = nullptr;
		}
	}
};

// StringKey hash函数  
struct StringKeyHash
{
	size_t operator()(const StringKey &key) const
	{
		return key.h;
	}
};

// StringKey 比较函数
struct StringKeyCompare
{
	bool operator()(const StringKey &lhs, const StringKey &rhs) const
	{
		const char* p1, *p2;
		p1 = lhs.sz ? lhs.sz : lhs.str.c_str();
		p2 = rhs.sz ? rhs.sz : rhs.str.c_str();
		return strcmp(p1, p2) == 0;
	}
};

struct StringHash {
	std::string s;
	size_t h;

	StringHash(const std::string& str)
	{
		s = str;
		h = simplehash(s.c_str());
	}
};

struct Timer
{
	Timer(const char* t = nullptr, Timer* pt = nullptr);
	~Timer();
	void stopMyself();

	std::chrono::time_point<std::chrono::high_resolution_clock> start;
	std::chrono::nanoseconds dur;
	std::clock_t cstart;
	std::clock_t cdur;
	const char* tag;
	Timer* parent;
	bool stop;
};

struct FilesCollection {
	struct FileInfo {
		std::string path; // path in svn, relative
		std::string patch;
		std::string mapping; // repo.mapping
		size_t hash; // simplehash(pathInPatch)

		FileInfo(const std::string& path, const std::string& patch) {
			this->path = path;
			this->patch = patch;
			this->hash = simplehash(path.c_str());
		}
		FileInfo(const std::string& path, const std::string& patch, const std::string& mapping) {
			this->path = path;
			this->patch = patch;
			this->mapping = mapping;
			this->hash = simplehash(path.c_str());
		}
	};
	std::vector<FileInfo> files;

	int appendPatchFile(const std::string& pathInPatch, const std::string& patch);
	int appendMappingFile(const std::string& pathInPatch, const std::string& mapping);
	std::string getPathWithResolutions(const std::vector<StringHash>& resolutions, const std::string& filename);
};

int strQuickFind4Chars(const char* src, int offest, const char* chars4, int size = -1);
int strFindLastOf(const char* src, int pos, char ch);

#endif // __TJ_COMMON_H__