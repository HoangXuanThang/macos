
#include "base/ccMacros.h"
#include "base/allocator/TJAllocator.h"

std::atomic_int usedBuddyCount;
std::atomic_int allocCount;
std::atomic_int mergeBuddyCount;
std::atomic_int splitBuddyCount;
std::atomic_int freeCount;
std::atomic_int missCount;
std::atomic_int usedSmallCount;

std::atomic_int usedFixedSize;
std::atomic_int usedBuddySize;
std::atomic_int usedSmallSize;

TJ_PROFILE_DOMAIN_DEF(__Allocator, "tianji.Allocator");
TJ_PROFILE_DOMAIN_DEF(__SmallAllocatorGlobal, "tianji.SmallAllocatorGlobal");
TJ_PROFILE_DOMAIN_DEF(__BuddyAllocatorGlobal, "tianji.tjBuddyAllocatorGlobal");
TJ_PROFILE_DOMAIN_DEF(__AllocatorGlobal, "tianji.AllocatorGlobal");

NS_CC_BEGIN
NS_CC_ALLOCATOR_BEGIN

// 参数测试基准
// 登录游戏-进入编队界面-显示6个精灵spine
// 占用峰值 9,142,192 bytes
// [4] = 33497
// [5] = 15361
// [6] = 6456
// [7] = 6648
// [8] = 5642
// [9] = 3803
// [10] = 3378
//
// 登录游戏-新手关卡-显示12个精灵spine
// 占用峰值 49,259,584 bytes
// [4] = 131072
// [5] = 131072
// [6] = 36999
// [7] = 36103
// [8] = 23125
// [9] = 17889
// [10] = 10756
//
// 编队界面
// alloc	33348784	int
// realAlloc	22615662	int
// 1.0*realAlloc / alloc	0.67815552135274260	double
// 
// 主城界面
// alloc	27085248	int
// realAlloc	18355629	int
// 1.0*realAlloc / alloc	0.67769839139002896	double
//
// 15MB bytes in pool
const int kSmallPoolSize[kSmallPoolKind] = {
	0, // 0
	0, // 1
	0, // 2
	0, // 3, 8 bytes
	128 * 1024, // 4, 16 bytes
	64 * 1024, // 5, 32 bytes
	48 * 1024, // 6, 64 bytes
	32 * 1024, // 7, 128 bytes
	16 * 1024, // 8, 256 bytes
// 	16 * 1024, // 9, 512 bytes
// 	8 * 1024, // 10, 1024 bytes
};

TJAllocator tjAllocatorGlobal;
TJBuddyAllocator tjBuddyAllocatorGlobal;
TJSmallAllocator tjSmallAllocatorGlobal;


NS_CC_ALLOCATOR_END
NS_CC_END

using namespace cocos2d::allocator;

TJ_PROFILE_TASK_DEF(__tj_malloc);
TJ_PROFILE_TASK_DEF(__tj_malloc1);
TJ_PROFILE_TASK_DEF(__tj_malloc2);
TJ_PROFILE_TASK_DEF(__tj_malloc3);
void* tj_malloc(size_t size)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__Allocator, __tj_malloc);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__SmallAllocatorGlobal, __tj_malloc1);
	void* ret = tjSmallAllocatorGlobal.allocate(size, false);
	TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);

	if (ret == NULL)
	{
		TJ_PROFILE_DOMAIN_TASK_BEGIN(__BuddyAllocatorGlobal, __tj_malloc2);
		ret = tjBuddyAllocatorGlobal.allocate(size, false);
		TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);
	}
	if (ret == NULL)
	{
		TJ_PROFILE_DOMAIN_TASK_BEGIN(__AllocatorGlobal, __tj_malloc3);
		ret = tjAllocatorGlobal.allocate(size);
		TJ_PROFILE_DOMAIN_TASK_END(__AllocatorGlobal);
	}

	TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
	return ret;
}

void* tj_calloc(size_t num, size_t size)
{
	size_t ssize = num * size;
	void* ret = tj_malloc(ssize);
	if (ret)
		memset(ret, 0, ssize);
	return ret;
}

TJ_PROFILE_TASK_DEF(__tj_realloc);
TJ_PROFILE_TASK_DEF(__tj_realloc1);
TJ_PROFILE_TASK_DEF(__tj_realloc2);
TJ_PROFILE_TASK_DEF(__tj_realloc3);
void* tj_realloc(void* ptr, size_t size)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__Allocator, __tj_realloc);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__SmallAllocatorGlobal, __tj_realloc1);
	if (tjSmallAllocatorGlobal.isMyAlloc(ptr))
	{
		void* newptr = tjSmallAllocatorGlobal.reallocate(ptr, size, false);
		if (newptr)
		{
			TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);
			TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
			return newptr;
		}

		// new and copy
		newptr = tjBuddyAllocatorGlobal.allocate(size);
		if (newptr)
			memcpy(newptr, ptr, size);

		// free
		tjSmallAllocatorGlobal.deallocate(ptr);

		TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);
		TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
		return newptr;
	}
	
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__BuddyAllocatorGlobal, __tj_realloc2);
	if (tjBuddyAllocatorGlobal.isMyAlloc(ptr))
	{
		void* newptr = tjBuddyAllocatorGlobal.reallocate(ptr, size, false);
		if (newptr)
		{
			TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);
			TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
			return newptr;
		}

		// new and copy
		newptr = tjAllocatorGlobal.allocate(size);
		if (newptr)
			memcpy(newptr, ptr, size);
		
		// free
		tjBuddyAllocatorGlobal.deallocate(ptr);

		TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);
		TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
		return newptr;
	}

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__AllocatorGlobal, __tj_realloc3);
	void* newptr = tjAllocatorGlobal.reallocate(ptr, size);
	TJ_PROFILE_DOMAIN_TASK_END(__AllocatorGlobal);
	TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
	return newptr;
}

TJ_PROFILE_TASK_DEF(__tj_free);
TJ_PROFILE_TASK_DEF(__tj_free1);
TJ_PROFILE_TASK_DEF(__tj_free2);
TJ_PROFILE_TASK_DEF(__tj_free3);
void tj_free(void* ptr)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__Allocator, __tj_free);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__SmallAllocatorGlobal, __tj_free1);
	if (tjSmallAllocatorGlobal.isMyAlloc(ptr))
	{
		tjSmallAllocatorGlobal.deallocate(ptr);
		TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);
		TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
		return;
	}
	TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__BuddyAllocatorGlobal, __tj_free2);
	if (tjBuddyAllocatorGlobal.isMyAlloc(ptr))
	{
		tjBuddyAllocatorGlobal.deallocate(ptr);
		TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);
		TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
		return;
	}
	TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__AllocatorGlobal, __tj_free3);
	tjAllocatorGlobal.deallocate(ptr);
	TJ_PROFILE_DOMAIN_TASK_END(__AllocatorGlobal);
	TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
}

TJ_PROFILE_TASK_DEF(__tj_small_malloc);
TJ_PROFILE_TASK_DEF(__tj_small_malloc1);
TJ_PROFILE_TASK_DEF(__tj_small_malloc2);
void* tj_small_malloc(size_t size)
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__Allocator, __tj_small_malloc);

	TJ_PROFILE_DOMAIN_TASK_BEGIN(__SmallAllocatorGlobal, __tj_small_malloc1);
	void* ret = tjSmallAllocatorGlobal.allocate(size, false);
	TJ_PROFILE_DOMAIN_TASK_END(__SmallAllocatorGlobal);
	
	if (ret == NULL)
	{
		TJ_PROFILE_DOMAIN_TASK_BEGIN(__BuddyAllocatorGlobal, __tj_small_malloc2);
		ret = tjBuddyAllocatorGlobal.allocate(size);
		TJ_PROFILE_DOMAIN_TASK_END(__BuddyAllocatorGlobal);
	}

	TJ_PROFILE_DOMAIN_TASK_END(__Allocator);
	return ret;
}

void* tj_small_calloc(size_t num, size_t size)
{
	size_t ssize = num * size;
	void* ret = tj_small_malloc(ssize);
	if (ret)
		memset(ret, 0, ssize);
	return ret;
}


void* tj_small_realloc(void* ptr, size_t size)
{
	if (tjSmallAllocatorGlobal.isMyAlloc(ptr))
	{
		void* newptr = tjSmallAllocatorGlobal.reallocate(ptr, size, false);
		if (newptr)
			return newptr;

		// new and copy
		newptr = tjBuddyAllocatorGlobal.allocate(size);
		if (newptr)
			memcpy(newptr, ptr, size);

		// free
		tjSmallAllocatorGlobal.deallocate(ptr);

		return newptr;
	}
	return tjBuddyAllocatorGlobal.reallocate(ptr, size);
}

