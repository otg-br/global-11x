#include "otpch.h"

#include "protocolreplay.h"
#include "outputmessage.h"

#include "configmanager.h"
#include "game.h"
#include "ban.h"
#include "scheduler.h"

extern ConfigManager g_config;
extern Game g_game;
extern ZReplays g_replays;

void ProtocolReplay::release()
{
	OutputMessagePool::getInstance().removeProtocolFromAutosend(shared_from_this());
	Protocol::release();
}

void ProtocolReplay::onRecvFirstMessage(NetworkMessage& msg)
{
	if (g_game.getGameState() == GAME_STATE_SHUTDOWN) {
		disconnect();
		return;
	}

	OperatingSystem_t operatingSystem = static_cast<OperatingSystem_t>(msg.get<uint16_t>());
	uint16_t version = msg.get<uint16_t>();
	if (version >= 1220) {
		enableCompact();
	} else {
		disconnectClient("Only client 12.20 is allowed!");
		return;
	}

	msg.skipBytes(7); // U32 client version, U8 client type, U16 dat revision

	if (!Protocol::RSA_decrypt(msg)) {
		disconnect();
		return;
	}

	uint32_t key[4];
	key[0] = msg.get<uint32_t>();
	key[1] = msg.get<uint32_t>();
	key[2] = msg.get<uint32_t>();
	key[3] = msg.get<uint32_t>();
	enableXTEAEncryption();
	setXTEAKey(key);

	if (operatingSystem >= CLIENTOS_OTCLIENT_LINUX) {
		disconnect();
		return;
	}

	msg.skipBytes(1); // gamemaster flag

	std::string sessionKey = msg.getString();
	std::string characterName = msg.getString();

	uint32_t timeStamp = msg.get<uint32_t>();
	uint8_t randNumber = msg.getByte();
	if (challengeTimestamp != timeStamp || challengeRandom != randNumber) {
		disconnect();
		return;
	}

	g_scheduler.addEvent(createSchedulerTask(0, std::bind(&ProtocolReplay::watchRecording, getThis(), characterName)));
}

void ProtocolReplay::onConnect()
{
	auto output = OutputMessagePool::getOutputMessage();
	static std::random_device rd;
	static std::ranlux24 generator(rd());
	static std::uniform_int_distribution<uint16_t> randNumber(0x00, 0xFF);

	// Skip checksum
	output->skipBytes(sizeof(uint32_t));

	// Packet length & type
	output->add<uint16_t>(0x0006);
	output->addByte(0x1F);

	// Add timestamp & random number
	challengeTimestamp = static_cast<uint32_t>(OS_TIME(nullptr));
	output->add<uint32_t>(challengeTimestamp);

	challengeRandom = randNumber(generator);
	output->addByte(challengeRandom);

	// Go back and write checksum
	output->skipBytes(-12);
	// To support 11.10-, not have problems with 11.11+
	output->add<uint32_t>(adlerChecksum(output->getOutputBuffer() + sizeof(uint32_t), 8));

	send(std::move(output));

	send(output);
}

void ProtocolReplay::disconnectClient(const std::string& message) const
{
	auto output = OutputMessagePool::getOutputMessage();
	output->addByte(0x14);
	output->addString(message);
	send(output);
	disconnect();

}
void ProtocolReplay::writeToOutputBuffer(const NetworkMessage& msg)
{
	auto out = getOutputBuffer(msg.getLength());
	out->append(msg);
}

void ProtocolReplay::watchRecording(const std::string& replayName)
{
	for (const auto& replay : g_replays.getReplays()) {
		if (replay.title == replayName) {
			data = replay.packets;
			break;
		}
	}

	if (data.empty()) {
		disconnectClient("This replay doesn't exists.");
		return;
	}

	playRecording();
	OutputMessagePool::getInstance().addProtocolToAutosend(shared_from_this());
}

void ProtocolReplay::playRecording()
{
	if (data.empty()) {
		releaseEvent();
		return;
	}
	
	const NetworkMessage& msg = data.front().second;
	time_t interval = data.front().first;
	data.pop();

	if (data.empty()) {
		releaseEvent();
		return;
	}

	interval = data.front().first - interval;
	eventId = g_scheduler.addEvent(createSchedulerTask(interval, std::bind(&ProtocolReplay::playRecording, getThis())));
	writeToOutputBuffer(msg);
}

void ProtocolReplay::parsePacket(NetworkMessage& msg)
{
	if (msg.getLength() <= 0) {
		return;
	}

	uint8_t recvbyte = msg.getByte();
	switch (recvbyte) {
	case 0x14: releaseEvent(); break;

	default:
		NetworkMessage msg;
		msg.addByte(0xB5);
		msg.addByte(2);
		writeToOutputBuffer(msg);
	}

	if (msg.isOverrun()) {
		disconnect();
	}
}

void ProtocolReplay::releaseEvent()
{
	if (eventId) {
		g_scheduler.stopEvent(eventId);
		eventId = 0;
	}
	disconnect();
}