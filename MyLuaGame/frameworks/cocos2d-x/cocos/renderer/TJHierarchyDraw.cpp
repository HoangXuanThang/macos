#include "TJHierarchyDraw.h"

#include <algorithm>
#include <functional>
#include "base/allocator/TJAllocator.h"

TJ_PROFILE_DOMAIN_DEF(__HierarchyDraw, "tianji.HierarchyDraw");

NS_CC_BEGIN

// singleton stuff
static HierarchyDrawManager* s_SharedHierarchyDrawManager = nullptr;

static std::vector<HierarchyDraw*> s_HierarchyDrawPool;

HierarchyDraw* HierarchyDraw::create(Node* node, const HierarchyDrawCallback& draw, SyncDrawType sync)
{
	if (s_HierarchyDrawPool.empty())
		return new HierarchyDraw(node, draw, sync);

	HierarchyDraw* ret = *s_HierarchyDrawPool.rbegin();
	s_HierarchyDrawPool.pop_back();
	ret->_node = node;
	ret->_sync = sync;
	ret->_drawCallback = draw;
	ret->_flags = 0;
	return ret;
}

HierarchyDraw * HierarchyDraw::create(Node * node, uint32_t flags)
{
	if (s_HierarchyDrawPool.empty())
		return new HierarchyDraw(node, flags);

	HierarchyDraw* ret = *s_HierarchyDrawPool.rbegin();
	s_HierarchyDrawPool.pop_back();
	ret->_node = node;
	ret->_sync = NoSync;
	ret->_drawCallback = nullptr;
	ret->_flags = flags;
	return ret;
}

HierarchyDraw* HierarchyDraw::createCallback(const HierarchyDrawCallback& draw, SyncDrawType sync)
{
	if (s_HierarchyDrawPool.empty())
		return new HierarchyDraw(nullptr, draw, sync);

	HierarchyDraw* ret = *s_HierarchyDrawPool.rbegin();
	s_HierarchyDrawPool.pop_back();
	ret->_node = nullptr;
	ret->_sync = sync;
	ret->_drawCallback = draw;
	ret->_flags = 0;
	return ret;
}

void HierarchyDraw::draw(Renderer* renderer, int pos, int size)
{
	if (_drawCallback)
		_drawCallback(pos, size);
	else
		_node->draw(renderer, _node->_modelViewTransform, _flags);
}

void HierarchyDraw::release()
{
	this->_node = nullptr;
	this->_drawCallback = nullptr;
	s_HierarchyDrawPool.push_back(this);
}


////////////////////////////////////////
//
// HierarchyDrawManager
//

HierarchyDrawManager* HierarchyDrawManager::getInstance()
{
	if (!s_SharedHierarchyDrawManager)
	{
		s_SharedHierarchyDrawManager = new (std::nothrow) HierarchyDrawManager;
		CCASSERT(s_SharedHierarchyDrawManager, "FATAL: Not enough memory");
		s_SharedHierarchyDrawManager->init();
	}

	return s_SharedHierarchyDrawManager;
}

bool HierarchyDrawManager::isInHierarchyMode()
{
	return _stackTop && _stackTop->curChild >= 0;
}

int HierarchyDrawManager::runHierarchyWith(Renderer* renderer, ui::LuaListRenderHintType hint, Node* node, Vector<ui::Widget*>& siblings, const HierarchyEndCallback& onEnd)
{
	if (_wait.node != nullptr)
	{
		CCLOG("hierarchy not begin");
		return 0;
	}

	_wait.renderer = renderer;
	_wait.node = node;
	_wait.draws.clear();
	_wait.draws.reserve(siblings.size());
	_wait.onEnd = onEnd;
	_wait.visitDeep = 0;
	_wait.curSibling = -1;
	_wait.curChild = -1;
	_wait.siblingStartIndex = 0;
	_wait.siblingNum = siblings.size();
	_wait.siblings.clear();
	_wait.siblings.reserve(siblings.size());
	_wait.hint = hint;
	_wait.nests.clear();
	if (hint == ui::LUA_ISOMORPH_2D)
		_wait.nests.reserve(siblings.size());
	for (auto& sibling : siblings)
		_wait.siblings.insert(sibling);

	return 0;
}

void HierarchyDrawManager::drawHierarchy2DBegin(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size)
{
	for (int i = 0; i < cur->siblingStartIndex; i++)
	{
		for (HierarchyDraw* draw : cur->draws[i])
		{
			draw->draw(cur->renderer, -1, -1);
			draw->release();
		}
	}
}

void HierarchyDrawManager::drawHierarchy2DDraw(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size)
{
	if (pos != size - 1 && size != -1)
		return;

	int siblingNum = 0;
	for (HierarchySiblings* sibling : parent->nests)
		siblingNum += sibling->siblingNum;

	std::vector<std::pair<NodeDraws::iterator, NodeDraws::iterator>> drawIters;
	drawIters.reserve(siblingNum);
	for (HierarchySiblings* sibling : parent->nests)
	{
		for (int j = 0; j < sibling->siblingNum; j++)
			drawIters.push_back({ sibling->draws[j + sibling->siblingStartIndex].begin(), sibling->draws[j + sibling->siblingStartIndex].end() });
	}
	drawHierarchyOfSibling(cur->renderer, drawIters);
}

void HierarchyDrawManager::drawHierarchy2DEnd(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size)
{
	for (int i = cur->siblingStartIndex + cur->siblingNum; i < cur->draws.size(); i++)
	{
		for (HierarchyDraw* draw : cur->draws[i])
		{
			draw->draw(cur->renderer, -1, -1);
			draw->release();
		}
	}

	cur->onEnd(false);
	delete cur;

	if (pos == size - 1 || size == -1)
		parent->nests.clear();
}

void HierarchyDrawManager::drawHierarchyNest(HierarchySiblings* cur)
{
	drawHierarchy(*cur);

	cur->onEnd(false);
	delete cur;
}

bool HierarchyDrawManager::mergeHierarchy(HierarchySiblings* h, HierarchySiblings* parent)
{
	std::vector<HierarchyDraw *>* parentDraws = nullptr;
	if (parent->curChild >= 0)
		parentDraws = &parent->draws[parent->curChild];

	if (!parentDraws)
		return false;

	if (h->hint != ui::LUA_UNKNOWN && parent->hint == h->hint + 1)
	{
		// should be h->hint + 1 == parent->hint
		parent->nests.push_back(h);
		parentDraws->push_back(HierarchyDraw::createCallback(std::bind(&HierarchyDrawManager::drawHierarchy2DBegin, this, h, parent, std::placeholders::_1, std::placeholders::_2), Hierarchy2DBegin));
		parentDraws->push_back(HierarchyDraw::createCallback(std::bind(&HierarchyDrawManager::drawHierarchy2DDraw, this, h, parent, std::placeholders::_1, std::placeholders::_2), Hierarchy2DDraw));
		parentDraws->push_back(HierarchyDraw::createCallback(std::bind(&HierarchyDrawManager::drawHierarchy2DEnd, this, h, parent, std::placeholders::_1, std::placeholders::_2), Hierarchy2DEnd));
	}
	else
	{
		// h draw himself, no merge to parent, but need recursion

		// same with deep first draw
		// diff with visit, it could be batch stencil draw
		parentDraws->push_back(HierarchyDraw::createCallback(std::bind(&HierarchyDrawManager::drawHierarchyNest, this, h), HierarchyNest));
	}

	return true;
}

TJ_PROFILE_TASK_DEF(__endHierarchy);
void HierarchyDrawManager::endHierarchy()
{
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__HierarchyDraw, __endHierarchy);

	HierarchySiblings* top = _stack.top();
	_stack.pop();

	bool isomorphism = true; // weak determine
	if (top->curSibling > 0)
	{
		int drawsCnt = 0;
		for (int i = top->siblingStartIndex; i <= top->siblingStartIndex + top->curSibling; i++)
		{
			drawsCnt += top->draws[i].empty() ? 0 : 1;
			if (drawsCnt > 1)
				break;
		}
		// only one or none
		if (drawsCnt <= 1)
			isomorphism = false;
	}
	else
	{
		// only one or none
		isomorphism = false;
	}

	bool mergeToParent = false;
	if (isomorphism)
	{
		if (!_stack.empty())
		{
			HierarchySiblings* parent = _stack.top();
			// must be merge draw in nest mode, whether 2d tableview
			// because some Begin and End place in parent, and Draw in children
			mergeToParent = mergeHierarchy(top, parent);
		}

		if (!mergeToParent)
			drawHierarchy(*top);
	}
	else
		drawRaw(*top);

	if (!mergeToParent)
	{
		top->onEnd(!isomorphism);
		delete top;
	}

	if (_stack.empty())
	{
		_stackTop = nullptr;
		_curDraws = nullptr;
	}
	else
	{
		_stackTop = _stack.top();
		if (_stackTop->curChild >= 0)
			_curDraws = &_stackTop->draws[_stackTop->curChild];
	}

	TJ_PROFILE_DOMAIN_TASK_END(__HierarchyDraw);
}

void HierarchyDrawManager::onVisit(Node* node)
{
	if (_wait.node == node)
	{
		HierarchySiblings* h = new HierarchySiblings();
		_wait.swap(*h);
		_stack.push(h);
		_stackTop = _stack.top();
		_curDraws = nullptr;
		_wait.node = nullptr;
	}

	if (_stackTop)
		_stackTop->visitDeep++;
}

void HierarchyDrawManager::onVisitEnd(Node* node)
{
	if (_stackTop == nullptr)
		return;

	_stackTop->visitDeep--;
	if (node == _stackTop->node)
		endHierarchy();
}

void HierarchyDrawManager::onSiblingVisit(Node* node)
{
	if (_stackTop == nullptr || _stackTop->visitDeep > 1)
		return;

	HierarchySiblings& top = *_stackTop;
	if (top.siblings.find(node) == top.siblings.end())
	{
		int index = top.draws.size();
		top.draws.resize(index + 1);
		top.curChild = index;
	}
	else // its sibling
	{
		top.curSibling++;
		if (top.curSibling == 0)
		{
			top.siblingStartIndex = top.draws.size();
			top.draws.resize(top.siblingStartIndex + top.siblingNum); // sibling will draw one by one
			for (int i = top.siblingStartIndex; i < top.siblingStartIndex + top.siblingNum; i++)
				top.draws[i].reserve(8);
		}
		top.curChild = top.curSibling + top.siblingStartIndex;
	}
	_curDraws = &top.draws[top.curChild];
}

void HierarchyDrawManager::pushDraw(Node* node, uint32_t flags)
{
	CCASSERT(_curDraws != nullptr, "no child be detected in the current");
	_curDraws->push_back(HierarchyDraw::create(node, flags));
}

void HierarchyDrawManager::pushSyncDraw(Node* node, SyncDrawType type, const HierarchyDrawCallback& draw)
{
	CCASSERT(_curDraws != nullptr, "no child be detected in the current");
	_curDraws->push_back(HierarchyDraw::create(node, draw, type));
}

void HierarchyDrawManager::init()
{
	_stackTop = nullptr;
	_curDraws = nullptr;
	_wait.node = nullptr;

	s_HierarchyDrawPool.reserve(64);
}

// #define IS_DEEP(t, d) ((1<<(d)) & (t))
// #define SET_DEEP(t, d) t |= (1<<(d))
// #define UNSET_DEEP(t, d) t ^= (1<<(d))

#define IS_DEEP(t, d) ((d) == (t))
#define SET_DEEP(t, d) t = d
#define UNSET_DEEP(t, d) t = (d) - 1

void HierarchyDrawManager::drawHierarchyOfSibling(Renderer* renderer, std::vector<std::pair<NodeDraws::iterator, NodeDraws::iterator>>& drawIters)
{
	int siblingNum = drawIters.size();
	int nDrawables = 0;
	int curDeep = 0;
	int* drawables = (int*)tj_malloc(sizeof(int)*siblingNum);
	int* drawDeep = (int*)tj_malloc(sizeof(int)*siblingNum);
	bool* drawHash = (bool*)tj_malloc(sizeof(bool)*siblingNum);
	int* nextDraws = (int*)tj_malloc(sizeof(int)*(siblingNum + 1));
	std::vector<NodeDraws::iterator> nextSyncs;
	nextSyncs.resize(siblingNum);
	for (int j = 0; j < siblingNum; j++)
	{
		nextSyncs[j] = drawIters[j].first;
		drawHash[j] = true;
		drawables[nDrawables++] = j;
		SET_DEEP(drawDeep[j], curDeep);
	}

	// sync point with deep
	// [b d [b d         e] e]
	// [b d [b d [b d e] e] e]
	//
	// [b d e][b d e]
	// [b d e][b d e][b d e]
	//
	// [b d e]
	// [b d     e]
	// [b d [b d e] e]
	while (true)
	{
		bool loop = false;
		SyncDrawType curSync = NoSync;
		// check next loop
		for (int j = 0; j < siblingNum; j++)
		{
			auto& sibling = drawIters[j];
			// not end
			if (sibling.first != sibling.second)
			{
				loop = true;
				if (!drawHash[j])
					continue;

				// find max sync point in the same deep
				HierarchyDraw* draw = *sibling.first;
				curSync = std::max(curSync, draw->_sync);
			}
			// search next sync point in drawables
			auto& sync = nextSyncs[j];
			if (sibling.first >= sync)
			{
				for (sync = sibling.first; sync != sibling.second; ++sync)
				{
					HierarchyDraw* draw = *sync;
					if (draw->_sync != NoSync)
						break;
				}
			}
		}
		if (!loop)
			break;

		if (curSync == NoSync)
		{
			int syncStepMin = 999999;
			int stepMax = 0;
			for (int i = 0; i < nDrawables; i++)
			{
				int j = drawables[i];
				auto& sibling = drawIters[j];
				auto& sync = nextSyncs[j];
				int d = sync - sibling.first;
				// d == 0 was draw end
				if (d > 0)
					syncStepMin = std::min(d, syncStepMin);
				int offset = sibling.second - sibling.first;
				stepMax = std::max(offset, stepMax);
			}
			// if exist any sync point in the drawables, must syncStepMin <= stepMin
			if (syncStepMin < 999999)
				stepMax = syncStepMin;
			CCASSERT(stepMax > 0, "draw step max must be >0");
			for (int k = 0; k < stepMax; k ++)
			{
				for (int i = 0; i < nDrawables; i++)
				{
					int j = drawables[i];
					auto& sibling = drawIters[j];
					// not end
					if (sibling.first != sibling.second)
					{
						HierarchyDraw* draw = *sibling.first;
						// forward
						draw->draw(renderer, i, nDrawables);
						draw->release();
						++sibling.first;
					}
				}
			}
		}
		else
		{
			bool isDeepSyncBegin = curSync == ClippingBegin || curSync == LayoutBegin || curSync == Hierarchy2DBegin || curSync == HierarchyNest;
			bool isDeepSyncEnd = curSync == ClippingEnd || curSync == LayoutEnd || curSync == Hierarchy2DEnd || curSync == HierarchyNest;

			// check drawables
			if (isDeepSyncBegin)
			{
				nDrawables = 0;
				for (int j = 0; j < siblingNum; j++)
				{
					drawHash[j] = false;
					const auto& sibling = drawIters[j];
					const auto& sync = nextSyncs[j];
					// sync != end
					if (sync != sibling.second)
					{
						HierarchyDraw* syncDraw = *sync; // next sync
						 // if same sync type and same sync deep, wait all relative sync draws
						if (IS_DEEP(drawDeep[j], curDeep) && syncDraw->_sync == curSync)
						{
							drawHash[j] = true;
							drawables[nDrawables++] = j;
							HierarchyDraw* draw = *sibling.first; // cur draw
						}
					}
				}

				++curDeep;
				CCASSERT(curDeep <= 30, "draw too deep");
				CCASSERT(nDrawables > 0, "no drawables");
				for (int i = 0; i < nDrawables; i++)
					SET_DEEP(drawDeep[drawables[i]], curDeep);
			}

			// draw drawables until all sync came
			// but may be more deep sync point coming, break the loop
			bool sameSync = true;
			for (int i = 0; i < nDrawables; i++)
				nextDraws[i] = 1;
			nextDraws[nDrawables] = 0;
			while (sameSync)
			{
				// jump to the first draw by num in the n-th(not real existed)
				// nextDraws like a skip list for effective iteration
				int pre = nDrawables;
				int syncReady = nextDraws[pre];
				for (int i = nextDraws[pre]; i < nDrawables; )
				{
					auto& sibling = drawIters[drawables[i]];
					// not end
					if (sibling.first != sibling.second)
					{
						HierarchyDraw* draw = *sibling.first;
						// new sync coming
						if (draw->_sync != NoSync && draw->_sync != curSync)
						{
							sameSync = false;
							break;
						}

						// NoSync or curSync
						if (draw->_sync == NoSync)
						{
							pre = i;
							// forward
							draw->draw(renderer, i, nDrawables);
							draw->release();
							++sibling.first;
						}
						else
						{
							++syncReady;
							++nextDraws[pre];
						}
						syncReady += nextDraws[i] - 1;
						i += nextDraws[i];
					}
					else
					{
						CCASSERT(false, "empty in drawables");
					}
				}
				// all sync ready
				if (syncReady == nDrawables)
				{
					for (int i = 0; i < nDrawables; i++)
					{
						auto& sibling = drawIters[drawables[i]];
						HierarchyDraw* draw = *sibling.first;
						// forward
						draw->draw(renderer, i, nDrawables);
						draw->release();
						++sibling.first;
					}
					break;
				}
			}
			// check sync in next iter, curSync may be changed by priority
			if (!sameSync)
				continue;

			// all siblings could be draw when the sync draw over
			if (isDeepSyncEnd)
			{
				for (int i = 0; i < nDrawables; i++)
					UNSET_DEEP(drawDeep[drawables[i]], curDeep);
				--curDeep;
				CCASSERT(curDeep >= 0, "draw deep corrupted");

				// find siblings which same deep, there were must be previous drawable sets
				nDrawables = 0;
				for (int j = 0; j < siblingNum; j++)
				{
					drawHash[j] = false;
					if (IS_DEEP(drawDeep[j], curDeep))
					{
						drawHash[j] = true;
						drawables[nDrawables++] = j;
					}
				}
			}
		}
	}

	tj_free(drawables);
	tj_free(nextDraws);
	tj_free(drawHash);
	tj_free(drawDeep);
}

void HierarchyDrawManager::drawHierarchy(HierarchySiblings& h)
{
	for (int i = 0; i < h.siblingStartIndex; i ++)
	{
		for (HierarchyDraw* draw : h.draws[i])
		{
			draw->draw(h.renderer, -1, -1);
			draw->release();
		}
	}

	std::vector<std::pair<NodeDraws::iterator, NodeDraws::iterator>> drawIters;
	drawIters.resize(h.siblingNum);
	for (int j = 0; j < h.siblingNum; j++)
		drawIters[j] = { h.draws[j + h.siblingStartIndex].begin(), h.draws[j + h.siblingStartIndex].end() };
	drawHierarchyOfSibling(h.renderer, drawIters);

	for (int i = h.siblingStartIndex + h.siblingNum; i < h.draws.size(); i++)
	{
		for (HierarchyDraw* draw : h.draws[i])
		{
			draw->draw(h.renderer, -1, -1);
			draw->release();
		}
	}
}

void HierarchyDrawManager::drawRaw(HierarchySiblings& h)
{
	for (auto& draws : h.draws)
	{
		for (HierarchyDraw* draw : draws)
		{
			draw->draw(h.renderer, -1, -1);
			draw->release();
		}
	}
}

NS_CC_END

