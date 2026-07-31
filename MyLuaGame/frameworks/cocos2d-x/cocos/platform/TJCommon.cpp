#include "TJCommon.h"

#include "base/CCConsole.h"

Timer::Timer(const char* t /*= nullptr*/, Timer* pt /*= nullptr*/) :
	dur(0),
	cdur(0),
	tag(t),
	parent(pt),
	stop(false)
{
	cstart = std::clock();
	start = std::chrono::high_resolution_clock::now();
}

Timer::~Timer()
{
	if (!stop) {
		auto end = std::chrono::high_resolution_clock::now();
		dur = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);

		auto cend = std::clock();
		cdur = cend - cstart;
	}
	if (parent) {
		parent->dur += dur;
		parent->cdur += cdur;
		parent->stopMyself();
	}
	if (tag) {
		//printf("%s: %.2lf ms, %lld ns, %.2lf ms\n", tag, 1.0*dur.count() / 1e6, dur.count(), 1000.0 * cdur / CLOCKS_PER_SEC);
		CCLOG("%s: %.2lf ms, %lld ns, %.2lf ms\n", tag, 1.0*dur.count() / 1e6, dur.count(), 1000.0 * cdur / CLOCKS_PER_SEC);
	}
}

void Timer::stopMyself()
{
	stop = true;
}

int FilesCollection::appendPatchFile(const std::string& path, const std::string& patch)
{
	// if path are same, it may be in patch be updated by huangwei 19/01/15
	FileInfo info(path, patch);
	for (auto it = files.begin(); it != files.end(); ++it)
	{
		if (info.hash == it->hash && info.path == it->path)
		{
			*it = info;
			return it - files.begin();
		}
	}
	files.emplace_back(info);
	return files.size();
}

int FilesCollection::appendMappingFile(const std::string& path, const std::string& mapping)
{
	// if path are same, it may be in obb be updated by huangwei 19/01/15
	static std::string empty = "";
	FileInfo info(path, empty, mapping);
	for (auto it = files.begin(); it != files.end(); ++it)
	{
		if (info.hash == it->hash && info.path == it->path)
		{
			*it = info;
			return it - files.begin();
		}
	}
	files.emplace_back(info);
	return files.size();
}

std::string FilesCollection::getPathWithResolutions(const std::vector<StringHash>& resolutions, const std::string& filename)
{
	static std::string empty;

	size_t filenameHash = simplehash(filename.c_str());
	// resolutions was from high priority to low
	for (auto resolutionIt = resolutions.cbegin(); resolutionIt != resolutions.cend(); ++resolutionIt)
	{
		const std::string& resolution = resolutionIt->s;
		for (auto it = files.begin(); it != files.end(); ++it)
		{
			const char* pathInPatch = it->path.c_str();
			size_t pathHash = it->hash;
			if (pathHash == resolutionIt->h + filenameHash) 
			{
				if (strncmp(resolution.c_str(), pathInPatch, resolution.size()) == 0
					&& strcmp(filename.c_str(), pathInPatch + resolution.size()) == 0)
				{
					if (it->mapping.empty())
					{
						return it->patch + resolution + filename;
					}
					else
					{
						return it->mapping;
					}
				}
			}
		}
	}

	return empty;
}

int strQuickFind4Chars(const char* src, int offest, const char* chars4, int size /*= -1*/)
{
	src += offest;
	uint32_t val = 0;
	uint32_t srcval = 0;
	for (int i = 0; i < 4; i++)
	{
		val = (val << 8) | (chars4[i]);
		srcval = (val << 8) | (src[i]);
		if (src[i] == 0)
			return std::string::npos;
	}
	if (val == srcval)
		return offest;

	const char* begin = src;
	const char* tail = src + 4;
	for (int i = offest + 4; *tail && (size < 0 || i < size); src++, tail++, i++)
	{
		srcval = (srcval << 8) | (*tail);
		if (val == srcval)
			return src - begin + 1 + offest;
	}
	return std::string::npos;
}

int strFindLastOf(const char* src, int pos, char ch)
{
	for (int i = pos; i >= 0; i--)
	{
		if (src[i] == ch)
			return i;
	}
	return -1;
}