
#include "base/TJThreadPool.h"


TJThreadPool* TJThreadPool::instance = nullptr;

TJThreadPool::TJThreadPool()
{
	int count = 4;
	unsigned int n = std::thread::hardware_concurrency();
	count = MAX(4, count > n ? n : count);
	CCLOG("hardware_concurrency %d thread_pool_count %d", n, count);


	_stop = false;
	_unfinished = 0;
	for (int i = 0; i < count; i++) {
		_threads.push_back(std::thread([this] {
			TJ_PROFILE_THREAD_DEF(__TJThreadPool);
			while (true) {
				TaskFunc task;
				{
					std::unique_lock<std::mutex> lock(this->_queueMutex);
					this->_condition.wait(lock, [this] { return !this->_tasks.empty() || this->_stop; });
					if (this->_stop)
						return;

					task = std::move(this->_tasks.front());
					this->_tasks.pop();
				}

				task();
				
				// keep safe to avoid "Lost wakeup"
				{
					std::unique_lock<std::mutex> lock(this->_queueMutex);
					this->_unfinished--;
				}
				this->_condition.notify_all();
			}
		}));
	}
}


TJThreadPool::~TJThreadPool()
{
	{
		std::unique_lock<std::mutex> lock(_queueMutex);
		_stop = true;

		while (_tasks.size())
			_tasks.pop();
	}

	_unfinished = 0;
	_condition.notify_all();
	for (int i = 0; i < _threads.size(); i++) {
		_threads[i].join();
	}
}

void TJThreadPool::enqueue(TaskFunc task) 
{
	std::unique_lock<std::mutex> lock(_queueMutex);
	if (_stop)
		return;

	_unfinished++;
	_tasks.push(std::move(task));
	_condition.notify_one();
}

int TJThreadPool::waitAll() 
{
	int ret = _unfinished;
	if (ret == 0) {
		return 0;
	}

	std::unique_lock<std::mutex> lock(_queueMutex);
	_condition.wait(lock, [this, ret] { return this->_unfinished <= 0 || this->_stop; });
	_unfinished = 0;
	return ret;
}
