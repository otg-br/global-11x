/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019 Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "otpch.h"

#include "tasks.h"
#include "game.h"

extern Game g_game;
extern Stats g_stats;

Task* createTaskWithStats(std::function<void (void)> f, const std::string& description, const std::string& extraDescription)
{
	return new Task(std::move(f), description, extraDescription);
}

Task* createTaskWithStats(uint32_t expiration, std::function<void (void)> f, const std::string& description, const std::string& extraDescription)
{
	return new Task(expiration, std::move(f), description, extraDescription);
}

void Dispatcher::threadMain()
{
	// NOTE: second argument defer_lock is to prevent from immediate locking
	std::unique_lock<std::mutex> taskLockUnique(taskLock, std::defer_lock);

#ifdef STATS_ENABLED
	std::chrono::high_resolution_clock::time_point time_point;
#endif

	while (getState() != THREAD_STATE_TERMINATED) {
		// check if there are tasks waiting
		taskLockUnique.lock();

		if (taskList.empty()) {
			//if the list is empty wait for signal
#ifdef STATS_ENABLED
			time_point = std::chrono::high_resolution_clock::now();
			taskSignal.wait(taskLockUnique);
			g_stats.dispatcherWaitTime(dispatcherId) += std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::high_resolution_clock::now() - time_point).count();
#else
			taskSignal.wait(taskLockUnique);
#endif
		}

		if (!taskList.empty()) {
			// take the first task
			Task* task = taskList.front();
			taskList.pop_front();
			taskLockUnique.unlock();

			if (!task->hasExpired()) {
				++dispatcherCycle;
				// execute it
#ifdef STATS_ENABLED
				time_point = std::chrono::high_resolution_clock::now();
#endif
				(*task)();
#ifdef STATS_ENABLED
				task->executionTime = std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::high_resolution_clock::now() - time_point).count();
				g_stats.addDispatcherTask(dispatcherId, task);
#else
				delete task;
#endif
			} else {
#ifdef STATS_ENABLED
				delete task;
#else
				delete task;
#endif
			}
		} else {
			taskLockUnique.unlock();
		}
	}
}

void Dispatcher::addTask(Task* task, bool push_front /*= false*/)
{
	bool do_signal = false;

	taskLock.lock();

	if (getState() == THREAD_STATE_RUNNING) {
		do_signal = taskList.empty();

		if (push_front) {
			taskList.push_front(task);
		} else {
			taskList.push_back(task);
		}
	} else {
		delete task;
	}

	taskLock.unlock();

	// send a signal if the list was empty
	if (do_signal) {
		taskSignal.notify_one();
	}
}

void Dispatcher::shutdown()
{
	Task* task = createTaskWithStats([this]() {
		setState(THREAD_STATE_TERMINATED);
		taskSignal.notify_one();
	}, "Dispatcher::shutdown", "Terminating dispatcher");

	std::lock_guard<std::mutex> lockClass(taskLock);
	taskList.push_back(task);

	taskSignal.notify_one();
}
