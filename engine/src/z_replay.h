#ifndef __Z_REPLAY__
#define __Z_REPLAY__

#include "protocolgame.h"

using PacketQueue = std::queue<std::pair<time_t, NetworkMessage>>;
struct ZReplayData {
	bool recording = false;

	std::string title;
	// Por default da para logar no 12 -- Vou colocar para poder logar no 10 ou no 12 (se o replay foi feito no 10, so da para assistir no 10, se for feito no 12, so da para assistir no 12)
	uint16_t version = 1220;

	PacketQueue packets;
};

static constexpr uint8_t Z_MAX_REPLAYS = 5;
using ReplayList = std::vector<ZReplayData>;
class ZReplays
{
	public:
		const ReplayList& getReplays() { return replayList; }
		void saveReplay(ZReplayData& replay);

	private:
		ReplayList replayList;
};
#endif
