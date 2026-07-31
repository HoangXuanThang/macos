
#ifndef TJ_ALLOCATOR_H
#define TJ_ALLOCATOR_H
/// @cond DO_NOT_SHOW

#include "confuse.h"
#include "base/allocator/CCAllocatorMacros.h"
#include "base/allocator/CCAllocatorBase.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <mutex>
#include <thread>
#include <atomic>
#include <algorithm>

extern std::atomic_int allocCount;
extern std::atomic_int freeCount;
extern std::atomic_int missCount;
extern std::atomic_int mergeBuddyCount;
extern std::atomic_int splitBuddyCount;
extern std::atomic_int usedBuddyCount;
extern std::atomic_int usedSmallCount;

extern std::atomic_int usedFixedSize;
extern std::atomic_int usedBuddySize;
extern std::atomic_int usedSmallSize;


extern "C" {
	CC_DLL void* tj_malloc(size_t size);
	CC_DLL void* tj_calloc(size_t num, size_t size);
	CC_DLL void* tj_realloc(void* ptr, size_t size);
	CC_DLL void tj_free(void* ptr);

	CC_DLL void* tj_small_malloc(size_t size);
	CC_DLL void* tj_small_calloc(size_t size);
	CC_DLL void* tj_small_realloc(void* ptr, size_t size);
}

#define tj_malloc_longtime tj_small_malloc
#define tj_calloc_longtime tj_small_calloc
#define tj_realloc_longtime tj_small_realloc


NS_CC_BEGIN
NS_CC_ALLOCATOR_BEGIN


inline size_t nextPow2BlockSize(size_t size)
{
	--size;
	size |= size >> 1;
	size |= size >> 2;
	size |= size >> 4;
	size |= size >> 8;
	size |= size >> 16;
	return ++size;
}

inline int get_bit_idx(int low)
{
#define CASE(n) \
	case 1 << (n): \
		return (n)

	switch (low)
	{
		CASE(0);
		CASE(1);
		CASE(2);
		CASE(3);
		CASE(4);
		CASE(5);
		CASE(6);
		CASE(7);
		CASE(8);
		CASE(9);
		CASE(10);
		CASE(11);
		CASE(12);
		CASE(13);
		CASE(14);
		CASE(15);
		CASE(16);
		CASE(17);
		CASE(18);
		CASE(19);
		CASE(20);
		CASE(21);
		CASE(22);
		CASE(23);
		CASE(24);
		CASE(25);
		CASE(26);
		CASE(27);
		CASE(28);
		CASE(29);
		CASE(30);
		CASE(31);
	}
#undef CASE

	assert(false);
	return -1;
}

inline unsigned int get_continuous_lowbit(unsigned int n, int ones)
{
#define CASE(x) \
	case (x): \
		ret &= (n >> ((x)-1)); \
		if (!ret) \
			return 0

	unsigned int ret = n;
	switch (ones)
	{
		CASE(32);
		CASE(31);
		CASE(30);
		CASE(29);
		CASE(28);
		CASE(27);
		CASE(26);
		CASE(25);
		CASE(24);
		CASE(23);
		CASE(22);
		CASE(21);
		CASE(20);
		CASE(19);
		CASE(18);
		CASE(17);
		CASE(16);
		CASE(15);
		CASE(14);
		CASE(13);
		CASE(12);
		CASE(11);
		CASE(10);
		CASE(9);
		CASE(8);
		CASE(7);
		CASE(6);
		CASE(5);
		CASE(4);
		CASE(3);
		CASE(2);
	case 1:
		break;
	}
#undef CASE

	return ret & (-ret);
}

//////////////////////////////////////////////////////////////////////////

// use for file load and mem inflate
// it will be free quickly
// 32 * 128KB = 4MB
const int kFixedBuffSize = 32;
const int kFixedMemMaxBitSize = 17; // 1<<17
const int kFixedMemMaxSize = (1 << kFixedMemMaxBitSize); // 128KB

class CC_DLL TJAllocator
{
public:
	TJAllocator()
	{
		buff = (char*)malloc(kFixedBuffSize * kFixedMemMaxSize);
		buffEnd = buff + kFixedBuffSize * kFixedMemMaxSize;
		freeMask.store(UINT32_MAX);
		memset(spans, 0, sizeof(spans));
		for (int i = 0; i < kFixedBuffSize; i++)
			ptrs[i] = buff + i * kFixedMemMaxSize;
	}

	inline void* fixedPtrTo(size_t size, int lowidx, int span = 1)
	{
		if (0 <= lowidx && lowidx < kFixedBuffSize)
		{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			allocCount += 1;
#endif // COCOS2D_DEBUG
			usedFixedSize += span << kFixedMemMaxBitSize;

			spans[lowidx] = span;
			return ptrs[lowidx];
		}

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
		missCount += 1;
#endif // COCOS2D_DEBUG
		return malloc(size);
	}

	inline void* allocate(size_t size)
	{
		unsigned int low = 0;
		// malloc continuous fixed
		if (size > kFixedMemMaxSize)
		{
			size_t span = size >> kFixedMemMaxBitSize;
			if (size > (span << kFixedMemMaxBitSize))
				++span;
			if (span > kFixedBuffSize)
			{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				missCount += 1;
#endif // COCOS2D_DEBUG
				return malloc(size);
			}

			unsigned int memMask = freeMask.load(std::memory_order_relaxed);
			while (true)
			{
				low = get_continuous_lowbit(memMask, span);
				if (low == 0)
				{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
					missCount += 1;
#endif // COCOS2D_DEBUG
					return malloc(size);
				}
				int lowidx = get_bit_idx(low);
				unsigned int mask = ((1u << span) - 1) << lowidx;
				if (freeMask.compare_exchange_strong(memMask, memMask ^ mask))
					return fixedPtrTo(size, lowidx, span);
			}

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			missCount += 1;
#endif // COCOS2D_DEBUG
			return malloc(size);
		}

		// malloc fixed
		unsigned int memMask = freeMask.load(std::memory_order_relaxed);
		if (memMask == 0)
		{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			missCount += 1;
#endif // COCOS2D_DEBUG
			return malloc(size);
		}

		while (true)
		{
			low = memMask & (-memMask);
			if (freeMask.compare_exchange_strong(memMask, memMask ^ low))
				break;
			if (memMask == 0)
			{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				missCount += 1;
#endif // COCOS2D_DEBUG
				return malloc(size);
			}
		}

		return fixedPtrTo(size, get_bit_idx(low));
	}

	inline void* reallocate(void* ptr, size_t size)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int idx = ((char*)ptr - buff) >> kFixedMemMaxBitSize;
			size_t span = spans[idx];
			if (size > span * kFixedMemMaxSize)
			{
				// new and copy
				void* newptr = allocate(size);
				memcpy(newptr, ptr, span * kFixedMemMaxSize);

				// free
				deallocate(ptr);

				ptr = newptr;
			}
			return ptr;
		}
		return realloc(ptr, size);
	}

	inline void deallocate(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			// free fixed
			int idx = ((char*)ptr - buff) >> kFixedMemMaxBitSize;
			int span = spans[idx];
			spans[idx] = 0;
			unsigned int mask = ((1u << span) - 1) << idx;
			unsigned int memMask = freeMask.load(std::memory_order_relaxed);
			while (!freeMask.compare_exchange_strong(memMask, memMask ^ mask));

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			freeCount += 1;
#endif // COCOS2D_DEBUG
			usedFixedSize -= span << kFixedMemMaxBitSize;

			return;
		}
		free(ptr);
	}

	inline bool isMyAlloc(void* ptr)
	{
		return buff <= ptr && ptr < buffEnd;
	}

	inline size_t possibleMemSize(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int idx = ((char*)ptr - buff) >> kFixedMemMaxBitSize;
			size_t span = spans[idx];
			return span * kFixedMemMaxSize;
		}
		return 0;
	}

protected:
	char* buff;
	char* buffEnd;
	char* ptrs[kFixedBuffSize];
	char spans[kFixedBuffSize];
	std::atomic_uint32_t freeMask;
};


//////////////////////////////////////////////////////////////////////////


const int kBuddyMinBitSize = 6;
const int kBuddyMinSize = (1 << kBuddyMinBitSize); // 64
const int kBuddyMemMaxBitSize = 26; // 1<<26
const int kBuddyMemMaxSize = (1 << kBuddyMemMaxBitSize); // 64MB

const int kUsedHeadSize = sizeof(int);


struct BuddyFree
{
	int level; // 0 is free, level when used
	int next;
	int prev;
};

struct BuddyHead
{
	int head;
	std::mutex mutex;
	int free; // only for debug
	char* buddy;

	void lock()
	{
		mutex.lock();
	}

	void unlock()
	{
		mutex.unlock();
	}
};


class CC_DLL TJBuddyAllocator
{
public:
	TJBuddyAllocator()
	{
		buff = (char*)malloc(kBuddyMemMaxSize);
		buffEnd = buff + kBuddyMemMaxSize;

		// init buddy mem buffer
		for (int i = 0; i <= kBuddyMemMaxBitSize; i++)
		{
			buddyHeads[i].head = -1;
			buddyHeads[i].free = 0;
		}
		for (int i = kBuddyMinBitSize; i <= kBuddyMemMaxBitSize; i++)
		{
			int size = kBuddyMemMaxSize / (1 << i) / 8 / 2 + 1;
			buddyHeads[i].buddy = (char*)malloc(size);
			memset(buddyHeads[i].buddy, 0, size);
		}
		buddyHeads[kBuddyMemMaxBitSize].head = 0;
		buddyHeads[kBuddyMemMaxBitSize].free = 1;
		BuddyFree* pfree = (BuddyFree*)buff;
		pfree->level = kBuddyMemMaxBitSize;
		pfree->next = -1;
		pfree->prev = -1;
	}


	inline int pushBuddyHead(int pos, int idx, bool autolock = true)
	{
		BuddyHead& bh = buddyHeads[pos];

		if (autolock)
			bh.lock();
		int head = bh.head;
		char* ptr = buff + (1 << pos) * idx;
		BuddyFree* pfree = (BuddyFree*)ptr;
		pfree->level = pos;
		pfree->prev = -1;
		pfree->next = head;

		// 0 -> 1
		if (idx & 0x1)
		{
			int bidx = idx >> 1;
			int bi = bidx >> 3; // /8
			int bj = bidx & 0x7; // %8
			bh.buddy[bi] = bh.buddy[bi] | (1 << bj);
		}

		if (head != -1)
		{
			pfree = (BuddyFree*)(buff + (1 << pos) * head);
			pfree->prev = idx;
		}

		bh.free++;

		bh.head = idx;
		if (autolock)
			bh.unlock();
		return head;
	}

	inline int popBuddyHead(int pos)
	{
		BuddyHead& bh = buddyHeads[pos];

		bh.lock();
		int head = bh.head;
		int next;
		if (head == -1)
		{
			bh.unlock();
			return -1;
		}

		char* ptr = buff + (1 << pos) * head;
		next = ((BuddyFree*)ptr)->next;
		if (next != -1)
		{
			BuddyFree* pfreeNext = (BuddyFree*)(buff + (1 << pos) * next);
			pfreeNext->prev = -1;
		}

		*(int*)ptr = pos;

		// 1 -> 0
		int idx = head;
		if (idx & 0x1)
		{
			int bidx = idx >> 1;
			int bi = bidx >> 3; // /8
			int bj = bidx & 0x7; // %8
			bh.buddy[bi] = bh.buddy[bi] & (~(1 << bj));
		}

		bh.free--;

		bh.head = next;
		bh.unlock();
		return head;
	}

	inline void* allocate(size_t size, bool useSys = true)
	{
		size_t raw = size;
		// malloc buddy
		do {
			size += kUsedHeadSize;
			if (size < kBuddyMinSize)
				size = kBuddyMinSize;
			else
				size = nextPow2BlockSize(size);

			int pos = get_bit_idx(size);
			int posUp = -1;
			int headUp = -1;
			for (int i = pos; i <= kBuddyMemMaxBitSize; ++i)
			{
				// malloc big one
				int head = popBuddyHead(i);
				if (head != -1)
				{
					posUp = i;
					headUp = head;
					break;
				}
			}

			if (posUp == -1)
				break;

			for (int i = posUp; i > pos; --i)
			{
				// malloc big one
				int head = -1;
				if (i == posUp)
					head = headUp;
				else
					head = popBuddyHead(i);
				if (head == -1)
					break;

				// split
				int head20 = head << 1;
				pushBuddyHead(i - 1, head20 ^ 0x1);
				pushBuddyHead(i - 1, head20);

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				splitBuddyCount += 1;
#endif // COCOS2D_DEBUG
			}

			int head = popBuddyHead(pos);
			if (head == -1)
				break;

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			allocCount += 1;
			usedBuddyCount += 1;
#endif // COCOS2D_DEBUG
			usedBuddySize += 1 << pos;

			char* ptr = buff + (1 << pos) * head;
			return ptr + kUsedHeadSize;
		} while (true);

		if (useSys)
		{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			missCount += 1;
#endif // COCOS2D_DEBUG
			return malloc(raw);
		}
		return nullptr;
	}

	inline void* reallocate(void* ptr, size_t size, bool useSys = true)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int pos = *(int*)((char*)ptr - kUsedHeadSize);
			size_t buddySize = (1 << pos) - kUsedHeadSize;
			if (size > buddySize)
			{
				// new and copy
				void* newptr = allocate(size, useSys);
				if (newptr == nullptr)
					return nullptr;
				memcpy(newptr, ptr, buddySize);

				// free
				deallocate(ptr);

				ptr = newptr;
			}
			return ptr;
		}
		if (useSys)
			return realloc(ptr, size);
		return nullptr;
	}

	inline void deallocate(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			// free buddy
			ptr = (char*)ptr - kUsedHeadSize;
			int pos = *(int*)ptr;

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			usedBuddyCount -= 1;
			freeCount += 1;
#endif // COCOS2D_DEBUG
			usedBuddySize -= 1 << pos;

			int head = ((char*)ptr - buff) >> pos;
			if ((head & 0x1) || pos == kBuddyMemMaxBitSize)
			{
				pushBuddyHead(pos, head);
			}
			else
			{
				// free buddy together
				for (int i = pos; i <= kBuddyMemMaxBitSize; ++i)
				{
					int head = ((char*)ptr - buff) >> i;
					int headBuddy = head ^ 0x1;

					if ((head & 0x1) || i == kBuddyMemMaxBitSize)
					{
						pushBuddyHead(i, head);
						return;
					}

					int bidx = head >> 1;
					int bi = bidx >> 3; // /8
					int bj = bidx & 0x7; // %8

					BuddyHead& bh = buddyHeads[i];
					bh.lock();

					// check buddy
					char merge = bh.buddy[bi] & (1 << bj);
					if (!merge)
					{
						pushBuddyHead(i, head, false);
						bh.unlock();
						return;
					}

					// free buddy
					BuddyFree* pfree = (BuddyFree*)(buff + (1 << i) * headBuddy);
					bool isHead = pfree->prev == -1;
					if (pfree->prev != -1)
					{
						BuddyFree* pfreePrev = (BuddyFree*)(buff + (1 << i) * pfree->prev);
						pfreePrev->next = pfree->next;
					}

					if (pfree->next != -1)
					{
						BuddyFree* pfreeNext = (BuddyFree*)(buff + (1 << i) * pfree->next);
						pfreeNext->prev = pfree->prev;
					}

					bh.free--;

					// 1 -> 0
					bh.buddy[bi] = bh.buddy[bi] ^ merge;

					// pop head
					if (isHead)
						bh.head = pfree->next;

					bh.unlock();

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
					mergeBuddyCount += 1;
#endif // COCOS2D_DEBUG
				}
			}
			return;
		}
		free(ptr);
	}

	inline bool isMyAlloc(void* ptr)
	{
		return buff <= ptr && ptr < buffEnd;
	}

	inline size_t possibleMemSize(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int pos = *(int*)((char*)ptr - kUsedHeadSize);
			size_t buddySize = (1 << pos) - kUsedHeadSize;
			return buddySize;
		}
		return 0;
	}

protected:
	char* buff;
	char* buffEnd;
	BuddyHead buddyHeads[kBuddyMemMaxBitSize + 1];
};


//////////////////////////////////////////////////////////////////////////

const int kSmallPoolKind = 9;
const int kSmallMemMaxSize = 1 << (kSmallPoolKind - 1);
const int kSmallMinSize = 1 << 4; // 16 bytes
extern const int kSmallPoolSize[kSmallPoolKind];

// 24 bits for index
// the max was 16 M mem blocks be support
inline int head_idx(int head)
{
	return head & ((1 << 24) - 1);
}

inline int idxtag_head(int tag, int idx)
{
	return (tag << 24) | (idx & ((1 << 24) - 1));
}

struct SmallHead
{
	std::atomic_int32_t head;
	std::atomic_int32_t tag;
	int free; // for debug
	int peak; // for debug
	int level;
	char* buff;

	inline char* popHeadPtr()
	{
		int h = head.load(std::memory_order_relaxed);
		while (h != -1)
		{
			int idx = head_idx(h);
			char* ptr = buff + (idx << level);
			int next = *(int*)ptr;
			if (head.compare_exchange_strong(h, next))
			{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				free--;
				peak = std::max(peak, kSmallPoolSize[level] - free);
#endif // COCOS2D_DEBUG
				return ptr;
			}
		}
		return nullptr;
	}

	inline void pushHeadPtr(char* ptr)
	{
		int t = tag.fetch_add(1);
		int idx = (ptr - buff) >> level;
		int& h = *(int*)ptr;
		int next = idxtag_head(t, idx);
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
		free++;
#endif // COCOS2D_DEBUG
		while (!head.compare_exchange_strong(h, next));
	}
};

class CC_DLL TJSmallAllocator
{
public:
	TJSmallAllocator()
	{
		int sum = 0;
		for (int i = 0; i < kSmallPoolKind; i++)
			sum += (1 << i) * kSmallPoolSize[i];
		buff = (char*)malloc(sum);
		buffEnd = buff + sum;

		char* p = buff;
		for (int i = 0; i < kSmallPoolKind; i++)
		{
			heads[i].head = -1;
			heads[i].tag = 1;
			heads[i].level = i;
			heads[i].free = kSmallPoolSize[i];
			heads[i].peak = 0;
			heads[i].buff = p;
			if (kSmallPoolSize[i] > 0)
			{
				heads[i].head = 0;
				for (int j = 0; j < kSmallPoolSize[i]; j++, p += 1 << i)
					*(int*)p = j + 1;
				*(int*)(p - (1 << i)) = -1;
			}
		}
	}

	inline int ptrpos(char* ptr)
	{
		int l = 4;
		int r = kSmallPoolKind;
		while (l < r)
		{
			int p = (l + r) >> 1;
			if (heads[p].buff <= ptr)
				l = p + 1;
			else
				r = p; // ptr < p
		}
		return r - 1;
	}

	inline void* allocate(size_t size, bool useSys = true)
	{
		size_t raw = size;
		if (size > kSmallMemMaxSize)
		{
			if (useSys)
			{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				missCount += 1;
#endif // COCOS2D_DEBUG
				return malloc(raw);
			}
			return nullptr;
		}

		if (size < kSmallMinSize)
			size = kSmallMinSize;
		else
			size = nextPow2BlockSize(size);
		int pos = get_bit_idx(size);
		void* ret = heads[pos].popHeadPtr();
		if (ret == nullptr)
		{
			// try bigger again, but no more bigger
			if (++pos < kSmallPoolKind)
				ret = heads[pos].popHeadPtr();
		}
		if (ret == nullptr)
		{
			if (useSys)
			{
#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
				missCount += 1;
#endif // COCOS2D_DEBUG
				return malloc(raw);
			}
			return nullptr;
		}

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
		allocCount += 1;
		usedSmallCount += 1;
#endif // COCOS2D_DEBUG
		usedSmallSize += 1 << pos;

		return ret;
	}

	inline void* reallocate(void* ptr, size_t size, bool useSys = true)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int pos = ptrpos((char*)ptr);
			if (size > (1u << pos))
			{
				// new and copy
				void* newptr = allocate(size, useSys);
				if (newptr == nullptr)
					return nullptr;
				memcpy(newptr, ptr, 1u << pos);

				// free
				deallocate(ptr);

				ptr = newptr;
			}
			return ptr;
		}
		if (useSys)
			return realloc(ptr, size);
		return nullptr;
	}

	inline void deallocate(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int pos = ptrpos((char*)ptr);
			assert(heads[pos].buff <= ptr);
			assert(pos + 1 >= kSmallPoolKind || ptr < heads[pos + 1].buff);

			heads[pos].pushHeadPtr((char*)ptr);

#if defined(COCOS2D_DEBUG) && (COCOS2D_DEBUG > 0)
			freeCount += 1;
			usedSmallCount -= 1;
#endif // COCOS2D_DEBUG
			usedSmallSize -= 1 << pos;

			return;
		}
		free(ptr);
	}

	inline bool isMyAlloc(void* ptr)
	{
		return buff <= ptr && ptr < buffEnd;
	}

	inline size_t possibleMemSize(void* ptr)
	{
		if (buff <= ptr && ptr < buffEnd)
		{
			int pos = ptrpos((char*)ptr);
			return 1u << pos;
		}
		return 0;
	}

protected:
	char* buff;
	char* buffEnd;
	SmallHead heads[kSmallPoolKind];
};


/** Make visible at the global scope.*/
extern CC_DLL TJAllocator tjAllocatorGlobal;
extern CC_DLL TJBuddyAllocator tjBuddyAllocatorGlobal;
extern CC_DLL TJSmallAllocator tjSmallAllocatorGlobal;

class CC_DLL TJFixedMem
{
public:
	TJFixedMem()
		:bytes(nullptr),
		size(0)
	{
	}

	~TJFixedMem()
	{
		clear();
	}

	TJFixedMem(TJFixedMem&& other)
		:bytes(other.bytes),
		size(other.size)
	{
		other.reset();
	}

	TJFixedMem& operator= (TJFixedMem&& other)
	{ 
		if (this != &other)
		{
			clear();
			bytes = other.bytes;
			size = other.size;
			other.reset();
		}
		return *this;
	}

	void assign(char* p, size_t s)
	{
		clear();
		bytes = p;
		size = s;
	}

	void resize(size_t s)
	{
		if (bytes)
		{
			if (s > size)
				bytes = (char*)tj_realloc(bytes, s);
		}
		else
			bytes = (char*)tj_malloc(s);
		size = s;
	}

	void clear()
	{
		if (bytes)
			tj_free(bytes);
		reset();
	}

	void reset()
	{
		bytes = nullptr;
		size = 0;
	}

	char* bytes;
	size_t size;

private:
	TJFixedMem(const TJFixedMem& other) {}

	TJFixedMem& operator= (const TJFixedMem& other) { return *this; }
};


// class TJJsonAllocator {
// public:
// 	static const bool kNeedFree = true;
// 	void* Malloc(size_t size) {
// 		return tjAllocatorGlobal.allocate(size);
// 	}
// 	void* Realloc(void* originalPtr, size_t originalSize, size_t newSize) {
// 		(void)originalSize;
// 		return tjAllocatorGlobal.reallocate(originalPtr, newSize);
// 	}
// 	static void Free(void *ptr) {
// 		tjAllocatorGlobal.deallocate(ptr);
// 	}
// };

NS_CC_ALLOCATOR_END
NS_CC_END



/// @endcond
#endif//TJ_ALLOCATOR_H
