
#ifndef TJ_THREADPOOL_H
#define TJ_THREADPOOL_H


#include "confuse.h"
#include "cocos2d.h"

#include <thread>
#include <queue>
#include <mutex>
#include <vector>

class CC_DLL TJThreadPool {
public:
	typedef std::function<void()> TaskFunc;

	virtual ~TJThreadPool();

	void enqueue(TaskFunc task);
	int waitAll();

	static TJThreadPool* getInstance() {
		if (instance == nullptr) {
			instance = new TJThreadPool();
		}
		return instance;
	}

	static void destroyInstance() {
		delete instance;
		instance = nullptr;
	}

protected:
	static TJThreadPool* instance;

	TJThreadPool();

	std::vector<std::thread> _threads;

	// the task queue
	std::queue<TaskFunc> _tasks;
	std::atomic_int _unfinished;

	// synchronization
	std::mutex _queueMutex;
	std::condition_variable _condition;
	bool _stop;
};


#endif//TJ_THREADPOOL_H
