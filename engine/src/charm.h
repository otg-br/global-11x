/**
* Credits: Holy-Tibia Team
*/


#ifndef FS_CHARM_H
#define FS_CHARM_H

#include "player.h"
#include "enums.h"

class Charm;

class Charms {
	public:
		bool loadFromXml(bool reloading = false);
		bool reload();

		Charm* getCharm(uint8_t id);
		std::map<uint8_t, Charm> charms;

	protected:
		friend class Charm;

};

class Charm
{
	public:
		Charm(uint8_t id) : 
				id(id) {}

		uint8_t getId() const {
			return id;
		}
		uint8_t getType() const {
			return type;
		}
		uint16_t getPrice() const {
			return price;
		}
		std::string getName() {
			return name;
		}
		std::string getDescription() {
			return description;
		}

	protected:
		friend class Charms;

	private:
		uint16_t price = 0;
		uint8_t type, id = 0;
		std::string name, description = "";
};

#endif
