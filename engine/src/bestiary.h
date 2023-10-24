/**
* Credits: Holy-Tibia Team
* Bytes: Charles
*/


#ifndef FS_BESTIARY_H
#define FS_BESTIARY_H

#include "player.h"
#include "enums.h"
#include "tools.h"
#include "monsters.h"

class Bestiary;
class Monsters;

struct RaceEntry
{
	RaceEntry(uint16_t id, std::string location, uint8_t ocorrence, uint8_t difficulty, bool rare) :
		id(id), location(std::move(location)), ocorrence(ocorrence), difficulty(difficulty), rare(rare) {}

	uint16_t id;
	std::string location;
	uint8_t ocorrence, difficulty;
	bool rare;
};

struct Difficulty
{
	Difficulty(uint16_t id, uint16_t charm, uint16_t first, uint16_t second, uint16_t final, bool rare) :
		id(id), charm(charm), first(first), second(second), final(final), rare(rare) {}

	uint16_t id, charm, first, second, final;
	bool rare;

};

class Bestiaries {
	public:
		bool loadFromXml(bool reloading = false);
		bool reload();

		Difficulty* getDifficulty(uint16_t id, bool rare = false);
		Bestiary* getBestiaryByRaceID(uint16_t id);
		Bestiary* getBestiaryByName(std::string& name);

		std::map<uint32_t, Bestiary> bestiary;
		std::map<std::string, uint16_t>& getMonsterNameMap() {
			return monstersNameMap;
		}
	protected:
		friend class Bestiary;
		friend class Monsters;

	private:
		uint32_t runningid = 0;
		std::vector<Difficulty> difficulties;
		std::map<std::string, uint16_t> monstersNameMap;
};

class Bestiary
{
	public:
		Bestiary(uint16_t id, std::string name) : 
				id(id), name(name) {}

		uint16_t getId() const {
			return id;
		}
		std::string getName() {
			return name;
		}

		const std::vector<RaceEntry>& getRaces() const {
			return races;
		}

		RaceEntry* getRaceByID(uint16_t id);
		MonsterType* getMonsterByRace(uint16_t id);
	protected:
		friend class Bestiaries;

	private:
		uint16_t id = 0;
		std::string name = "";
		std::vector<RaceEntry> races;
};


#endif
