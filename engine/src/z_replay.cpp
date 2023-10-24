#include "otpch.h"
#include "player.h"
#include "z_replay.h"
#include "databasetasks.h"

// https://gist.github.com/Lyuzera/62bd5e635cb1d0fade73acc7cfa063b4
void ZReplays::saveReplay(ZReplayData& replay)
{
	replay.recording = false;
	replay.title = formatDate(time(0));

	ZReplayData copy = replay;

	// salvando para logar no client 12
	
	std::ostringstream query;
	query << "INSERT into `z_replay` (`title`, `version`) VALUES (" << g_database.escapeString(replay.title) << ", " << replay.version << ");";
	g_databaseTasks.addTask(query.str());

	// clear player replay structure to be able to record again.
	replay.title.clear();
	PacketQueue().swap(replay.packets);

	replayList.push_back(std::move(copy));
}
