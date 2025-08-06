/*
* Feito por Lucas Prazeres
* Equipe Holy-Tibia
*/

#include "otpch.h"
#include "store.h"
#include "pugicast.h"
#include "game.h"
#include "configmanager.h"

extern Game g_game;
extern ConfigManager g_config;

const std::unordered_map<std::string, CoinType_t> CoinTypeMap = {
	{"coin", COIN_TYPE_DEFAULT},
	{"transferable", COIN_TYPE_TRANSFERABLE},
	{"tournament", COIN_TYPE_TOURNAMENT}
};
const std::unordered_map<std::string, OfferStates_t> OfferStatesMap = {
	{"none", OFFER_STATE_NONE},
	{"new", OFFER_STATE_NEW},
	{"sale", OFFER_STATE_SALE},
	{"timed", OFFER_STATE_TIMED}
};
const std::unordered_map<std::string, OfferTypes_t> OfferTypesMap = {
	{"none", OFFER_TYPE_NONE},
	{"item", OFFER_TYPE_ITEM},
	{"stackeable", OFFER_TYPE_STACKABLE},
	{"outfit", OFFER_TYPE_OUTFIT},
	{"outfit addon", OFFER_TYPE_OUTFIT_ADDON},
	{"mount", OFFER_TYPE_MOUNT},
	{"namechange", OFFER_TYPE_NAMECHANGE},
	{"sexchange", OFFER_TYPE_SEXCHANGE},
	{"promotion", OFFER_TYPE_PROMOTION},
	{"house", OFFER_TYPE_HOUSE},
	{"expboost", OFFER_TYPE_EXPBOOST},
	{"preyslot", OFFER_TYPE_PREYSLOT},
	{"preybonus", OFFER_TYPE_PREYBONUS},
	{"temple", OFFER_TYPE_TEMPLE},
	{"blessing", OFFER_TYPE_BLESSINGS},
	{"premium", OFFER_TYPE_PREMIUM},
	{"pouch", OFFER_TYPE_POUCH},
	{"allblessing", OFFER_TYPE_ALLBLESSINGS},
	{"reward", OFFER_TYPE_INSTANT_REWARD_ACCESS},
	{"training", OFFER_TYPE_TRAINING},
	{"charmexpansion", OFFER_TYPE_CHARM_EXPANSION},
	{"charmpoints", OFFER_TYPE_CHARM_POINTS},
	{"multiitems", OFFER_TYPE_MULTI_ITEMS},
	{"blessrune", OFFER_TYPE_BLESS_RUNE},
	{"vip", OFFER_TYPE_VIP},
	{"fragremove", OFFER_TYPE_FRAG_REMOVE},
	{"skullremove", OFFER_TYPE_SKULL_REMOVE},
	{"recoverykey", OFFER_TYPE_RECOVERYKEY},
};

const std::unordered_map<std::string, OfferBuyTypes_t> OfferBuyTypesMap = {
	{"none", OFFER_BUY_TYPE_OTHERS},
	{"offername", OFFER_BUY_TYPE_NAMECHANGE},
	{"teste", OFFER_BUY_TYPE_TESTE}
};

const std::unordered_map<std::string, Skulls_t> OfferSkullMap = {
	{"none", SKULL_NONE},
	{"red", SKULL_RED},
	{"black", SKULL_BLACK}
};


bool Store::isValidType(OfferTypes_t type)
{
	auto it = std::find_if(OfferTypesMap.begin(), OfferTypesMap.end(), [type](std::pair<std::string, OfferTypes_t> const& pair) {
		return pair.second == type;
	});

	return it != OfferTypesMap.end();
}

bool Store::loadFromXml(bool /* reloading */) {
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_file("data/XML/store.xml");
	if (!result) {
		printXMLError("Error - Store::loadFromXml", "data/XML/store.xml", result);
		return  false;
	 }

	loaded = true;
	for (auto baseNode : doc.child("store").children()) {
		pugi::xml_attribute attr;
		// StoreCategory
		if (strcasecmp(baseNode.name(), "category") == 0) {
			pugi::xml_attribute name = baseNode.attribute("name");
			if (!name) {
				std::cout << "[Warning - Store::loadFromXml] Missing name for Category entry" << std::endl;
				continue;
			}

			std::vector<std::string> offersName;
			for (auto childNode : baseNode.children()) {
				if (strcasecmp(childNode.name(), "subcategory") == 0) {
					offersName.push_back( childNode.attribute("name").as_string() );
				}
			}

			categories.emplace_back(
				name.value(),
				offersName,
				baseNode.attribute("icon").as_string(),
				baseNode.attribute("rookgaard").as_bool(true)
			);

			offercount++;

			categories.shrink_to_fit();
		// Home
		} else if (strcasecmp(baseNode.name(), "home") == 0) {
			for (auto childNode : baseNode.children()) {
				if (strcasecmp(childNode.name(), "offer") == 0) {
					home.offers.push_back( childNode.attribute("name").as_string() );
				} else if (strcasecmp(childNode.name(), "banner") == 0) {
					home.banners.push_back( childNode.attribute("image").as_string() );
				}
			}

		// Offers
		} else if (strcasecmp(baseNode.name(), "offers") == 0) {
			pugi::xml_attribute attributeName = baseNode.attribute("name");
			if (!attributeName) {
				std::cout << "[Warning - Store::loadFromXml] Missing name for Offers entry" << std::endl;
				continue;
			}

			// make StoreOffers
			std::string name = attributeName.value();

			auto res = storeOffers.emplace(std::piecewise_construct,
					std::forward_as_tuple(name),
					std::forward_as_tuple(name)
				);

			if (!res.second) {
				std::cout << "[Warning - Store::loadFromXml] Duplicate Category Offer by name: '" << name << "' [ignored]" << std::endl;
				continue;
			}

			offercount++;

			// editando StoreOffers na memoria
			StoreOffers& offers = res.first->second;
			// reaproveitando variavel
			attributeName = baseNode.attribute("description");
			if (attributeName) {
				offers.description = attributeName.value();	
			}

			attributeName = baseNode.attribute("icon");
			if (attributeName) {
				offers.icon = attributeName.value();	
			}

			attributeName = baseNode.attribute("rookgaard");
			if (attributeName) {
				offers.rookgaard = attributeName.as_bool();
			}

			attributeName = baseNode.attribute("state");
			if (attributeName) {
				auto parseState = OfferStatesMap.find(attributeName.value());
				if (parseState != OfferStatesMap.end()) {
					offers.state = parseState->second;
				}
			}

			if (offers.state == OFFER_STATE_SALE) {
				saleoffer = true;
			} else if (offers.state == OFFER_STATE_NEW) {
				newoffer = true;
			}

			attributeName = baseNode.attribute("parent");
			if (attributeName) {
				offers.parent = attributeName.value();
			}

			// pegando as ofertas
			for (auto childNode : baseNode.children()) {
				if (strcasecmp(childNode.name(), "offer") == 0) {
					if (!(attr = childNode.attribute("name"))) {
						std::cout << "[Warning - Store::loadFromXml] Missing key attribute in Store::StoreOffers::StoreOffer name" << std::endl;
						continue;
					}

					name = attr.value();
					uint32_t id = 0;
					pugi::xml_attribute childNodeName = childNode.attribute("id");
					if (childNodeName) {
						id = pugi::cast<uint32_t>(childNodeName.value());
					} else {
						runningid++;
						id = runningid;
					}

					auto resultOffer = offers.offers.emplace(std::piecewise_construct,
						std::forward_as_tuple(id),
						std::forward_as_tuple(id, name ));

					if (!resultOffer.second) {
						std::cout << "[Warning - Store::loadFromXml] Duplicate Store Offer by name: '" << attr.value() << "'" << std::endl;
						continue;
					}

					StoreOffer& offer = resultOffer.first->second;
					childNodeName = childNode.attribute("price");
					if (!childNodeName) {
						std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need price" << std::endl;
						continue;
					}
					offer.price = pugi::cast<uint32_t>(childNodeName.value());

					childNodeName = childNode.attribute("count");
					if (childNodeName) {
						offer.count = pugi::cast<uint16_t>(childNodeName.value());
					}

					childNodeName = childNode.attribute("icon");
					if (childNodeName) {
						offer.icon =  childNodeName.value();
					}

					childNodeName = childNode.attribute("description");
					if (childNodeName) {
						offer.description =  childNodeName.value();
					}

					childNodeName = childNode.attribute("description12");
					if (childNodeName) {
						offer.description12 =  childNodeName.value();
						replaceString(offer.description12, "<li>", "&#8226;");
					}

					childNodeName = childNode.attribute("type");
					if (childNodeName) {
						auto parseType = OfferTypesMap.find(childNodeName.value());
						if (parseType != OfferTypesMap.end()) {
							offer.type = parseType->second;
						}
					}


					childNodeName = childNode.attribute("disabled");
					if (childNodeName) {
						offer.disabled = childNodeName.as_bool();
					}

					if (offer.type == OFFER_TYPE_BLESS_RUNE && !g_config.getBoolean(ConfigManager::BLESS_RUNE)) {
						offer.disabled = true;
					}

					if (offer.type == OFFER_TYPE_OUTFIT || offer.type == OFFER_TYPE_OUTFIT_ADDON) {
						childNodeName = childNode.attribute("female");
						if (!childNodeName) {
							std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need female outfit" << std::endl;
							continue;
						}
						offer.female = pugi::cast<uint16_t>(childNodeName.value());
						childNodeName = childNode.attribute("male");
						if (!childNodeName) {
							std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need male outfit" << std::endl;
							continue;
						}
						offer.male = pugi::cast<uint16_t>(childNodeName.value());

						childNodeName = childNode.attribute("addon");
						if (!childNodeName) {
							offer.addon = 0;
						} else {
							offer.addon = pugi::cast<uint16_t>(childNodeName.value());
						}
					} else if (offer.type == OFFER_TYPE_BLESSINGS) {
						childNodeName = childNode.attribute("blessid");
						if (!childNodeName) {
							std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need bless id" << std::endl;
							continue;
						}
						offer.blessid = pugi::cast<uint16_t>(childNodeName.value());
					} else if (offer.type == OFFER_TYPE_ITEM || offer.type == OFFER_TYPE_STACKABLE ||
							 offer.type == OFFER_TYPE_HOUSE || offer.type == OFFER_TYPE_TRAINING ||
							 offer.type == OFFER_TYPE_POUCH) {

						childNodeName = childNode.attribute("itemtype");
						if (!childNodeName) {
							std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need itemtype" << std::endl;
							continue;
						}
						offer.itemtype = pugi::cast<uint16_t>(childNodeName.value());

						childNodeName = childNode.attribute("charges");
						if (childNodeName) {
							offer.charges = pugi::cast<uint16_t>(childNodeName.value());
						}

						childNodeName = childNode.attribute("actionid");
						if (childNodeName) {
							offer.actionid = pugi::cast<uint16_t>(childNodeName.value());
						}

						if (offer.count == 0) {
							offer.count = 1;
						}
					} else if (offer.type == OFFER_TYPE_MULTI_ITEMS) {
						childNodeName = childNode.attribute("items");
						if (!childNodeName) {
							std::cout << "[Warning - Store::loadFromXml] Store Offer by name: '" << offer.name << "' need items" << std::endl;
							continue;
						}

						StringVector itemsList = explodeString(childNodeName.value(), ";");
						for (const std::string& itemsInfo : itemsList) {
							StringVector info = explodeString(itemsInfo, ",");
							if (info.size() == 2) {
								uint16_t itemid = std::stoi(info[0]);
								uint16_t item_count = std::stoi(info[1]);
								offer.itemList[itemid] = item_count;
							}
						}

					} else if (offer.type == OFFER_TYPE_SKULL_REMOVE) {
						childNodeName = childNode.attribute("skull");
						if (childNodeName) {
							auto parseSkull = OfferSkullMap.find(childNodeName.value());
							if (parseSkull != OfferSkullMap.end()) {
								offer.skull = parseSkull->second;
							}
						}
					}

					childNodeName = childNode.attribute("state");
					if (childNodeName) {
						auto parseState = OfferStatesMap.find(childNodeName.value());
						if (parseState != OfferStatesMap.end()) {
							offer.state = parseState->second;
						}
					}

					if (offer.state == OFFER_STATE_SALE) {
						saleoffer = true;
						childNodeName = childNode.attribute("validUntil");
						if (childNodeName) {
							offer.validUntil = pugi::cast<uint32_t>(childNodeName.value());
						}
						childNodeName = childNode.attribute("basePrice");
						if (childNodeName) {
							offer.basePrice = pugi::cast<uint32_t>(childNodeName.value());
						}
					} else if (offer.state == OFFER_STATE_NEW) {
						newoffer = true;
					}

					childNodeName = childNode.attribute("coinType");
					if (childNodeName) {
						auto parseCoin = CoinTypeMap.find(childNodeName.value());
						if (parseCoin != CoinTypeMap.end()) {
							offer.coinType = parseCoin->second;
						}
					}

					childNodeName = childNode.attribute("buyType");
					if (childNodeName) {
						auto parsebtpe = OfferBuyTypesMap.find(childNodeName.value());
						if (parsebtpe != OfferBuyTypesMap.end()) {
							offer.buyType = parsebtpe->second;
						}
					}

					offer.rookgaard = offers.rookgaard;
					childNodeName = childNode.attribute("rookgaard");
					if (childNodeName) {
						offer.rookgaard = childNodeName.as_bool();
					}
				}
			}
		}
	}

	return true;
}

bool Store::reload() {
	categories.clear();
	storeOffers.clear();
	home.offers.clear();
	home.banners.clear();
	runningid = beginid;
	loaded = false;
	offercount = 0;

	newoffer = false;
	saleoffer = false;

	return loadFromXml(true);
}

std::vector<StoreOffers*> Store::getStoreOffers()
{
	std::vector<StoreOffers*> filter;
	for (auto& info : storeOffers) {
		StoreOffers* offers = &info.second;
		filter.push_back(offers);
	}

	return filter;
}

std::vector<StoreOffer*> Store::getStoreOffer(StoreOffers* offers)
{
	std::vector<StoreOffer*> filter;
	for (auto& info : offers->offers) {
		StoreOffer* offer = offers->getOfferByID(info.first);
		if (offer) {
			filter.push_back(offer);				
		}
	}
	return filter;
}

StoreOffer* Store::getStoreOfferByName(std::string name)
{
	for (auto& info : storeOffers) {
		StoreOffers* offers = &info.second;
		for (auto& info2 : offers->offers) {
			StoreOffer* offer = offers->getOfferByID(info2.first);
			if (offer && strcasecmp(offer->getName().c_str(), name.c_str()) == 0) {
				return offer;
			}
		}
	}
	return nullptr;
}

std::vector<StoreOffer*> Store::getHomeOffers()
{
	std::vector<StoreOffer*> filter;

	for (auto off = home.offers.begin(), end = home.offers.end(); off != end; ++off) {
		StoreOffer* oferta = getStoreOfferByName((*off));
		if (oferta) {
			bool hasDec = false;
			for (auto off2 = filter.begin(), end2 = filter.end(); off2 != end2; ++off2) {
				if ((*off2)->getName() == oferta->getName()){
					hasDec = true;
					break;
				}
			}

			if (!hasDec) {
				filter.emplace_back(oferta);
			}
		}
	}

	return filter;
}


std::map<std::string, std::vector<StoreOffer*>> Store::getHomeOffersOrganized()
{
	std::map<std::string, std::vector<StoreOffer*>> filter;
	for (auto off = home.offers.begin(), end = home.offers.end(); off != end; ++off) {
		StoreOffer* oferta = getStoreOfferByName((*off));
		if (oferta) {
			std::string name = oferta->getName();
			filter[name].emplace_back(oferta);
		}
	}


	return filter;
}

std::map<std::string, std::vector<StoreOffer*>> Store::getStoreOrganizedByName(StoreOffers* offers)
{
	std::map<std::string, std::vector<StoreOffer*>> filter;
	for (auto& info : offers->offers) {
		StoreOffer* offer = offers->getOfferByID(info.first);
		if (offer) {
			std::string name = offer->getName();
			filter[name].emplace_back(offer);				
		}
	}


	return filter;
}

StoreOffer* StoreOffers::getOfferByID(uint32_t id)
{
	auto it = offers.find(id);
	if (it == offers.end()) {
		return nullptr;
	}

	return &it->second;
}

std::string StoreOffer::getDisabledReason(Player* player)
{

	uint16_t outfitLookType = player->getSex() == PLAYERSEX_FEMALE ? female : male;

	std::string disabledReason;
	if (disabled) {
		disabledReason = "This offer is disabled.";
	} else if (type == OFFER_TYPE_POUCH) {
 			Item* item = g_game.findItemOfType(player, 26377, true, -1);
 			if (item)
 				disabledReason = "You already have Loot Pouch.";
 	} else if (type == OFFER_TYPE_BLESSINGS) {
 				if (player->hasBlessing(blessid))
 					disabledReason = "You already have this Bless.";
	} else if (type == OFFER_TYPE_ALLBLESSINGS) {
		uint8_t count = 0;
		uint8_t limitBless = 0;
		uint8_t minBless = (g_game.getWorldType() == WORLD_TYPE_RETRO_OPEN_PVP ? BLESS_PVE_FIRST : BLESS_FIRST);
		uint8_t maxBless = BLESS_LAST;
		for (int i = minBless; i <= maxBless; ++i) {
			limitBless++;
			if (player->hasBlessing(i)) {
				count++;
			}
		}

		if (count >= limitBless)
			disabledReason = "You already have all Blessings.";

	} else if (type == OFFER_TYPE_OUTFIT && player->canWear(outfitLookType, addon)) {
		disabledReason = "You already have this outfit.";
	} else if (type == OFFER_TYPE_OUTFIT_ADDON) {
		if (player->canWear(outfitLookType, 0)) {
			if (player->canWear(outfitLookType, addon)) {
				disabledReason = "You already have this addon.";
			}
		}
	} else if (type == OFFER_TYPE_MOUNT) {
		Mount* mount = g_game.mounts.getMountByID(id);
		if (!mount) {
			disabledReason = "Mount not found";
		} else if (player->hasMount(mount)) {
			disabledReason = "You already have this mount.";
		}

	} else if (type == OFFER_TYPE_PROMOTION) {
		disabledReason = "This offer has disabled.";
	} else if (type == OFFER_TYPE_PREYSLOT) {
		if (player->isUnlockedPrey(2)) {
			disabledReason = "You already have 3 slots released.";
		}

	} else if (type == OFFER_TYPE_EXPBOOST) {
		int32_t value1;
		player->getStorageValue(51052, value1);
		int32_t value2;
		player->getStorageValue(51053, value2);
		if (value1 >= 6) {
			disabledReason = "Can be purchased up to 5 times between 2 server saves.";
		} else if ((OS_TIME(nullptr) - value2) < (1*60*60)) {
			disabledReason = "You still have active boost.";
		}
	} else if (type == OFFER_TYPE_CHARM_EXPANSION) {
		if (player->hasCharmExpansion()) {
			disabledReason = "You have charm expansion";
		}
	} else if (type == OFFER_TYPE_BLESS_RUNE) {
		int32_t value1;
		player->getStorageValue(PSTRG_BLESS_RUNA, value1);
		if (value1 > OS_TIME(nullptr)) {
			disabledReason = "Your blessing is active.";
		}
	} else if (type == OFFER_TYPE_SKULL_REMOVE) {
		if (player->getSkull() != skull) {
			disabledReason = "This offer is disabled for you"; 
		}
	} else if (type == OFFER_TYPE_FRAG_REMOVE) {
		if (player->unjustifiedKills.empty()) {
			disabledReason = "You have no frag to remove."; 
		}
	} else if (type == OFFER_TYPE_RECOVERYKEY) {
		int32_t value;
		player->getAccountStorageValue(1, value);
		if (value > OS_TIME(nullptr)) {
			disabledReason = "You recently generated an RK."; 
		}
	}

	if (player->getVocation()->getId() == 0 && !rookgaard) {
		disabledReason = "This offer is deactivated."; 
	}

	if (player->getCoinBalance(coinType) - getPrice(player) < 0) {
		if (coinType == COIN_TYPE_TOURNAMENT) {
			disabledReason = "You don't have tournament coins.";
		} else {
			disabledReason = "You don't have coins.";
		}
	}

	return disabledReason;
}

Mount* StoreOffer::getMount()
{
	return g_game.mounts.getMountByID(id);
}

uint8_t Store::convertType(OfferTypes_t type)
{
	uint8_t offertype = 0;
	if (type == OFFER_TYPE_POUCH || type == OFFER_TYPE_ITEM || type == OFFER_TYPE_STACKABLE ||  type == OFFER_TYPE_HOUSE || type == OFFER_TYPE_TRAINING) {
 		offertype = 3;
	} else if (type == OFFER_TYPE_OUTFIT || type == OFFER_TYPE_OUTFIT_ADDON) {
		offertype = 2;
	} else if (type == OFFER_TYPE_MOUNT) {
		offertype = 1;
	}

	return offertype;
}

StoreOffers* Store::getOfferByName(std::string name)
{
	// checa primeiro as categorias
	for (auto offer = categories.begin(), end = categories.end(); offer != end; ++offer) {
		if (strcasecmp((*offer).name.c_str(), name.c_str()) == 0) {
			return getOfferByName((*offer).subcategory[0]);
		}
	}

	// pula para ofertas
	auto it = storeOffers.find(name);
	if (it == storeOffers.end()) {
		// Clicando no banner tbm chama uma oferta
		// std::cout << "[Warning - Store::getOfferByName] Offer " << name << " not found" << std::endl;
		return nullptr;
	}
	return &it->second;
}

StoreOffers* Store::getOffersByOfferId(uint32_t id)
{
	for (auto& info : storeOffers) {
		StoreOffers* offers = &info.second;
		if (offers == nullptr){
			continue;
		}

		StoreOffer* offer = offers->getOfferByID(id);
		if (offer != nullptr && offer->getId() == id) {
			return offers;
		}
	}

	return nullptr;
}

StoreOffer* Store::getOfferById(uint32_t id)
{
	for (auto& info : storeOffers) {
		StoreOffers* offers = &info.second;
		if (offers == nullptr){
			continue;
		}

		StoreOffer* offer = offers->getOfferByID(id);
		if (offer != nullptr && offer->getId() == id) {
			return offer;
		}
	}

	return nullptr;
}

uint32_t StoreOffer::getPrice(Player* player)
{
	uint32_t newPrice = 0;
	if (player && type == OFFER_TYPE_EXPBOOST) {
		int32_t value1;
		player->getStorageValue(51052, value1);
		uint32_t xpBoostPrice = getExpBoostPrice(value1);
		if (xpBoostPrice > 0) {
			if (player->isVip()) {
				xpBoostPrice *= 0.90;
			}

		}
		
		return xpBoostPrice;
	}

	if (state == OFFER_STATE_SALE) {
		time_t mytime;
		mytime = time(NULL);
		struct tm tm = *localtime(&mytime);
		int32_t daySub = validUntil - tm.tm_mday;
		if (daySub < 0) {
			newPrice = basePrice;
		}
	}

	uint32_t p_prince = price;
	if (player && player->isVip()) {
		newPrice *= 0.90;
		p_prince *= 0.90;
	}

	return newPrice > 0 ? newPrice : p_prince;
}

uint16_t StoreOffer::getCount(bool inBuy)
{
	if (!inBuy && type == OFFER_TYPE_PREMIUM) {
		return 1;
	}

	return count;
}

std::string StoreOffer::getDescription(Player* player /*= nullptr */)
{
	if (!player) {
		return description;
	}

	uint16_t version = player->getProtocolVersion();
	std::string showDesc = version < 1200 ? description : description12;
	if (showDesc.empty() && version >= 1200 ) {
		showDesc = description;
	}

	if ((type == OFFER_TYPE_ITEM || type == OFFER_TYPE_STACKABLE) && showDesc.empty()) {
		Item* virtualItem = Item::CreateItem(itemtype, count);
		if (virtualItem) {
			showDesc = "You see " + virtualItem->getDescription(version < 1200 ? -1 : -2);
			delete virtualItem;
		}
	}

	return showDesc;
}