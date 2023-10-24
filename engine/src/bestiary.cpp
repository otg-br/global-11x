/**
* Credits: Holy-Tibia Team
* Bytes: Charles
*/

#include "otpch.h"
#include "bestiary.h"
#include "pugicast.h"

extern Monsters g_monsters;

bool Bestiaries::loadFromXml(bool /* reloading */) {
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/bestiary.xml");
	if (!result) {
		printXMLError("Error - Bestiaries::loadFromXml", "data/XML/bestiary.xml", result);
		return  false;
	 }

	for (auto bestiaryNode : doc.child("bestiary").children()) {
		pugi::xml_attribute attr;
		if (strcasecmp(bestiaryNode.name(), "difficulty") == 0) {
			pugi::xml_attribute id = bestiaryNode.attribute("id");
			if (!id) {
				std::cout << "[Warning - Bestiaries::loadFromXml] Missing id for difficulty entry" << std::endl;
				continue;
			}

			if (!(attr = bestiaryNode.attribute("type"))) {
				std::cout << "[Warning - Bestiary::loadFromXml] Missing Bestiary type." << std::endl;
				continue;
			}

			uint16_t type = pugi::cast<uint16_t>(attr.value());
			if (type > 2) {
				std::cout << "[Warning - Bestiary::loadFromXml] Invalid Bestiary type " << type << " id " << id.value() << "." << std::endl;
				continue;
			}

			difficulties.emplace_back(
				pugi::cast<uint16_t>(id.value()),
				pugi::cast<uint16_t>(bestiaryNode.attribute("charm").value()),
				pugi::cast<uint16_t>(bestiaryNode.attribute("first").value()),
				pugi::cast<uint16_t>(bestiaryNode.attribute("second").value()),
				pugi::cast<uint16_t>(bestiaryNode.attribute("final").value()),
				type == 1
			);

			difficulties.shrink_to_fit();

		} else if (strcasecmp(bestiaryNode.name(), "category") == 0) {
			++runningid;
			pugi::xml_attribute nameBase = bestiaryNode.attribute("name");
			if (!nameBase) {
				std::cout << "[Warning - Bestiary::loadFromXml] Missing Bestiary category name" << std::endl;
				continue;
			}
			
			auto res = bestiary.emplace(std::piecewise_construct,
				std::forward_as_tuple(runningid),
				std::forward_as_tuple(runningid, nameBase.as_string())
			);

			if (!res.second) {
				std::cout << "[Warning - Bestiary::loadFromXml] Duplicate Bestiary of ID: '" << runningid << "' and name '" << nameBase.as_string() << "'." << std::endl;
				continue;
			}

			Bestiary& best = res.first->second;

			for (auto raceNode : bestiaryNode.children()) {
				pugi::xml_attribute id = raceNode.attribute("id");
				if (!id) {
					std::cout << "[Warning - Bestiaries::loadFromXml] Missing id for difficulty entry" << std::endl;
					continue;
				}

				uint16_t raceid = pugi::cast<uint16_t>(id.value());

				pugi::xml_attribute locationBase = raceNode.attribute("location");
				std::string location = "";
				if (locationBase) {
					location = locationBase.as_string();
				}

				pugi::xml_attribute namexmlbase = raceNode.attribute("name");
				if (namexmlbase) {
					std::string namelower = asLowerCaseString(namexmlbase.as_string());
					monstersNameMap[namelower] = raceid;
				} else {
					// nao tem problema iniciar o server sem setar o raceid
					std::cout << "[Warning - Bestiaries::loadFromXml] Missing name for race (" << raceid << ") Category: " << nameBase.as_string() << std::endl;
				}

				best.races.emplace_back(
					raceid,
					location,
					static_cast<uint8_t>(pugi::cast<uint16_t>(raceNode.attribute("ocorrence").value())),
					static_cast<uint8_t>(pugi::cast<uint16_t>(raceNode.attribute("difficulty").value())),
					pugi::cast<uint16_t>(raceNode.attribute("ocorrence").value()) >= 4
				);
			}
		}

	}

	return true;
}

bool Bestiaries::reload() {
	runningid = 0;
	difficulties.clear();
	bestiary.clear();
	monstersNameMap.clear();

	return loadFromXml(true);
}

Difficulty* Bestiaries::getDifficulty(uint16_t id, bool rare)
{
	for (auto& it : difficulties) {
		if (it.id == id && it.rare == rare) {
			return &it;
		}
	}

	return nullptr;

}

RaceEntry* Bestiary::getRaceByID(uint16_t id)
{
	auto it = std::find_if(races.begin(), races.end(), [id](const RaceEntry& cat_imb) {
				return cat_imb.id == id;
			});

	return it != races.end() ? &*it : nullptr;
}

MonsterType* Bestiary::getMonsterByRace(uint16_t id)
{
	MonsterType* monsterType = g_monsters.getMonsterTypeByRace(id);
	if (!monsterType) {
		return nullptr;
	}

	return monsterType;
}

Bestiary* Bestiaries::getBestiaryByRaceID(uint16_t id)
{
	for (auto& it : bestiary) {
		if (it.second.getRaceByID(id)) {
			return &it.second;
		}
	}

	return nullptr;
}

Bestiary* Bestiaries::getBestiaryByName(std::string& name)
{
	for (auto& it : bestiary) {
		if (strcasecmp(it.second.getName().c_str(), name.c_str()) == 0) {
			return &it.second;
		}
	}

	return nullptr;
}
