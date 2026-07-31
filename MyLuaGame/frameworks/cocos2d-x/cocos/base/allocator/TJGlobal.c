

void* tj_malloc(size_t size)
{
	return cocos2d::allocator::tjAllocatorGlobal.allocate(size);
}

void tj_free(void* ptr)
{
	cocos2d::allocator::tjAllocatorGlobal.deallocate(ptr);
}

void* tj_realloc(void* ptr, size_t size)
{
	return cocos2d::allocator::tjAllocatorGlobal.reallocate(ptr, size);
}