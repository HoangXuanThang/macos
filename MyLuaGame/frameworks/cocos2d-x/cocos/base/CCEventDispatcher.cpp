/****************************************************************************
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
#include "base/CCEventDispatcher.h"
#include <algorithm>

#include "base/CCEventCustom.h"
#include "base/CCEventListenerTouch.h"
#include "base/CCEventListenerAcceleration.h"
#include "base/CCEventListenerMouse.h"
#include "base/CCEventListenerKeyboard.h"
#include "base/CCEventListenerCustom.h"
#include "base/CCEventListenerFocus.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC || CC_TARGET_PLATFORM == CC_PLATFORM_LINUX || CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
#include "base/CCEventListenerController.h"
#endif
#include "2d/CCScene.h"
#include "base/CCDirector.h"
#include "base/CCEventType.h"
#include "2d/CCCamera.h"

#include "platform/TJCommon.h"

#define DUMP_LISTENER_ITEM_PRIORITY_INFO 0

enum DirtyVisitFlag
{
	NONE = 0,
	LISTENER = 1 << 0,
	PATH = 1 << 1,
	ALL = LISTENER | PATH
};

TJ_PROFILE_DOMAIN_DEF(__EventDispatcher, "tianji.EventDispatcher");

namespace
{

class DispatchGuard
{
public:
    DispatchGuard(int& count):
            _count(count)
    {
        ++_count;
    }

    ~DispatchGuard()
    {
        --_count;
    }

private:
    int& _count;
};

}

NS_CC_BEGIN

static const EventListener::ListenerID invalidListenerID = "__invalid";
static const EventListener::ListenerID& __getListenerID(Event* event)
{
    switch (event->getType())
    {
        case Event::Type::ACCELERATION:
			return EventListenerAcceleration::LISTENER_ID;
            break;
        case Event::Type::CUSTOM:
            {
                auto customEvent = static_cast<EventCustom*>(event);
				return customEvent->getEventName();
            }
            break;
        case Event::Type::KEYBOARD:
			return EventListenerKeyboard::LISTENER_ID;
            break;
        case Event::Type::MOUSE:
			return EventListenerMouse::LISTENER_ID;
            break;
        case Event::Type::FOCUS:
			return EventListenerFocus::LISTENER_ID;
            break;
        case Event::Type::TOUCH:
            // Touch listener is very special, it contains two kinds of listeners, EventListenerTouchOneByOne and EventListenerTouchAllAtOnce.
            // return UNKNOWN instead.
            CCASSERT(false, "Don't call this method if the event is for touch.");
            break;
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC || CC_TARGET_PLATFORM == CC_PLATFORM_LINUX || CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
        case Event::Type::GAME_CONTROLLER:
			return EventListenerController::LISTENER_ID;
            break;
#endif
        default:
            CCASSERT(false, "Invalid type!");
            break;
    }
    
    return invalidListenerID;
}

EventDispatcher::EventListenerVector::EventListenerVector() :
 _fixedListeners(nullptr),
 _sceneGraphListeners(nullptr),
 _gt0Index(0)
{
}

EventDispatcher::EventListenerVector::~EventListenerVector()
{
    CC_SAFE_DELETE(_sceneGraphListeners);
    CC_SAFE_DELETE(_fixedListeners);
}

size_t EventDispatcher::EventListenerVector::size() const
{
    size_t ret = 0;
    if (_sceneGraphListeners)
        ret += _sceneGraphListeners->size();
    if (_fixedListeners)
        ret += _fixedListeners->size();
    
    return ret;
}

bool EventDispatcher::EventListenerVector::empty() const
{
    return (_sceneGraphListeners == nullptr || _sceneGraphListeners->empty())
        && (_fixedListeners == nullptr || _fixedListeners->empty());
}

void EventDispatcher::EventListenerVector::push_back(EventListener* listener)
{
#if CC_NODE_DEBUG_VERIFY_EVENT_LISTENERS
    CCASSERT(_sceneGraphListeners == nullptr ||
             std::count(_sceneGraphListeners->begin(), _sceneGraphListeners->end(), listener) == 0,
             "Listener should not be added twice!");
        
    CCASSERT(_fixedListeners == nullptr ||
             std::count(_fixedListeners->begin(), _fixedListeners->end(), listener) == 0,
             "Listener should not be added twice!");
#endif

    if (listener->getFixedPriority() == 0)
    {
        if (_sceneGraphListeners == nullptr)
        {
            _sceneGraphListeners = new (std::nothrow) std::vector<EventListener*>();
            _sceneGraphListeners->reserve(100);
        }
        
        _sceneGraphListeners->push_back(listener);
    }
    else
    {
        if (_fixedListeners == nullptr)
        {
            _fixedListeners = new std::vector<EventListener*>();
            _fixedListeners->reserve(100);
        }
        
        _fixedListeners->push_back(listener);
    }
}

void EventDispatcher::EventListenerVector::clearSceneGraphListeners()
{
    if (_sceneGraphListeners)
    {
        _sceneGraphListeners->clear();
        delete _sceneGraphListeners;
        _sceneGraphListeners = nullptr;
    }
}

void EventDispatcher::EventListenerVector::clearFixedListeners()
{
    if (_fixedListeners)
    {
        _fixedListeners->clear();
        delete _fixedListeners;
        _fixedListeners = nullptr;
    }
}

void EventDispatcher::EventListenerVector::clear()
{
    clearSceneGraphListeners();
    clearFixedListeners();
}


EventDispatcher::EventDispatcher()
: _inDispatch(0)
, _isEnabled(false)
, _isInputEnabled(false)
, _nodePriorityIndex(0)
{
    _toAddedListeners.reserve(50);
    _toRemovedListeners.reserve(50);
    
    // fixed #4129: Mark the following listener IDs for internal use.
    // Therefore, internal listeners would not be cleaned when removeAllEventListeners is invoked.
    _internalCustomListenerIDs.insert(EVENT_COME_TO_FOREGROUND);
    _internalCustomListenerIDs.insert(EVENT_COME_TO_BACKGROUND);
    _internalCustomListenerIDs.insert(EVENT_RENDERER_RECREATED);

	_afterDrawListener = addCustomEventListener(Director::EVENT_AFTER_DRAW, [this](EventCustom* event) {
		updateListeners();
	});
}

EventDispatcher::~EventDispatcher()
{
	removeEventListener(_afterDrawListener);
	_afterDrawListener = nullptr;

    // Clear internal custom listener IDs from set,
    // so removeAllEventListeners would clean internal custom listeners.
    _internalCustomListenerIDs.clear();
    removeAllEventListeners();
}


void EventDispatcher::tjVisitTree(Node* node)
{
	node->sortAllChildren();

	int i = 0;
	long nodeData = (long)node->getUserData();
	// may be flag was the old left, carefully!
	bool isListener = (nodeData & DirtyVisitFlag::LISTENER) == DirtyVisitFlag::LISTENER;
	node->setUserData((void*)DirtyVisitFlag::NONE);

	auto& children = node->getChildren();
	auto childrenCount = children.size();

	if (childrenCount > 0)
	{
		Node* child = nullptr;
		// visit children zOrder < 0
		for (; i < childrenCount; i++)
		{
			child = children.at(i);
			if (child && child->getLocalZOrder() < 0)
			{
				if ((long)child->getUserData() == DirtyVisitFlag::NONE)
					continue;
				tjVisitTree(child);
			}
			else
				break;
		}

		if (isListener)
			_globalZOrderNodeMap[node->getGlobalZOrder()].push_back(node);

		for (; i < childrenCount; i++)
		{
			child = children.at(i);
			if (child)
			{
				if ((long)child->getUserData() == DirtyVisitFlag::NONE)
					continue;
				tjVisitTree(child);
			}
		}
	}
	else
	{
		if (isListener)
			_globalZOrderNodeMap[node->getGlobalZOrder()].push_back(node);
	}
}

void EventDispatcher::tjVisitFromRoot(Node* node)
{
	tjVisitTree(node);

	std::vector<float> globalZOrders;
	globalZOrders.reserve(_globalZOrderNodeMap.size());

	for (const auto& e : _globalZOrderNodeMap)
	{
		globalZOrders.push_back(e.first);
	}

	std::stable_sort(globalZOrders.begin(), globalZOrders.end(), [](const float a, const float b) {
		return a < b;
	});

	// userdata is priority, not DirtyVisitFlag anymore
	for (const auto& globalZ : globalZOrders)
	{
		for (Node* n : _globalZOrderNodeMap[globalZ])
		{
			//_nodePriorityMap[n] = ++_nodePriorityIndex;
			n->setUserData((void*)++_nodePriorityIndex);
		}
	}
}

void EventDispatcher::pauseEventListenersForTarget(Node* target, bool recursive/* = false */)
{
    auto listenerIter = _nodeListenersMap.find(target);
    if (listenerIter != _nodeListenersMap.end())
    {
        auto listeners = listenerIter->second;
        for (auto& l : *listeners)
        {
            l->setPaused(true);
        }
    }

    for (auto& listener : _toAddedListeners)
    {
        if (listener->getAssociatedNode() == target)
        {
            listener->setPaused(true);
        }
    }
    
    if (recursive)
    {
        const auto& children = target->getChildren();
        for (const auto& child : children)
        {
            pauseEventListenersForTarget(child, true);
        }
    }
}

void EventDispatcher::resumeEventListenersForTarget(Node* target, bool recursive/* = false */)
{
    auto listenerIter = _nodeListenersMap.find(target);
    if (listenerIter != _nodeListenersMap.end())
    {
        auto listeners = listenerIter->second;
        for (auto& l : *listeners)
        {
            l->setPaused(false);
        }
    }
    
    for (auto& listener : _toAddedListeners)
    {
        if (listener->getAssociatedNode() == target)
        {
            listener->setPaused(false);
        }
    }

    setDirtyForNode(target);
    
    if (recursive)
    {
        const auto& children = target->getChildren();
        for (const auto& child : children)
        {
            resumeEventListenersForTarget(child, true);
        }
    }
}

void EventDispatcher::removeEventListenersForTarget(Node* target, bool recursive/* = false */)
{
    // Ensure the node is removed from these immediately also.
    // Don't want any dangling pointers or the possibility of dealing with deleted objects..
    //_nodePriorityMap.erase(target);
    _dirtyNodes.erase(target);

    auto listenerIter = _nodeListenersMap.find(target);
    if (listenerIter != _nodeListenersMap.end())
    {
        auto listeners = listenerIter->second;
        auto listenersCopy = *listeners;
        for (auto& l : listenersCopy)
        {
			// dissociateNodeAndEventListener will remove the pair in _nodeListenersMap
            removeEventListener(l);
        }
    }
    
    // Bug fix: ensure there are no references to the node in the list of listeners to be added.
    // If we find any listeners associated with the destroyed node in this list then remove them.
    // This is to catch the scenario where the node gets destroyed before it's listener
    // is added into the event dispatcher fully. This could happen if a node registers a listener
    // and gets destroyed while we are dispatching an event (touch etc.)
    for (auto iter = _toAddedListeners.begin(); iter != _toAddedListeners.end(); )
    {
        EventListener * listener = *iter;
            
        if (listener->getAssociatedNode() == target)
        {
            listener->setAssociatedNode(nullptr);   // Ensure no dangling ptr to the target node.
            listener->setRegistered(false);
            releaseListener(listener);
            iter = _toAddedListeners.erase(iter);
        }
        else
        {
            ++iter;
        }
    }
    
    if (recursive)
    {
        const auto& children = target->getChildren();
        for (const auto& child : children)
        {
            removeEventListenersForTarget(child, true);
        }
    }
}

void EventDispatcher::associateNodeAndEventListener(Node* node, EventListener* listener)
{
    std::vector<EventListener*>* listeners = nullptr;
    auto found = _nodeListenersMap.find(node);
    if (found != _nodeListenersMap.end())
    {
        listeners = found->second;
    }
    else
    {
        listeners = new (std::nothrow) std::vector<EventListener*>();
        _nodeListenersMap.emplace(node, listeners);
    }
    
    listeners->push_back(listener);
	// clean node userdata for tjVisitFromRoot by huangwei 2019/12/24
	node->setUserData(0);
}

void EventDispatcher::dissociateNodeAndEventListener(Node* node, EventListener* listener)
{
    std::vector<EventListener*>* listeners = nullptr;
    auto found = _nodeListenersMap.find(node);
    if (found != _nodeListenersMap.end())
    {
        listeners = found->second;
        auto iter = std::find(listeners->begin(), listeners->end(), listener);
        if (iter != listeners->end())
        {
            listeners->erase(iter);
        }
        
        if (listeners->empty())
        {
            _nodeListenersMap.erase(found);
            delete listeners;
        }
    }
}

void EventDispatcher::addEventListener(EventListener* listener)
{
    if (_inDispatch == 0)
    {
        forceAddEventListener(listener);
    }
    else
    {
        _toAddedListeners.push_back(listener);
    }
#if CC_ENABLE_GC_FOR_NATIVE_OBJECTS
    auto sEngine = ScriptEngineManager::getInstance()->getScriptEngine();
    if (sEngine)
    {
        sEngine->retainScriptObject(this, listener);
    }
#endif // CC_ENABLE_GC_FOR_NATIVE_OBJECTS
    listener->retain();
}

void EventDispatcher::forceAddEventListener(EventListener* listener)
{
    EventListenerVector* listeners = nullptr;
    const EventListener::ListenerID& listenerID = listener->getListenerID();
    auto itr = _listenerMap.find(listenerID);
    if (itr == _listenerMap.end())
    {
        
        listeners = new (std::nothrow) EventListenerVector();
        _listenerMap.emplace(listenerID, listeners);
    }
    else
    {
        listeners = itr->second;
    }
    
    listeners->push_back(listener);
    
    if (listener->getFixedPriority() == 0)
    {
        setDirty(listenerID, DirtyFlag::SCENE_GRAPH_PRIORITY);
        
        auto node = listener->getAssociatedNode();
        CCASSERT(node != nullptr, "Invalid scene graph priority!");
        
        associateNodeAndEventListener(node, listener);
        
        if (!node->isRunning())
        {
            listener->setPaused(true);
        }
    }
    else
    {
        setDirty(listenerID, DirtyFlag::FIXED_PRIORITY);
    }
}

void EventDispatcher::addEventListenerWithSceneGraphPriority(EventListener* listener, Node* node)
{
    CCASSERT(listener && node, "Invalid parameters.");
    CCASSERT(!listener->isRegistered(), "The listener has been registered.");
    
    if (!listener->checkAvailable())
        return;
    
    listener->setAssociatedNode(node);
    listener->setFixedPriority(0);
    listener->setRegistered(true);
    
    addEventListener(listener);
}

#if CC_NODE_DEBUG_VERIFY_EVENT_LISTENERS && COCOS2D_DEBUG > 0

void EventDispatcher::debugCheckNodeHasNoEventListenersOnDestruction(Node* node)
{
    // Check the listeners map
    for (const auto & keyValuePair : _listenerMap)
    {
        const EventListenerVector * eventListenerVector = keyValuePair.second;
        
        if (eventListenerVector)
        {
            if (eventListenerVector->getSceneGraphPriorityListeners())
            {
                for (EventListener * listener : *eventListenerVector->getSceneGraphPriorityListeners())
                {
                    CCASSERT(!listener ||
                             listener->getAssociatedNode() != node,
                             "Node should have no event listeners registered for it upon destruction!");
                }
            }
        }
    }
    
    // Check the node listeners map
    for (const auto & keyValuePair : _nodeListenersMap)
    {
        CCASSERT(keyValuePair.first != node, "Node should have no event listeners registered for it upon destruction!");
        
        if (keyValuePair.second)
        {
            for (EventListener * listener : *keyValuePair.second)
            {
                CCASSERT(listener->getAssociatedNode() != node,
                         "Node should have no event listeners registered for it upon destruction!");
            }
        }
    }
    
    // Check the node priority map
    for (const auto & keyValuePair : _nodePriorityMap)
    {
        CCASSERT(keyValuePair.first != node,
                 "Node should have no event listeners registered for it upon destruction!");
    }
    
    // Check the to be added list
    for (EventListener * listener : _toAddedListeners)
    {
        CCASSERT(listener->getAssociatedNode() != node,
                 "Node should have no event listeners registered for it upon destruction!");
    }
    
    // Check the dirty nodes set
    for (Node * dirtyNode : _dirtyNodes)
    {
        CCASSERT(dirtyNode != node,
                 "Node should have no event listeners registered for it upon destruction!");
    }
}

#endif  // #if CC_NODE_DEBUG_VERIFY_EVENT_LISTENERS && COCOS2D_DEBUG > 0


void EventDispatcher::addEventListenerWithFixedPriority(EventListener* listener, int fixedPriority)
{
    CCASSERT(listener, "Invalid parameters.");
    CCASSERT(!listener->isRegistered(), "The listener has been registered.");
    CCASSERT(fixedPriority != 0, "0 priority is forbidden for fixed priority since it's used for scene graph based priority.");
    
    if (!listener->checkAvailable())
        return;
    
    listener->setAssociatedNode(nullptr);
    listener->setFixedPriority(fixedPriority);
    listener->setRegistered(true);
    listener->setPaused(false);

    addEventListener(listener);
}

EventListenerCustom* EventDispatcher::addCustomEventListener(const std::string &eventName, const std::function<void(EventCustom*)>& callback)
{
    EventListenerCustom *listener = EventListenerCustom::create(eventName, callback);
    addEventListenerWithFixedPriority(listener, 1);
    return listener;
}

void EventDispatcher::removeEventListener(EventListener* listener)
{
    if (listener == nullptr)
        return;

	listener->retain();
	listener->setRegistered(false);
    if (listener->getAssociatedNode() != nullptr)
    {
        dissociateNodeAndEventListener(listener->getAssociatedNode(), listener);
		listener->setAssociatedNode(nullptr);  // nullptr out the node pointer so we don't have any dangling pointers to destroyed nodes.
    }
	_toRemovedListeners.push_back(listener);
    
//     // just return if listener is in _toRemovedListeners to avoid remove listeners more than once
// 	if (std::find(_toRemovedListeners.begin(), _toRemovedListeners.end(), listener) != _toRemovedListeners.end())
// 	{
// 		TJ_PROFILE_DOMAIN_TASK_END(__EventDispatcher);
// 		return;
// 	}
// 
//     bool isFound = false;
//     
//     auto removeListenerInVector = [&](std::vector<EventListener*>* listeners){
//         if (listeners == nullptr)
//             return;
//         
//         for (auto iter = listeners->begin(); iter != listeners->end(); ++iter)
//         {
//             auto l = *iter;
//             if (l == listener)
//             {
//                 CC_SAFE_RETAIN(l);
//                 l->setRegistered(false);
//                 if (l->getAssociatedNode() != nullptr)
//                 {
//                     dissociateNodeAndEventListener(l->getAssociatedNode(), l);
//                     l->setAssociatedNode(nullptr);  // nullptr out the node pointer so we don't have any dangling pointers to destroyed nodes.
//                 }
//                 
//                 if (_inDispatch == 0)
//                 {
//                     iter = listeners->erase(iter);
//                     releaseListener(l);
//                 }
//                 else
//                 {
//                     _toRemovedListeners.push_back(l);
//                 }
//                 
//                 isFound = true;
//                 break;
//             }
//         }
//     };
//     
//     for (auto iter = _listenerMap.begin(); iter != _listenerMap.end();)
//     {
//         auto listeners = iter->second;
//         auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
//         auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
// 
//         removeListenerInVector(sceneGraphPriorityListeners);
//         if (isFound)
//         {
//             // fixed #4160: Dirty flag need to be updated after listeners were removed.
//             setDirty(listener->getListenerID(), DirtyFlag::SCENE_GRAPH_PRIORITY);
//         }
//         else
//         {
//             removeListenerInVector(fixedPriorityListeners);
//             if (isFound)
//             {
//                 setDirty(listener->getListenerID(), DirtyFlag::FIXED_PRIORITY);
//             }
//         }
//         
// #if CC_NODE_DEBUG_VERIFY_EVENT_LISTENERS
//         CCASSERT(_inDispatch != 0 ||
//                  !sceneGraphPriorityListeners ||
//                  std::count(sceneGraphPriorityListeners->begin(), sceneGraphPriorityListeners->end(), listener) == 0,
//                  "Listener should be in no lists after this is done if we're not currently in dispatch mode.");
//             
//         CCASSERT(_inDispatch != 0 ||
//                  !fixedPriorityListeners ||
//                  std::count(fixedPriorityListeners->begin(), fixedPriorityListeners->end(), listener) == 0,
//                  "Listener should be in no lists after this is done if we're not currently in dispatch mode.");
// #endif
// 
//         if (iter->second->empty())
//         {
//             _priorityDirtyFlagMap.erase(listener->getListenerID());
//             auto list = iter->second;
//             iter = _listenerMap.erase(iter);
//             CC_SAFE_DELETE(list);
//         }
//         else
//         {
//             ++iter;
//         }
//         
//         if (isFound)
//             break;
//     }
// 
//     if (isFound)
//     {
//         releaseListener(listener);
//     }
//     else
//     {
//         for(auto iter = _toAddedListeners.begin(); iter != _toAddedListeners.end(); ++iter)
//         {
//             if (*iter == listener)
//             {
//                 listener->setRegistered(false);
//                 releaseListener(listener);
//                 _toAddedListeners.erase(iter);
//                 break;
//             }
//         }
//     }

}

void EventDispatcher::setPriority(EventListener* listener, int fixedPriority)
{
    if (listener == nullptr)
        return;
    
    for (auto& iter : _listenerMap)
    {
        auto fixedPriorityListeners = iter.second->getFixedPriorityListeners();
        if (fixedPriorityListeners)
        {
            auto found = std::find(fixedPriorityListeners->begin(), fixedPriorityListeners->end(), listener);
            if (found != fixedPriorityListeners->end())
            {
                CCASSERT(listener->getAssociatedNode() == nullptr, "Can't set fixed priority with scene graph based listener.");
                
                if (listener->getFixedPriority() != fixedPriority)
                {
                    listener->setFixedPriority(fixedPriority);
                    setDirty(listener->getListenerID(), DirtyFlag::FIXED_PRIORITY);
                }
                return;
            }
        }
    }
}

void EventDispatcher::dispatchEventToListeners(EventListenerVector* listeners, const std::function<bool(EventListener*)>& onEvent)
{
    bool shouldStopPropagation = false;
    auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
    auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
    
    ssize_t i = 0;
    // priority < 0
    if (fixedPriorityListeners)
    {
        CCASSERT(listeners->getGt0Index() <= static_cast<ssize_t>(fixedPriorityListeners->size()), "Out of range exception!");
        
        if (!fixedPriorityListeners->empty())
        {
            for (; i < listeners->getGt0Index(); ++i)
            {
                auto l = fixedPriorityListeners->at(i);
                if (l->isEnabled() && !l->isPaused() && l->isRegistered() && onEvent(l))
                {
                    shouldStopPropagation = true;
                    break;
                }
            }
        }
    }
    
    if (sceneGraphPriorityListeners)
    {
        if (!shouldStopPropagation)
        {
            // priority == 0, scene graph priority
            for (auto& l : *sceneGraphPriorityListeners)
            {
                if (l->isEnabled() && !l->isPaused() && l->isRegistered() && onEvent(l))
                {
                    shouldStopPropagation = true;
                    break;
                }
            }
        }
    }
    
    if (fixedPriorityListeners)
    {
        if (!shouldStopPropagation)
        {
            // priority > 0
            ssize_t size = fixedPriorityListeners->size();
            for (; i < size; ++i)
            {
                auto l = fixedPriorityListeners->at(i);
                
                if (l->isEnabled() && !l->isPaused() && l->isRegistered() && onEvent(l))
                {
                    shouldStopPropagation = true;
                    break;
                }
            }
        }
    }
}

void EventDispatcher::dispatchTouchEventToListeners(EventListenerVector* listeners, const std::function<bool(EventListener*)>& onEvent)
{
    bool shouldStopPropagation = false;
    auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
    auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
    
    ssize_t i = 0;
    // priority < 0
    if (fixedPriorityListeners)
    {
        CCASSERT(listeners->getGt0Index() <= static_cast<ssize_t>(fixedPriorityListeners->size()), "Out of range exception!");
        
        if (!fixedPriorityListeners->empty())
        {
            for (; i < listeners->getGt0Index(); ++i)
            {
                auto l = fixedPriorityListeners->at(i);
                if (l->isEnabled() && !l->isPaused() && l->isRegistered() && onEvent(l))
                {
                    shouldStopPropagation = true;
                    break;
                }
            }
        }
    }
    
    auto scene = Director::getInstance()->getRunningScene();
    if (scene && sceneGraphPriorityListeners)
    {
        if (!shouldStopPropagation)
        {
            // priority == 0, scene graph priority
            
            // first, get all enabled, unPaused and registered listeners
            std::vector<EventListener*> sceneListeners;
            for (auto& l : *sceneGraphPriorityListeners)
            {
                if (l->isEnabled() && !l->isPaused() && l->isRegistered())
                {
                    sceneListeners.push_back(l);
                }
            }
            // second, for all camera call all listeners
            // get a copy of cameras, prevent it's been modified in listener callback
            // if camera's depth is greater, process it earlier
            auto cameras = scene->getCameras();
            for (auto rit = cameras.rbegin(), ritRend = cameras.rend(); rit != ritRend; ++rit)
            {
                Camera* camera = *rit;
                if (camera->isVisible() == false)
                {
                    continue;
                }
                
                Camera::_visitingCamera = camera;
                auto cameraFlag = (unsigned short)camera->getCameraFlag();
                for (auto& l : sceneListeners)
                {
                    if (nullptr == l->getAssociatedNode() || 0 == (l->getAssociatedNode()->getCameraMask() & cameraFlag))
                    {
                        continue;
                    }
                    if (onEvent(l))
                    {
                        shouldStopPropagation = true;
                        break;
                    }
                }
                if (shouldStopPropagation)
                {
                    break;
                }
            }
            Camera::_visitingCamera = nullptr;
        }
    }
    
    if (fixedPriorityListeners)
    {
        if (!shouldStopPropagation)
        {
            // priority > 0
            ssize_t size = fixedPriorityListeners->size();
            for (; i < size; ++i)
            {
                auto l = fixedPriorityListeners->at(i);
                
                if (l->isEnabled() && !l->isPaused() && l->isRegistered() && onEvent(l))
                {
                    shouldStopPropagation = true;
                    break;
                }
            }
        }
    }
}

TJ_PROFILE_TASK_DEF(__dispatchEvent);
void EventDispatcher::dispatchEvent(Event* event)
{
    if (!_isEnabled)
        return;

	// spine will reset batch buffer by EventCustom(EVENT_AFTER_DRAW)
	// its use for special EventCustom, it will be memory explode and fps down when the EventCustom be disable
	// so we only want to disable input events in game
	// by huangwei 19/11/29
	if (!_isInputEnabled && (event->getType() != Event::Type::CUSTOM))
		return;
    
	// defer it in kinds of path
	// reduce no related kind to call
	// by huangwei 2019/06/21
	//updateDirtyFlagForSceneGraph();
    
	TJ_PROFILE_DOMAIN_TASK_BEGIN(__EventDispatcher, __dispatchEvent);

    DispatchGuard guard(_inDispatch);
    
	auto director = Director::getInstance();
    if (event->getType() == Event::Type::TOUCH)
    {
		//::Timer t("dispatchEvent by TOUCH");

		updateDirtyFlagForSceneGraph();

        dispatchTouchEvent(static_cast<EventTouch*>(event));

		director->setDirtyDraw();
		TJ_PROFILE_DOMAIN_TASK_END(__EventDispatcher);
        return;
    }
    
    auto listenerID = __getListenerID(event);
    
    auto pfnDispatchEventToListeners = &EventDispatcher::dispatchEventToListeners;
    if (event->getType() == Event::Type::MOUSE) {
        pfnDispatchEventToListeners = &EventDispatcher::dispatchTouchEventToListeners;
    }
    auto iter = _listenerMap.find(listenerID);
    if (iter != _listenerMap.end())
    {
		EventListenerVector* listeners = iter->second;
		auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
		// no sceneGraph listeners mean no necessary to call updateDirtyFlagForSceneGraph
		if (sceneGraphPriorityListeners && !sceneGraphPriorityListeners->empty())
			updateDirtyFlagForSceneGraph();

		sortEventListeners(listenerID);
        
        auto onEvent = [&event](EventListener* listener) -> bool{
            event->setCurrentTarget(listener->getAssociatedNode());
            listener->_onEvent(event);
            return event->isStopped();
        };
        
        (this->*pfnDispatchEventToListeners)(listeners, onEvent);

		// spine listen to after_draw in each frame
// 		if (!listeners->empty())
// 			director->setDirtyDraw();
    }
    
    //updateListeners(event);

	TJ_PROFILE_DOMAIN_TASK_END(__EventDispatcher);
}

void EventDispatcher::dispatchCustomEvent(const std::string &eventName, void *optionalUserData)
{
    EventCustom ev(eventName);
    ev.setUserData(optionalUserData);
    dispatchEvent(&ev);
}

bool EventDispatcher::hasEventListener(const EventListener::ListenerID& listenerID) const
{
    return getListeners(listenerID) != nullptr;
}

void EventDispatcher::dispatchTouchEvent(EventTouch* event)
{
    sortEventListeners(EventListenerTouchOneByOne::LISTENER_ID);
    sortEventListeners(EventListenerTouchAllAtOnce::LISTENER_ID);
    
    auto oneByOneListeners = getListeners(EventListenerTouchOneByOne::LISTENER_ID);
    auto allAtOnceListeners = getListeners(EventListenerTouchAllAtOnce::LISTENER_ID);
    
    // If there aren't any touch listeners, return directly.
    if (nullptr == oneByOneListeners && nullptr == allAtOnceListeners)
        return;
    
    bool isNeedsMutableSet = (oneByOneListeners && allAtOnceListeners);
    
    const std::vector<Touch*>& originalTouches = event->getTouches();
    std::vector<Touch*> mutableTouches(originalTouches.size());
    std::copy(originalTouches.begin(), originalTouches.end(), mutableTouches.begin());

    //
    // process the target handlers 1st
    //
    if (oneByOneListeners)
    {
        auto mutableTouchesIter = mutableTouches.begin();
        
        for (auto& touches : originalTouches)
        {
            bool isSwallowed = false;

            auto onTouchEvent = [&](EventListener* l) -> bool { // Return true to break
                EventListenerTouchOneByOne* listener = static_cast<EventListenerTouchOneByOne*>(l);
                
                // Skip if the listener was removed.
                if (!listener->_isRegistered)
                    return false;
             
                event->setCurrentTarget(listener->_node);
                
                bool isClaimed = false;
                std::vector<Touch*>::iterator removedIter;
                
                EventTouch::EventCode eventCode = event->getEventCode();
                
                if (eventCode == EventTouch::EventCode::BEGAN)
                {
                    if (listener->onTouchBegan)
                    {
                        isClaimed = listener->onTouchBegan(touches, event);
                        if (isClaimed && listener->_isRegistered)
                        {
                            listener->_claimedTouches.push_back(touches);
                        }
                    }
                }
                else if (!listener->_claimedTouches.empty()
                         && ((removedIter = std::find(listener->_claimedTouches.begin(), listener->_claimedTouches.end(), touches)) != listener->_claimedTouches.end()))
                {
                    isClaimed = true;
                    
                    switch (eventCode)
                    {
                        case EventTouch::EventCode::MOVED:
                            if (listener->onTouchMoved)
                            {
                                listener->onTouchMoved(touches, event);
                            }
                            break;
                        case EventTouch::EventCode::ENDED:
                            if (listener->onTouchEnded)
                            {
                                listener->onTouchEnded(touches, event);
                            }
                            if (listener->_isRegistered)
                            {
                                listener->_claimedTouches.erase(removedIter);
                            }
                            break;
                        case EventTouch::EventCode::CANCELLED:
                            if (listener->onTouchCancelled)
                            {
                                listener->onTouchCancelled(touches, event);
                            }
                            if (listener->_isRegistered)
                            {
                                listener->_claimedTouches.erase(removedIter);
                            }
                            break;
                        default:
                            CCASSERT(false, "The eventcode is invalid.");
                            break;
                    }
                }
                
                // If the event was stopped, return directly.
                if (event->isStopped())
                {
                    updateListeners(event);
                    return true;
                }
                
                CCASSERT(touches->getID() == (*mutableTouchesIter)->getID(),
                         "touches ID should be equal to mutableTouchesIter's ID.");
                
                if (isClaimed && listener->_isRegistered && listener->_needSwallow)
                {
                    if (isNeedsMutableSet)
                    {
                        mutableTouchesIter = mutableTouches.erase(mutableTouchesIter);
                        isSwallowed = true;
                    }
                    return true;
                }
                
                return false;
            };
            
            //
            dispatchTouchEventToListeners(oneByOneListeners, onTouchEvent);
            if (event->isStopped())
            {
                return;
            }
            
            if (!isSwallowed)
                ++mutableTouchesIter;
        }
    }
    
    //
    // process standard handlers 2nd
    //
    if (allAtOnceListeners && !mutableTouches.empty())
    {
        
        auto onTouchesEvent = [&](EventListener* l) -> bool{
            EventListenerTouchAllAtOnce* listener = static_cast<EventListenerTouchAllAtOnce*>(l);
            // Skip if the listener was removed.
            if (!listener->_isRegistered)
                return false;
            
            event->setCurrentTarget(listener->_node);
            
            switch (event->getEventCode())
            {
                case EventTouch::EventCode::BEGAN:
                    if (listener->onTouchesBegan)
                    {
                        listener->onTouchesBegan(mutableTouches, event);
                    }
                    break;
                case EventTouch::EventCode::MOVED:
                    if (listener->onTouchesMoved)
                    {
                        listener->onTouchesMoved(mutableTouches, event);
                    }
                    break;
                case EventTouch::EventCode::ENDED:
                    if (listener->onTouchesEnded)
                    {
                        listener->onTouchesEnded(mutableTouches, event);
                    }
                    break;
                case EventTouch::EventCode::CANCELLED:
                    if (listener->onTouchesCancelled)
                    {
                        listener->onTouchesCancelled(mutableTouches, event);
                    }
                    break;
                default:
                    CCASSERT(false, "The eventcode is invalid.");
                    break;
            }
            
            // If the event was stopped, return directly.
            if (event->isStopped())
            {
                updateListeners(event);
                return true;
            }
            
            return false;
        };
        
        dispatchTouchEventToListeners(allAtOnceListeners, onTouchesEvent);
        if (event->isStopped())
        {
            return;
        }
    }
    
    //updateListeners(event);
}
void EventDispatcher::updateListeners()
{
	CCASSERT(_inDispatch == 1, "If program goes here, there should be in dispatch.");

	if (_inDispatch > 1)
		return;

	if (!_toAddedListeners.empty())
	{
		for (auto& listener : _toAddedListeners)
		{
			// may be in _toRemovedListeners
			if (!listener->isRegistered())
			{
				releaseListener(listener);
				continue;
			}
			forceAddEventListener(listener);
		}
		_toAddedListeners.clear();
	}

	if (!_toRemovedListeners.empty())
	{
		cleanToRemovedListeners();

		for (auto iter = _listenerMap.begin(); iter != _listenerMap.end();)
		{
			if (iter->second->empty())
			{
				_priorityDirtyFlagMap.erase(iter->first);
				delete iter->second;
				iter = _listenerMap.erase(iter);
			}
			else
			{
				++iter;
			}
		}
	}

}

void EventDispatcher::updateListeners(Event* event)
{
    CCASSERT(_inDispatch > 0, "If program goes here, there should be event in dispatch.");

    if (_inDispatch > 1)
        return;

	// do nothing
	return;

//     auto onUpdateListeners = [this](const EventListener::ListenerID& listenerID)
//     {
//         auto listenersIter = _listenerMap.find(listenerID);
//         if (listenersIter == _listenerMap.end())
//             return;
// 
//         auto listeners = listenersIter->second;
//         
//         auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
//         auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
//         
//         if (sceneGraphPriorityListeners)
//         {
//             for (auto iter = sceneGraphPriorityListeners->begin(); iter != sceneGraphPriorityListeners->end();)
//             {
//                 auto l = *iter;
//                 if (!l->isRegistered())
//                 {
//                     iter = sceneGraphPriorityListeners->erase(iter);
//                     // if item in toRemove list, remove it from the list
//                     auto matchIter = std::find(_toRemovedListeners.begin(), _toRemovedListeners.end(), l);
//                     if (matchIter != _toRemovedListeners.end())
//                         _toRemovedListeners.erase(matchIter);
//                     releaseListener(l);
//                 }
//                 else
//                 {
//                     ++iter;
//                 }
//             }
//         }
//         
//         if (fixedPriorityListeners)
//         {
//             for (auto iter = fixedPriorityListeners->begin(); iter != fixedPriorityListeners->end();)
//             {
//                 auto l = *iter;
//                 if (!l->isRegistered())
//                 {
//                     iter = fixedPriorityListeners->erase(iter);
//                     // if item in toRemove list, remove it from the list
//                     auto matchIter = std::find(_toRemovedListeners.begin(), _toRemovedListeners.end(), l);
//                     if (matchIter != _toRemovedListeners.end())
//                         _toRemovedListeners.erase(matchIter);
//                     releaseListener(l);
//                 }
//                 else
//                 {
//                     ++iter;
//                 }
//             }
//         }
//         
//         if (sceneGraphPriorityListeners && sceneGraphPriorityListeners->empty())
//         {
//             listeners->clearSceneGraphListeners();
//         }
// 
//         if (fixedPriorityListeners && fixedPriorityListeners->empty())
//         {
//             listeners->clearFixedListeners();
//         }
//     };
// 
//     if (event->getType() == Event::Type::TOUCH)
//     {
//         onUpdateListeners(EventListenerTouchOneByOne::LISTENER_ID);
//         onUpdateListeners(EventListenerTouchAllAtOnce::LISTENER_ID);
//     }
//     else
//     {
//         onUpdateListeners(__getListenerID(event));
//     }
//     
//     CCASSERT(_inDispatch == 1, "_inDispatch should be 1 here.");
//     
//     for (auto iter = _listenerMap.begin(); iter != _listenerMap.end();)
//     {
//         if (iter->second->empty())
//         {
//             _priorityDirtyFlagMap.erase(iter->first);
//             delete iter->second;
//             iter = _listenerMap.erase(iter);
//         }
//         else
//         {
//             ++iter;
//         }
//     }
//     
//     if (!_toAddedListeners.empty())
//     {
//         for (auto& listener : _toAddedListeners)
//         {
//             forceAddEventListener(listener);
//         }
//         _toAddedListeners.clear();
//     }
// 
//     if (!_toRemovedListeners.empty())
//     {
//         cleanToRemovedListeners();
//     }
}

static EventListener::ListenerID prevListenerID;

void EventDispatcher::updateDirtyFlagForSceneGraph()
{
    if (!_dirtyNodes.empty())
    {
		prevListenerID.clear();
        for (auto& node : _dirtyNodes)
        {
            auto iter = _nodeListenersMap.find(node);
            if (iter != _nodeListenersMap.end())
            {
                for (auto& l : *iter->second)
                {
					const EventListener::ListenerID& id = l->getListenerID();
					// ListenerID only had 8 types and 2 types used frequently
					// reduce std::unordered_map.find
					if (id == prevListenerID)
						continue;
					prevListenerID = id;
					setDirty(id, DirtyFlag::SCENE_GRAPH_PRIORITY);
                }
            }
        }
        
        _dirtyNodes.clear();
    }
}

void EventDispatcher::sortEventListeners(const EventListener::ListenerID& listenerID)
{
    DirtyFlag dirtyFlag = DirtyFlag::NONE;
    
    auto dirtyIter = _priorityDirtyFlagMap.find(listenerID);
    if (dirtyIter != _priorityDirtyFlagMap.end())
    {
        dirtyFlag = dirtyIter->second;
    }
    
    if (dirtyFlag != DirtyFlag::NONE)
    {
        // Clear the dirty flag first, if `rootNode` is nullptr, then set its dirty flag of scene graph priority
        dirtyIter->second = DirtyFlag::NONE;

        if ((int)dirtyFlag & (int)DirtyFlag::FIXED_PRIORITY)
        {
            sortEventListenersOfFixedPriority(listenerID);
        }
        
        if ((int)dirtyFlag & (int)DirtyFlag::SCENE_GRAPH_PRIORITY)
        {
            auto rootNode = Director::getInstance()->getRunningScene();
            if (rootNode)
            {
                sortEventListenersOfSceneGraphPriority(listenerID, rootNode);
            }
            else
            {
                dirtyIter->second = DirtyFlag::SCENE_GRAPH_PRIORITY;
            }
        }
    }
}

void EventDispatcher::sortEventListenersOfSceneGraphPriority(const EventListener::ListenerID& listenerID, Node* rootNode)
{
    auto listeners = getListeners(listenerID);
    if (listeners == nullptr)
        return;
    auto sceneGraphListeners = listeners->getSceneGraphPriorityListeners();
    if (sceneGraphListeners == nullptr)
        return;

	// Reset priority index
	_nodePriorityIndex = 0;
	_nodePriorityMap.clear();

	_globalZOrderNodeMap.clear();

	// reverse visit, from leaf to root, reduce the time of tree's travel
	// use node userdata to mark, speed up hash find
	// by huangwei 2019/6/20
	for (const auto l : *sceneGraphListeners)
	{
		Node* node = l->getAssociatedNode();
		if (node)
			node->setUserData((void*)DirtyVisitFlag::LISTENER);
		while (node)
		{
			Node* parent = node->getParent();
			if (parent)
			{
				long data = (long)parent->getUserData();
				parent->setUserData((void*)(data | DirtyVisitFlag::PATH));
			}
			node = parent;
		}
	}

	tjVisitFromRoot(rootNode);

    // After sort: priority < 0, > 0
    std::stable_sort(sceneGraphListeners->begin(), sceneGraphListeners->end(), [this](const EventListener* l1, const EventListener* l2) {
        //return _nodePriorityMap[l1->getAssociatedNode()] > _nodePriorityMap[l2->getAssociatedNode()];
		Node* node1 = l1->getAssociatedNode();
		Node* node2 = l2->getAssociatedNode();
		return (long)(node1 ? node1->getUserData() : 0) > (long)(node2 ? node2->getUserData() : 0);
    });

#if DUMP_LISTENER_ITEM_PRIORITY_INFO
	log("-----------------------------------");
	for (auto& l : *sceneGraphListeners)
	{
		log("listener priority: node ([%s]%p), priority (%d)", typeid(*l->_node).name(), l->_node, (long)l->_node->getUserData());
	}
#endif

	// _globalZOrderNodeMap != sceneGraphListeners
	// may be leave some nodes with DirtyVisitFlag in here, carefully!
	for (auto& nodes : _globalZOrderNodeMap)
	{
		for (Node* n : nodes.second)
		{
			n->setUserData(0);
		}
	}

	_globalZOrderNodeMap.clear();
}

void EventDispatcher::sortEventListenersOfFixedPriority(const EventListener::ListenerID& listenerID)
{
    auto listeners = getListeners(listenerID);

    if (listeners == nullptr)
        return;
    
    auto fixedListeners = listeners->getFixedPriorityListeners();
    if (fixedListeners == nullptr)
        return;
    
    // After sort: priority < 0, > 0
    std::stable_sort(fixedListeners->begin(), fixedListeners->end(), [](const EventListener* l1, const EventListener* l2) {
        return l1->getFixedPriority() < l2->getFixedPriority();
    });
    
    // FIXME: Should use binary search
    int index = 0;
    for (auto& listener : *fixedListeners)
    {
        if (listener->getFixedPriority() >= 0)
            break;
        ++index;
    }
    
    listeners->setGt0Index(index);
    
#if DUMP_LISTENER_ITEM_PRIORITY_INFO
    log("-----------------------------------");
    for (auto& l : *fixedListeners)
    {
        log("listener priority: node (%p), fixed (%d)", l->_node, l->_fixedPriority);
    }    
#endif
    
}

EventDispatcher::EventListenerVector* EventDispatcher::getListeners(const EventListener::ListenerID& listenerID) const
{
    auto iter = _listenerMap.find(listenerID);
    if (iter != _listenerMap.end())
    {
        return iter->second;
    }
    
    return nullptr;
}

void EventDispatcher::removeEventListenersForListenerID(const EventListener::ListenerID& listenerID)
{
    auto listenerItemIter = _listenerMap.find(listenerID);
    if (listenerItemIter != _listenerMap.end())
    {
        auto listeners = listenerItemIter->second;
        auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
        auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();
        
        auto removeAllListenersInVector = [&](std::vector<EventListener*>* listenerVector){
            if (listenerVector == nullptr)
                return;
            
            for (auto iter = listenerVector->begin(); iter != listenerVector->end();)
            {
                auto l = *iter;
                l->setRegistered(false);
                if (l->getAssociatedNode() != nullptr)
                {
                    dissociateNodeAndEventListener(l->getAssociatedNode(), l);
                    l->setAssociatedNode(nullptr);  // nullptr out the node pointer so we don't have any dangling pointers to destroyed nodes.
                }
                
                if (_inDispatch == 0)
                {
                    iter = listenerVector->erase(iter);
                    releaseListener(l);
                }
                else
                {
                    ++iter;
                }
            }
        };
        
        removeAllListenersInVector(sceneGraphPriorityListeners);
        removeAllListenersInVector(fixedPriorityListeners);
        
        // Remove the dirty flag according the 'listenerID'.
        // No need to check whether the dispatcher is dispatching event.
        _priorityDirtyFlagMap.erase(listenerID);
        
        if (!_inDispatch)
        {
            listeners->clear();
            delete listeners;
            _listenerMap.erase(listenerItemIter);
        }
    }
    
    for (auto iter = _toAddedListeners.begin(); iter != _toAddedListeners.end();)
    {
        if ((*iter)->getListenerID() == listenerID)
        {
            (*iter)->setRegistered(false);
            releaseListener(*iter);
            iter = _toAddedListeners.erase(iter);
        }
        else
        {
            ++iter;
        }
    }
}

void EventDispatcher::removeEventListenersForType(EventListener::Type listenerType)
{
    if (listenerType == EventListener::Type::TOUCH_ONE_BY_ONE)
    {
        removeEventListenersForListenerID(EventListenerTouchOneByOne::LISTENER_ID);
    }
    else if (listenerType == EventListener::Type::TOUCH_ALL_AT_ONCE)
    {
        removeEventListenersForListenerID(EventListenerTouchAllAtOnce::LISTENER_ID);
    }
    else if (listenerType == EventListener::Type::MOUSE)
    {
        removeEventListenersForListenerID(EventListenerMouse::LISTENER_ID);
    }
    else if (listenerType == EventListener::Type::ACCELERATION)
    {
        removeEventListenersForListenerID(EventListenerAcceleration::LISTENER_ID);
    }
    else if (listenerType == EventListener::Type::KEYBOARD)
    {
        removeEventListenersForListenerID(EventListenerKeyboard::LISTENER_ID);
    }
    else
    {
        CCASSERT(false, "Invalid listener type!");
    }
}

void EventDispatcher::removeCustomEventListeners(const std::string& customEventName)
{
    removeEventListenersForListenerID(customEventName);
}

void EventDispatcher::removeAllEventListeners()
{
    bool cleanMap = true;
    std::vector<EventListener::ListenerID> types;
    types.reserve(_listenerMap.size());
    
    for (const auto& e : _listenerMap)
    {
        if (_internalCustomListenerIDs.find(e.first) != _internalCustomListenerIDs.end())
        {
            cleanMap = false;
        }
        else
        {
            types.push_back(e.first);
        }
    }

    for (const auto& type : types)
    {
        removeEventListenersForListenerID(type);
    }
    
    if (!_inDispatch && cleanMap)
    {
        _listenerMap.clear();
    }
}

void EventDispatcher::setEnabled(bool isEnabled)
{
    _isEnabled = isEnabled;
	_isInputEnabled = isEnabled;
}

bool EventDispatcher::isEnabled() const
{
    return _isEnabled;
}

void EventDispatcher::setInputEnabled(bool isEnabled)
{
	_isInputEnabled = isEnabled;
}

bool EventDispatcher::isInputEnabled() const
{
	return _isInputEnabled;
}

void EventDispatcher::setDirtyForNode(Node* node)
{
	Director::getInstance()->setDirtyDraw();
	// clean node userdata for tjVisitFromRoot by huangwei 2019/12/24
	node->setUserData(0);

    // Mark the node dirty only when there is an eventlistener associated with it. 
    if (_nodeListenersMap.find(node) != _nodeListenersMap.end())
    {
        _dirtyNodes.insert(node);
    }

    // Also set the dirty flag for node's children
    const auto& children = node->getChildren();
    for (const auto& child : children)
    {
        setDirtyForNode(child);
    }
}

void EventDispatcher::setDirty(const EventListener::ListenerID& listenerID, DirtyFlag flag)
{    
    auto iter = _priorityDirtyFlagMap.find(listenerID);
    if (iter == _priorityDirtyFlagMap.end())
    {
        _priorityDirtyFlagMap.emplace(listenerID, flag);
    }
    else
    {
        int ret = (int)flag | (int)iter->second;
        iter->second = (DirtyFlag) ret;
    }
}

void EventDispatcher::cleanToRemovedListeners()
{
	std::unordered_map<EventListener::ListenerID, EventListenerVector*> _cleanMap;
	std::vector<EventListener*> _cleanVec;
	// make new to replace old
	for (auto& l : _toRemovedListeners)
	{
		auto listenersIter = _listenerMap.find(l->getListenerID());
		if (listenersIter == _listenerMap.end())
			continue;

		auto listeners = listenersIter->second;
		auto fixedPriorityListeners = listeners->getFixedPriorityListeners();
		auto sceneGraphPriorityListeners = listeners->getSceneGraphPriorityListeners();

		if (sceneGraphPriorityListeners)
		{
			_cleanVec.clear();
			_cleanVec.reserve(sceneGraphPriorityListeners->size());
			for (auto l : *sceneGraphPriorityListeners)
			{
				if (l->isRegistered())
					_cleanVec.push_back(l);
				else
				{
					CCASSERT(l->getAssociatedNode() == nullptr, "unregistered listener had associated node");
					releaseListener(l);
				}
			}
			if (_cleanVec.empty())
				listeners->clearSceneGraphListeners();
			else
				sceneGraphPriorityListeners->swap(_cleanVec);
		}

		if (fixedPriorityListeners)
		{
			_cleanVec.clear();
			_cleanVec.reserve(fixedPriorityListeners->size());
			for (auto l : *fixedPriorityListeners)
			{
				if (l->isRegistered())
					_cleanVec.push_back(l);
				else
				{
					CCASSERT(l->getAssociatedNode() == nullptr, "unregistered listener had associated node");
					releaseListener(l);
				}
			}
			if (_cleanVec.empty())
				listeners->clearFixedListeners();
			else
				fixedPriorityListeners->swap(_cleanVec);
		}

		if (listeners->empty())
			delete listeners;
		else
			_cleanMap[listenersIter->first] = listeners;
		// clean each ListenerID vector once
		_listenerMap.erase(listenersIter);
	}
	for (auto listenersIter : _cleanMap)
		_listenerMap[listenersIter.first] = listenersIter.second;

    for (auto& l : _toRemovedListeners)
		releaseListener(l);
    _toRemovedListeners.clear();
}

void EventDispatcher::releaseListener(EventListener* listener)
{
#if CC_ENABLE_GC_FOR_NATIVE_OBJECTS
    auto sEngine = ScriptEngineManager::getInstance()->getScriptEngine();
    if (listener && sEngine)
    {
        sEngine->releaseScriptObject(this, listener);
    }
#endif // CC_ENABLE_GC_FOR_NATIVE_OBJECTS
    CC_SAFE_RELEASE(listener);
}

NS_CC_END
