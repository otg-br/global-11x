/*
 *
 */

#ifndef FS_PROTOCOLCODES_H
#define FS_PROTOCOLCODES_H

enum GameOpcode_t : uint8_t {

};

enum ServerOpcode_t : uint8_t {
	ServerLogout = 0x14,
	ServerReceivePingBack = 0x1D,
};


#endif
