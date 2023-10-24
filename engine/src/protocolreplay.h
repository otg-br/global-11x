#ifndef __PROTOCOLREPLAY__
#define __PROTOCOLREPLAY__

#include "protocol.h"
#include "z_replay.h"

class ProtocolReplay;
using ProtocolReplay_ptr = std::shared_ptr<ProtocolReplay>;

class ProtocolReplay final : public Protocol
{
	public:
		enum {server_sends_first = true};
		enum {protocol_identifier = 0};
		enum {use_checksum = true};
		static const char* protocol_name() {
			return "replay protocol";
		}

		explicit ProtocolReplay(Connection_ptr connection) : Protocol(connection) {}

	private:
		ProtocolReplay_ptr getThis() {
			return std::static_pointer_cast<ProtocolReplay>(shared_from_this());
		}

		void writeToOutputBuffer(const NetworkMessage& msg);
		void release() override;
		void releaseEvent();

		void disconnectClient(const std::string& message) const;

		void parsePacket(NetworkMessage& msg) override;
		void onRecvFirstMessage(NetworkMessage& msg) override;
		void onConnect() override;

		void watchRecording(const std::string& replayName);
		void playRecording();

		PacketQueue data;
		uint32_t eventId = 0;

		uint32_t challengeTimestamp = 0;
		uint8_t challengeRandom = 0;
};
#endif