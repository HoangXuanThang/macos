#ifndef __TJ_HIERARCHYDRAW_H__
#define __TJ_HIERARCHYDRAW_H__

#include <stack>
#include <unordered_set>

#include "confuse.h"
#include "2d/CCNode.h"
#include "ui/UIWidget.h"
#include "ui/UILayout.h"
#include "ui/UIListView.h"

// begin > draw > end
// deep first
enum SyncDrawType {
	NoSync = 0,
	HierarchyNest = 1,

	ClippingEnd = 1 << 5,
	LayoutEnd,
	Hierarchy2DEnd,

	ClippingDraw = 1 << 6,
	LayoutDraw,
	Hierarchy2DDraw,

	ClippingBegin = 1 << 7,
	LayoutBegin,
	Hierarchy2DBegin,
};

NS_CC_BEGIN

typedef std::function<void(int pos, int size)> HierarchyDrawCallback;
typedef std::function<void(bool failed)> HierarchyEndCallback;

class CC_DLL HierarchyDraw
{
public:

protected:
	SyncDrawType _sync;
	uint32_t _flags;
	Node* _node;
	HierarchyDrawCallback _drawCallback;

	static HierarchyDraw* create(Node* node, const HierarchyDrawCallback& draw, SyncDrawType sync);
	static HierarchyDraw* create(Node* node, uint32_t flags);
	static HierarchyDraw* createCallback(const HierarchyDrawCallback& draw, SyncDrawType sync);
	
	void draw(Renderer* renderer, int pos, int size);
	void release();

private:
	friend class HierarchyDrawManager;

	CC_DISALLOW_COPY_AND_ASSIGN(HierarchyDraw);

	HierarchyDraw() {}
	~HierarchyDraw() {}

	HierarchyDraw(Node* node, const HierarchyDrawCallback& draw, SyncDrawType sync) :
		_node(node),
		_sync(sync),
		_drawCallback(draw),
		_flags(0)
	{}

	HierarchyDraw(Node* node, uint32_t flags) :
		_node(node),
		_sync(NoSync),
		_drawCallback(nullptr),
		_flags(flags)
	{}
};



class CC_DLL HierarchyDrawManager
{
public:
	static HierarchyDrawManager* getInstance();

	bool isInHierarchyMode();
	int runHierarchyWith(Renderer* renderer, ui::LuaListRenderHintType hint, Node* node, Vector<ui::Widget*>& siblings, const HierarchyEndCallback& onEnd);
	void onVisit(Node* node);
	void onVisitEnd(Node* node);
	void onSiblingVisit(Node* node);

	void pushDraw(Node* node, uint32_t flags);
	void pushSyncDraw(Node* node, SyncDrawType type, const HierarchyDrawCallback& draw);

protected:
	typedef std::vector<HierarchyDraw*> NodeDraws;
	typedef std::vector<NodeDraws> SiblingDraws;

	struct HierarchySiblings
	{
		Renderer* renderer;
		Node* node;
		std::unordered_set<Node*> siblings;
		SiblingDraws draws;
		std::vector<HierarchySiblings*> nests;
		HierarchyEndCallback onEnd;
		int visitDeep;
		int curSibling;
		int curChild;
		int siblingStartIndex;
		int siblingNum;
		ui::LuaListRenderHintType hint;

		void swap(HierarchySiblings& rhs)
		{
			std::swap(renderer, rhs.renderer);
			std::swap(node, rhs.node);
			std::swap(onEnd, rhs.onEnd);
			std::swap(visitDeep, rhs.visitDeep);
			std::swap(curSibling, rhs.curSibling);
			std::swap(curChild, rhs.curChild);
			std::swap(siblingStartIndex, rhs.siblingStartIndex);
			std::swap(siblingNum, rhs.siblingNum);
			std::swap(hint, rhs.hint);

			siblings.swap(rhs.siblings);
			draws.swap(rhs.draws);
			nests.swap(rhs.nests);
		}
	};

	void endHierarchy();

	void init();
	void drawHierarchyOfSibling(Renderer* renderer, std::vector<std::pair<NodeDraws::iterator, NodeDraws::iterator>>& drawIters);
	void drawHierarchy(HierarchySiblings& hierarchy);
	void drawRaw(HierarchySiblings& hierarchy);
	
	bool mergeHierarchy(HierarchySiblings* cur, HierarchySiblings* parent);

	void drawHierarchy2DBegin(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size);
	void drawHierarchy2DDraw(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size);
	void drawHierarchy2DEnd(HierarchySiblings* cur, HierarchySiblings* parent, int pos, int size);

	void drawHierarchyNest(HierarchySiblings* cur);

	std::stack<HierarchySiblings*> _stack;
	HierarchySiblings _wait;
	HierarchySiblings* _stackTop;
	std::vector<HierarchyDraw*>* _curDraws;
};

NS_CC_END

#endif // !__TJ_HIERARCHYDRAW_H__
