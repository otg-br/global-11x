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

#include "item.h"
#include "container.h"
#include "teleport.h"
#include "trashholder.h"
#include "mailbox.h"
#include "house.h"
#include "game.h"
#include "bed.h"
#include "rewardchest.h"
#include "imbuements.h"

#include "actions.h"
#include "spells.h"

extern Game g_game;
extern Spells* g_spells;
extern Vocations g_vocations;
extern Imbuements g_imbuements;

Items Item::items;

Item* Item::CreateItem(const uint16_t type, uint16_t count /*= 0*/)
{
	Item* newItem = nullptr;

	const ItemType& it = Item::items[type];
	if (it.group == ITEM_GROUP_DEPRECATED) {
		return nullptr;
	}

	if (it.stackable && count == 0) {
		count = 1;
	}

	if (it.id != 0) {
		if (it.isDepot()) {
			newItem = new DepotLocker(type);
		} else if (it.isRewardChest()) {
			newItem = new RewardChest(type);
		} else if (it.isContainer()) {
			newItem = new Container(type);
		} else if (it.isTeleport()) {
			newItem = new Teleport(type);
		} else if (it.isMagicField()) {
			newItem = new MagicField(type);
		} else if (it.isDoor()) {
			newItem = new Door(type);
		} else if (it.isTrashHolder()) {
			newItem = new TrashHolder(type);
		} else if (it.isMailbox()) {
			newItem = new Mailbox(type);
		} else if (it.isBed()) {
			newItem = new BedItem(type);
		} else if (it.id >= 2210 && it.id <= 2212) {
			newItem = new Item(type - 3, count);
		} else if (it.id == 2215 || it.id == 2216) {
			newItem = new Item(type - 2, count);
		} else if (it.id >= 2202 && it.id <= 2206) {
			newItem = new Item(type - 37, count);
		} else if (it.id == 2640) {
			newItem = new Item(6132, count);
		} else if (it.id == 6301) {
			newItem = new Item(6300, count);
		} else if (it.id == 18528) {
			newItem = new Item(18408, count);
		} else {
			newItem = new Item(type, count);
		}

		newItem->incrementReferenceCounter();
	}

	return newItem;
}

uint32_t Item::getImbuement(uint8_t slot) {
	int64_t slotid = IMBUEMENT_SLOT + slot;
	const ItemAttributes::CustomAttribute* attr = getCustomAttribute(slotid);
	if (attr) {
		uint32_t info = static_cast<uint32_t>(boost::get<int64_t>(attr->value));
		if(info << 8)
			return info;
	}

	return 0;
}

void Item::setImbuement(uint8_t slot, int64_t info) {
	int64_t slotid = IMBUEMENT_SLOT + slot;
	std::string key = boost::lexical_cast<std::string>(slotid);
	ItemAttributes::CustomAttribute val;
	val.set<int64_t>(info);
	setCustomAttribute(key, val);
	return;
}

Container* Item::CreateItemAsContainer(const uint16_t type, uint16_t size)
{
	const ItemType& it = Item::items[type];
	if (it.id == 0 || it.group == ITEM_GROUP_DEPRECATED || it.stackable || it.useable || it.moveable || it.pickupable || it.isDepot() || it.isSplash() || it.isDoor()) {
		return nullptr;
	}

	Container* newItem = new Container(type, size);
	newItem->incrementReferenceCounter();
	return newItem;
}

Item* Item::CreateItem(PropStream& propStream)
{
	uint16_t id;
	if (!propStream.read<uint16_t>(id)) {
		return nullptr;
	}

	switch (id) {
		case ITEM_FIREFIELD_PVP_FULL:
			id = ITEM_FIREFIELD_PERSISTENT_FULL;
			break;

		case ITEM_FIREFIELD_PVP_MEDIUM:
			id = ITEM_FIREFIELD_PERSISTENT_MEDIUM;
			break;

		case ITEM_FIREFIELD_PVP_SMALL:
			id = ITEM_FIREFIELD_PERSISTENT_SMALL;
			break;

		case ITEM_ENERGYFIELD_PVP:
			id = ITEM_ENERGYFIELD_PERSISTENT;
			break;

		case ITEM_POISONFIELD_PVP:
			id = ITEM_POISONFIELD_PERSISTENT;
			break;

		case ITEM_MAGICWALL:
			id = ITEM_MAGICWALL_PERSISTENT;
			break;

		case ITEM_WILDGROWTH:
			id = ITEM_WILDGROWTH_PERSISTENT;
			break;

		default:
			break;
	}

	return Item::CreateItem(id, 0);
}

Item::Item(const uint16_t type, uint16_t count /*= 0*/) :
	id(type)
{
	const ItemType& it = items[id];

	if (it.isFluidContainer() || it.isSplash()) {
		setFluidType(count);
	} else if (it.stackable) {
		if (count != 0) {
			setItemCount(count);
		} else if (it.charges != 0) {
			setItemCount(it.charges);
		}
	} else if (it.charges != 0) {
		if (count != 0) {
			setCharges(count);
		} else {
			setCharges(it.charges);
		}
	}

	setDefaultDuration();
}

Item::Item(const Item& i) :
	Thing(), id(i.id), count(i.count), loadedFromMap(i.loadedFromMap)
{
	if (i.attributes) {
		attributes.reset(new ItemAttributes(*i.attributes));
	}
}

Item* Item::clone() const
{
	Item* item = Item::CreateItem(id, count);
	if (attributes) {
		item->attributes.reset(new ItemAttributes(*attributes));
		if (item->getDuration() > 0) {
			item->startDecaying();
		}
	}

	return item;
}

bool Item::equals(const Item* otherItem) const
{
	if (!otherItem || id != otherItem->id) {
		return false;
	}

	const auto& otherAttributes = otherItem->attributes;
	if (!attributes) {
		return !otherAttributes || (otherAttributes->attributeBits == 0);
	} else if (!otherAttributes) {
		return (attributes->attributeBits == 0);
	}

	if (attributes->attributeBits != otherAttributes->attributeBits) {
		return false;
	}

	const auto& attributeList = attributes->attributes;
	const auto& otherAttributeList = otherAttributes->attributes;
	for (const auto& attribute : attributeList) {
		if (ItemAttributes::isStrAttrType(attribute.type)) {
			for (const auto& otherAttribute : otherAttributeList) {
				if (attribute.type == otherAttribute.type && *attribute.value.string != *otherAttribute.value.string) {
					return false;
				}
			}
		} else {
			for (const auto& otherAttribute : otherAttributeList) {
				if (attribute.type == otherAttribute.type && attribute.value.integer != otherAttribute.value.integer) {
					return false;
				}
			}
		}
	}
	return true;
}

void Item::setDefaultSubtype()
{
	const ItemType& it = items[id];

	setItemCount(1);

	if (it.charges != 0) {
		if (it.stackable) {
			setItemCount(it.charges);
		} else {
			setCharges(it.charges);
		}
	}
}

void Item::onRemoved()
{
	ScriptEnvironment::removeTempItem(this);

	if (hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		g_game.removeUniqueItem(getUniqueId());
	}
}

void Item::setID(uint16_t newid)
{
	const ItemType& prevIt = Item::items[id];
	id = newid;

	const ItemType& it = Item::items[newid];
	uint32_t newDuration = it.decayTime * 1000;

	if (newDuration == 0 && !it.stopTime && it.decayTo < 0) {
		removeAttribute(ITEM_ATTRIBUTE_DECAYSTATE);
		removeAttribute(ITEM_ATTRIBUTE_DURATION);
	}

	if (!isRewardCorpse()) {
		removeAttribute(ITEM_ATTRIBUTE_CORPSEOWNER);
	}

	if (newDuration > 0 && (!prevIt.stopTime || !hasAttribute(ITEM_ATTRIBUTE_DURATION))) {
		setDecaying(DECAYING_FALSE);
		setDuration(newDuration);
	}

}

Cylinder* Item::getTopParent()
{
	Cylinder* aux = getParent();
	Cylinder* prevaux = dynamic_cast<Cylinder*>(this);
	if (!aux) {
		return prevaux;
	}

	while (aux->getParent() != nullptr) {
		prevaux = aux;
		aux = aux->getParent();
	}

	if (prevaux) {
		return prevaux;
	}
	return aux;
}

const Cylinder* Item::getTopParent() const
{
	const Cylinder* aux = getParent();
	const Cylinder* prevaux = dynamic_cast<const Cylinder*>(this);
	if (!aux) {
		return prevaux;
	}

	while (aux->getParent() != nullptr) {
		prevaux = aux;
		aux = aux->getParent();
	}

	if (prevaux) {
		return prevaux;
	}
	return aux;
}

Tile* Item::getTile()
{
	Cylinder* cylinder = getTopParent();
	//get root cylinder
	if (cylinder && cylinder->getParent()) {
		cylinder = cylinder->getParent();
	}
	return dynamic_cast<Tile*>(cylinder);
}

const Tile* Item::getTile() const
{
	const Cylinder* cylinder = getTopParent();
	//get root cylinder
	if (cylinder && cylinder->getParent()) {
		cylinder = cylinder->getParent();
	}
	return dynamic_cast<const Tile*>(cylinder);
}

uint16_t Item::getSubType() const
{
	const ItemType& it = items[id];
	if (it.isFluidContainer() || it.isSplash()) {
		return getFluidType();
	} else if (it.stackable) {
		return count;
	} else if (it.charges != 0) {
		return getCharges();
	}
	return count;
}

Player* Item::getHoldingPlayer() const
{
	Cylinder* p = getParent();
	while (p) {
		if (p->getCreature()) {
			return p->getCreature()->getPlayer();
		}

		p = p->getParent();
	}
	return nullptr;
}

void Item::setSubType(uint16_t n)
{
	const ItemType& it = items[id];
	if (it.isFluidContainer() || it.isSplash()) {
		setFluidType(n);
	} else if (it.stackable) {
		setItemCount(n);
	} else if (it.charges != 0) {
		setCharges(n);
	} else {
		setItemCount(n);
	}
}

Attr_ReadValue Item::readAttr(AttrTypes_t attr, PropStream& propStream)
{
	switch (attr) {
		case ATTR_COUNT:
		case ATTR_RUNE_CHARGES: {
			uint8_t count;
			if (!propStream.read<uint8_t>(count)) {
				return ATTR_READ_ERROR;
			}

			setSubType(count);
			break;
		}

		case ATTR_ACTION_ID: {
			uint16_t actionId;
			if (!propStream.read<uint16_t>(actionId)) {
				return ATTR_READ_ERROR;
			}

			setActionId(actionId);
			break;
		}

		case ATTR_UNIQUE_ID: {
			uint16_t uniqueId;
			if (!propStream.read<uint16_t>(uniqueId)) {
				return ATTR_READ_ERROR;
			}

			setUniqueId(uniqueId);
			break;
		}

		case ATTR_TEXT: {
			std::string text;
			if (!propStream.readString(text)) {
				return ATTR_READ_ERROR;
			}

			setText(text);
			break;
		}

		case ATTR_WRITTENDATE: {
			uint32_t writtenDate;
			if (!propStream.read<uint32_t>(writtenDate)) {
				return ATTR_READ_ERROR;
			}

			setDate(writtenDate);
			break;
		}

		case ATTR_WRITTENBY: {
			std::string writer;
			if (!propStream.readString(writer)) {
				return ATTR_READ_ERROR;
			}

			setWriter(writer);
			break;
		}

		case ATTR_DESC: {
			std::string text;
			if (!propStream.readString(text)) {
				return ATTR_READ_ERROR;
			}

			setSpecialDescription(text);
			break;
		}

		case ATTR_CHARGES: {
			uint16_t charges;
			if (!propStream.read<uint16_t>(charges)) {
				return ATTR_READ_ERROR;
			}

			setSubType(charges);
			break;
		}

		case ATTR_DURATION: {
			int32_t duration;
			if (!propStream.read<int32_t>(duration)) {
				return ATTR_READ_ERROR;
			}

			setDuration(std::max<int32_t>(0, duration));
			break;
		}

		case ATTR_DECAYING_STATE: {
			uint8_t state;
			if (!propStream.read<uint8_t>(state)) {
				return ATTR_READ_ERROR;
			}

			if (state != DECAYING_FALSE) {
				setDecaying(DECAYING_PENDING);
			}
			break;
		}

		case ATTR_NAME: {
			std::string name;
			if (!propStream.readString(name)) {
				return ATTR_READ_ERROR;
			}

			setStrAttr(ITEM_ATTRIBUTE_NAME, name);
			break;
		}

		case ATTR_ARTICLE: {
			std::string article;
			if (!propStream.readString(article)) {
				return ATTR_READ_ERROR;
			}

			setStrAttr(ITEM_ATTRIBUTE_ARTICLE, article);
			break;
		}

		case ATTR_PLURALNAME: {
			std::string pluralName;
			if (!propStream.readString(pluralName)) {
				return ATTR_READ_ERROR;
			}

			setStrAttr(ITEM_ATTRIBUTE_PLURALNAME, pluralName);
			break;
		}

		case ATTR_WEIGHT: {
			uint32_t weight;
			if (!propStream.read<uint32_t>(weight)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_WEIGHT, weight);
			break;
		}

		case ATTR_ATTACK: {
			int32_t attack;
			if (!propStream.read<int32_t>(attack)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ATTACK, attack);
			break;
		}

		case ATTR_CLASSIFICATION: {
			uint32_t classification;
			if (!propStream.read<uint32_t>(classification)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_CLASSIFICATION, classification);
			break;
		}

		case ATTR_TIER: {
			uint32_t tier;
			if (!propStream.read<uint32_t>(tier)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_TIER, tier);
			break;
		}

		case ATTR_DEFENSE: {
			int32_t defense;
			if (!propStream.read<int32_t>(defense)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_DEFENSE, defense);
			break;
		}

		case ATTR_EXTRADEFENSE: {
			int32_t extraDefense;
			if (!propStream.read<int32_t>(extraDefense)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_EXTRADEFENSE, extraDefense);
			break;
		}

		case ATTR_IMBUINGSLOTS: {
			break;
		}

		case ATTR_ARMOR: {
			int32_t armor;
			if (!propStream.read<int32_t>(armor)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ARMOR, armor);
			break;
		}

		case ATTR_WRAPID: {
			uint16_t wrapId;
			if (!propStream.read<uint16_t>(wrapId)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_WRAPID, wrapId);
			break;
		}

		case ATTR_HITCHANCE: {
			int8_t hitChance;
			if (!propStream.read<int8_t>(hitChance)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_HITCHANCE, hitChance);
			break;
		}

		case ATTR_SHOOTRANGE: {
			uint8_t shootRange;
			if (!propStream.read<uint8_t>(shootRange)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_SHOOTRANGE, shootRange);
			break;
		}

		case ATTR_SPECIAL: {
			std::string special;
			if (!propStream.readString(special)) {
				return ATTR_READ_ERROR;
			}

			setStrAttr(ITEM_ATTRIBUTE_SPECIAL, special);
			break;
		}

		case ATTR_DECAYTO: {
			int32_t decayTo;
			if (!propStream.read<int32_t>(decayTo)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_DECAYTO, decayTo);
			break;
		}

		case ATTR_QUICKLOOTCONTAINER: {
			uint32_t flags;
			if (!propStream.read<uint32_t>(flags)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER, flags);
			break;
		}

		//these should be handled through derived classes
		//If these are called then something has changed in the items.xml since the map was saved
		//just read the values

		//Depot class
		case ATTR_DEPOT_ID: {
			if (!propStream.skip(2)) {
				return ATTR_READ_ERROR;
			}
			break;
		}

		//Door class
		case ATTR_HOUSEDOORID: {
			if (!propStream.skip(1)) {
				return ATTR_READ_ERROR;
			}
			break;
		}

		//Bed class
		case ATTR_SLEEPERGUID: {
			if (!propStream.skip(4)) {
				return ATTR_READ_ERROR;
			}
			break;
		}

		case ATTR_SLEEPSTART: {
			if (!propStream.skip(4)) {
				return ATTR_READ_ERROR;
			}
			break;
		}

		//Teleport class
		case ATTR_TELE_DEST: {
			if (!propStream.skip(5)) {
				return ATTR_READ_ERROR;
			}
			break;
		}

		//Container class
		case ATTR_CONTAINER_ITEMS: {
			return ATTR_READ_ERROR;
		}

		case ATTR_CUSTOM_ATTRIBUTES: {
			uint64_t size;
			if (!propStream.read<uint64_t>(size)) {
				return ATTR_READ_ERROR;
			}

			for (uint64_t i = 0; i < size; i++) {
				// Unserialize key type and value
				std::string key;
				if (!propStream.readString(key)) {
					return ATTR_READ_ERROR;
				};

				// Unserialize value type and value
				ItemAttributes::CustomAttribute val;
				if (!val.unserialize(propStream)) {
					return ATTR_READ_ERROR;
				}

				setCustomAttribute(key, val);
			}
			break;
		}

		case ATTR_OPENED: {
			uint8_t opened;
			if (!propStream.read<uint8_t>(opened)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_OPENED, opened);
			break;
		}
		case ATTR_IMBUED: {
			uint8_t imbued;
			if (!propStream.read<uint8_t>(imbued)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_IMBUED, imbued);
			break;
		}

		// Dynamic element attributes for upgrade system
		case ATTR_ELEMENTICE: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTICE, elementDamage);
			break;
		}

		case ATTR_ELEMENTEARTH: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTEARTH, elementDamage);
			break;
		}

		case ATTR_ELEMENTFIRE: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTFIRE, elementDamage);
			break;
		}

		case ATTR_ELEMENTENERGY: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTENERGY, elementDamage);
			break;
		}

		case ATTR_ELEMENTDEATH: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTDEATH, elementDamage);
			break;
		}

		case ATTR_ELEMENTHOLY: {
			uint16_t elementDamage;
			if (!propStream.read<uint16_t>(elementDamage)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ELEMENTHOLY, elementDamage);
			break;
		}

		// Dynamic absorb percent attributes for upgrade system
		case ATTR_ABSORBICE: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBICE, absorbPercent);
			break;
		}

		case ATTR_ABSORBEARTH: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBEARTH, absorbPercent);
			break;
		}

		case ATTR_ABSORBFIRE: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBFIRE, absorbPercent);
			break;
		}

		case ATTR_ABSORBENERGY: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBENERGY, absorbPercent);
			break;
		}

		case ATTR_ABSORBDEATH: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBDEATH, absorbPercent);
			break;
		}

		case ATTR_ABSORBHOLY: {
			uint16_t absorbPercent;
			if (!propStream.read<uint16_t>(absorbPercent)) {
				return ATTR_READ_ERROR;
			}

			setIntAttr(ITEM_ATTRIBUTE_ABSORBHOLY, absorbPercent);
			break;
		}

		default:
			return ATTR_READ_ERROR;
	}

	return ATTR_READ_CONTINUE;
}

bool Item::unserializeAttr(PropStream& propStream)
{
	uint8_t attr_type;
	while (propStream.read<uint8_t>(attr_type) && attr_type != 0) {
		Attr_ReadValue ret = readAttr(static_cast<AttrTypes_t>(attr_type), propStream);
		if (ret == ATTR_READ_ERROR) {
			return false;
		} else if (ret == ATTR_READ_END) {
			return true;
		}
	}
	return true;
}

bool Item::unserializeItemNode(OTB::Loader&, const OTB::Node&, PropStream& propStream)
{
	return unserializeAttr(propStream);
}

void Item::serializeAttr(PropWriteStream& propWriteStream) const
{
	const ItemType& it = items[id];
	if (it.stackable || it.isFluidContainer() || it.isSplash()) {
		propWriteStream.write<uint8_t>(ATTR_COUNT);
		propWriteStream.write<uint8_t>(getSubType());
	}

	uint16_t charges = getCharges();
	if (charges != 0) {
		propWriteStream.write<uint8_t>(ATTR_CHARGES);
		propWriteStream.write<uint16_t>(charges);
	}

	if (it.moveable) {
		uint16_t actionId = getActionId();
		if (actionId != 0) {
			propWriteStream.write<uint8_t>(ATTR_ACTION_ID);
			propWriteStream.write<uint16_t>(actionId);
		}
	}

	const std::string& text = getText();
	if (!text.empty()) {
		propWriteStream.write<uint8_t>(ATTR_TEXT);
		propWriteStream.writeString(text);
	}

	const time_t writtenDate = getDate();
	if (writtenDate != 0) {
		propWriteStream.write<uint8_t>(ATTR_WRITTENDATE);
		propWriteStream.write<uint32_t>(writtenDate);
	}

	const std::string& writer = getWriter();
	if (!writer.empty()) {
		propWriteStream.write<uint8_t>(ATTR_WRITTENBY);
		propWriteStream.writeString(writer);
	}

	const std::string& specialDesc = getSpecialDescription();
	if (!specialDesc.empty()) {
		propWriteStream.write<uint8_t>(ATTR_DESC);
		propWriteStream.writeString(specialDesc);
	}

	if (hasAttribute(ITEM_ATTRIBUTE_DURATION)) {
		propWriteStream.write<uint8_t>(ATTR_DURATION);
		propWriteStream.write<uint32_t>(getIntAttr(ITEM_ATTRIBUTE_DURATION));
	}

	ItemDecayState_t decayState = getDecaying();
	if (decayState == DECAYING_TRUE || decayState == DECAYING_PENDING) {
		propWriteStream.write<uint8_t>(ATTR_DECAYING_STATE);
		propWriteStream.write<uint8_t>(decayState);
	}

	if (hasAttribute(ITEM_ATTRIBUTE_NAME)) {
		propWriteStream.write<uint8_t>(ATTR_NAME);
		propWriteStream.writeString(getStrAttr(ITEM_ATTRIBUTE_NAME));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_ARTICLE)) {
		propWriteStream.write<uint8_t>(ATTR_ARTICLE);
		propWriteStream.writeString(getStrAttr(ITEM_ATTRIBUTE_ARTICLE));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_PLURALNAME)) {
		propWriteStream.write<uint8_t>(ATTR_PLURALNAME);
		propWriteStream.writeString(getStrAttr(ITEM_ATTRIBUTE_PLURALNAME));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_WEIGHT)) {
		propWriteStream.write<uint8_t>(ATTR_WEIGHT);
		propWriteStream.write<uint32_t>(getIntAttr(ITEM_ATTRIBUTE_WEIGHT));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_ATTACK)) {
		propWriteStream.write<uint8_t>(ATTR_ATTACK);
		propWriteStream.write<int32_t>(getIntAttr(ITEM_ATTRIBUTE_ATTACK));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_CLASSIFICATION)) {
		propWriteStream.write<uint8_t>(ATTR_CLASSIFICATION);
		propWriteStream.write<uint32_t>(getIntAttr(ITEM_ATTRIBUTE_CLASSIFICATION));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_TIER)) {
		propWriteStream.write<uint8_t>(ATTR_TIER);
		propWriteStream.write<uint32_t>(getIntAttr(ITEM_ATTRIBUTE_TIER));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_DEFENSE)) {
		propWriteStream.write<uint8_t>(ATTR_DEFENSE);
		propWriteStream.write<int32_t>(getIntAttr(ITEM_ATTRIBUTE_DEFENSE));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE)) {
		propWriteStream.write<uint8_t>(ATTR_EXTRADEFENSE);
		propWriteStream.write<int32_t>(getIntAttr(ITEM_ATTRIBUTE_EXTRADEFENSE));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_IMBUINGSLOTS)) {
		// removido
	}

	if (hasAttribute(ITEM_ATTRIBUTE_ARMOR)) {
		propWriteStream.write<uint8_t>(ATTR_ARMOR);
		propWriteStream.write<int32_t>(getIntAttr(ITEM_ATTRIBUTE_ARMOR));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_HITCHANCE)) {
		propWriteStream.write<uint8_t>(ATTR_HITCHANCE);
		propWriteStream.write<int8_t>(getIntAttr(ITEM_ATTRIBUTE_HITCHANCE));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_SHOOTRANGE)) {
		propWriteStream.write<uint8_t>(ATTR_SHOOTRANGE);
		propWriteStream.write<uint8_t>(getIntAttr(ITEM_ATTRIBUTE_SHOOTRANGE));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_SPECIAL)) {
		propWriteStream.write<uint8_t>(ATTR_SPECIAL);
		propWriteStream.writeString(getStrAttr(ITEM_ATTRIBUTE_SPECIAL));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_OPENED)) {
		propWriteStream.write<uint8_t>(ATTR_OPENED);
		propWriteStream.write<uint8_t>(getIntAttr(ITEM_ATTRIBUTE_OPENED));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_IMBUED)) {
		propWriteStream.write<uint8_t>(ATTR_IMBUED);
		propWriteStream.write<uint8_t>(getIntAttr(ITEM_ATTRIBUTE_IMBUED));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_DECAYTO)) {
		propWriteStream.write<uint8_t>(ATTR_DECAYTO);
		propWriteStream.write<int32_t>(getIntAttr(ITEM_ATTRIBUTE_DECAYTO));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_QUICKLOOTCONTAINER)) {
		propWriteStream.write<uint8_t>(ATTR_QUICKLOOTCONTAINER);
		propWriteStream.write<uint32_t>(getQuicklootAttr());
	}

	if (hasAttribute(ITEM_ATTRIBUTE_WRAPID)) {
		propWriteStream.write<uint8_t>(ATTR_WRAPID);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_WRAPID));
	}

	// Dynamic element attributes for upgrade system
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTICE)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTICE);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTICE));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTEARTH)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTEARTH);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTEARTH));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTFIRE)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTFIRE);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTFIRE));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTENERGY)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTENERGY);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTENERGY));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTDEATH)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTDEATH);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTDEATH));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ELEMENTHOLY)) {
		propWriteStream.write<uint8_t>(ATTR_ELEMENTHOLY);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ELEMENTHOLY));
	}

	// Dynamic absorb percent attributes for upgrade system
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBICE)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBICE);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBICE));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBEARTH)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBEARTH);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBEARTH));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBFIRE)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBFIRE);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBFIRE));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBENERGY)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBENERGY);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBENERGY));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBDEATH)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBDEATH);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBDEATH));
	}
	
	if (hasAttribute(ITEM_ATTRIBUTE_ABSORBHOLY)) {
		propWriteStream.write<uint8_t>(ATTR_ABSORBHOLY);
		propWriteStream.write<uint16_t>(getIntAttr(ITEM_ATTRIBUTE_ABSORBHOLY));
	}

	if (hasAttribute(ITEM_ATTRIBUTE_CUSTOM)) {
		const ItemAttributes::CustomAttributeMap* customAttrMap = attributes->getCustomAttributeMap();
		propWriteStream.write<uint8_t>(ATTR_CUSTOM_ATTRIBUTES);
		propWriteStream.write<uint64_t>(static_cast<uint64_t>(customAttrMap->size()));
		for (const auto &entry : *customAttrMap) {
			// Serializing key type and value
			propWriteStream.writeString(entry.first);

			// Serializing value type and value
			entry.second.serialize(propWriteStream);
		}
	}
}

bool Item::hasProperty(ITEMPROPERTY prop) const
{
	const ItemType& it = items[id];
	switch (prop) {
		case CONST_PROP_BLOCKSOLID: return it.blockSolid;
		case CONST_PROP_MOVEABLE: return it.moveable && !hasAttribute(ITEM_ATTRIBUTE_UNIQUEID);
		case CONST_PROP_HASHEIGHT: return it.hasHeight;
		case CONST_PROP_BLOCKPROJECTILE: return it.blockProjectile;
		case CONST_PROP_BLOCKPATH: return it.blockPathFind;
		case CONST_PROP_ISVERTICAL: return it.isVertical;
		case CONST_PROP_ISHORIZONTAL: return it.isHorizontal;
		case CONST_PROP_IMMOVABLEBLOCKSOLID: return it.blockSolid && (!it.moveable || hasAttribute(ITEM_ATTRIBUTE_UNIQUEID));
		case CONST_PROP_IMMOVABLEBLOCKPATH: return it.blockPathFind && (!it.moveable || hasAttribute(ITEM_ATTRIBUTE_UNIQUEID));
		case CONST_PROP_IMMOVABLENOFIELDBLOCKPATH: return !it.isMagicField() && it.blockPathFind && (!it.moveable || hasAttribute(ITEM_ATTRIBUTE_UNIQUEID));
		case CONST_PROP_NOFIELDBLOCKPATH: return !it.isMagicField() && it.blockPathFind;
		case CONST_PROP_SUPPORTHANGABLE: return it.isHorizontal || it.isVertical;
		default: return false;
	}
}

uint32_t Item::getWeight() const
{
	uint32_t weight = getBaseWeight();
	if (isStackable()) {
		return weight * std::max<uint32_t>(1, getItemCount());
	}
	return weight;
}

std::string Item::getDescription(const ItemType& it, int32_t lookDistance,
								 const Item* item /*= nullptr*/, int32_t subType /*= -1*/, bool addArticle /*= true*/)
{
	const std::string* text = nullptr;
	std::string marcador = (lookDistance == -2 ? "\n{info}" : "");
	std::ostringstream s;
	s << getNameDescription(it, item, subType, addArticle);

	if (item) {
		subType = item->getSubType();
	}

	if (it.isRune()) {
		if (it.runeLevel > 0 || it.runeMagLevel > 0) {
			if (RuneSpell* rune = g_spells->getRuneSpell(it.id)) {
				int32_t tmpSubType = subType;
				if (item) {
					tmpSubType = item->getSubType();
				}
				s << ". " << (it.stackable && tmpSubType > 1 ? "They" : "It") << " can only be used by ";

				const VocSpellMap& vocMap = rune->getVocMap();
				std::vector<Vocation*> showVocMap;

				// vocations are usually listed with the unpromoted and promoted version, the latter being
				// hidden from description, so `total / 2` is most likely the amount of vocations to be shown.
				showVocMap.reserve(vocMap.size() / 2);
				for (const auto& voc : vocMap) {
					if (voc.second) {
						showVocMap.push_back(g_vocations.getVocation(voc.first));
					}
				}

				if (!showVocMap.empty()) {
					auto vocIt = showVocMap.begin(), vocLast = (showVocMap.end() - 1);
					while (vocIt != vocLast) {
						s << asLowerCaseString((*vocIt)->getVocName()) << "s";
						if (++vocIt == vocLast) {
							s << " and ";
						} else {
							s << ", ";
						}
					}
					s << asLowerCaseString((*vocLast)->getVocName()) << "s";
				} else {
					s << "players";
				}

				s << " with";

				if (it.runeLevel > 0) {
					s << " level " << it.runeLevel;
				}

				if (it.runeMagLevel > 0) {
					if (it.runeLevel > 0) {
						s << " and";
					}

					s << " magic level " << it.runeMagLevel;
				}

				s << " or higher";
			}
		}
	} else if (it.weaponType != WEAPON_NONE) {
		if (it.weaponType == WEAPON_DISTANCE && it.ammoType != AMMO_NONE) {
			bool begin = true;
			begin = false;
			s << " (Range: " << static_cast<uint16_t>(item ? item->getShootRange() : it.shootRange);

			int32_t attack;
			int8_t hitChance;
			if (item) {
				attack = item->getAttack();
				hitChance = item->getHitChance();
			} else {
				attack = it.attack;
				hitChance = it.hitChance;
			}

			if (attack != 0) {
				s << ", Atk " << std::showpos << attack << std::noshowpos;
			}

			if (hitChance != 0) {
				s << ", Hit% " << std::showpos << static_cast<int16_t>(hitChance) << std::noshowpos;
			}

			// Show Classification and Tier on item 
			uint32_t classification = item ? item->getClassification() : it.classification;
			uint32_t tier = item ? item->getTier() : it.tier;

			if (classification) {
				s << "\nClassification: " << classification << " Tier: " << tier;
			}
			
			if (it.abilities) {
				for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
					if (!it.abilities->skills[i]) {
						continue;
					}

					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
				}

				for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
					if (!it.abilities->skills[i]) {
						continue;
					}

					if (begin) {
						begin = false;
						s << " (";
					}
					else {
						s << ", ";
					}
					s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
				}

				if (it.abilities->stats[STAT_MAGICPOINTS]) {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "magic level " << std::showpos << it.abilities->stats[STAT_MAGICPOINTS] << std::noshowpos;
				}

				int16_t show = it.abilities->absorbPercent[0];
				if (show != 0) {
					for (size_t i = 1; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] != show) {
							show = 0;
							break;
						}
					}
				}

				if (show == 0) {
					bool tmp = true;

					for (size_t i = 0; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] == 0) {
							continue;
						}

						if (tmp) {
							tmp = false;

							if (begin) {
								begin = false;
								s << " (";
							} else {
								s << ", ";
							}

							s << "protection ";
						} else {
							s << ", ";
						}

						s << getCombatName(indexToCombatType(i)) << ' ' << std::showpos << it.abilities->absorbPercent[i] << std::noshowpos << '%';
					}
				} else {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "protection all " << std::showpos << show << std::noshowpos << '%';
				}

				show = it.abilities->fieldAbsorbPercent[0];
				if (show != 0) {
					for (size_t i = 1; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] != show) {
							show = 0;
							break;
						}
					}
				}

				if (show == 0) {
					bool tmp = true;

					for (size_t i = 0; i < COMBAT_COUNT; ++i) {
						if (it.abilities->fieldAbsorbPercent[i] == 0) {
							continue;
						}

						if (tmp) {
							tmp = false;

							if (begin) {
								begin = false;
								s << " (";
							} else {
								s << ", ";
							}

							s << "protection ";
						} else {
							s << ", ";
						}

						s << getCombatName(indexToCombatType(i)) << " field " << std::showpos << it.abilities->fieldAbsorbPercent[i] << std::noshowpos << '%';
					}
				} else {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "protection all fields " << std::showpos << show << std::noshowpos << '%';
				}

				if (it.abilities->speed) {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "speed " << std::showpos << (it.abilities->speed >> 1) << std::noshowpos;
				}
			}

			if (!begin) {
			s << ')';
			}
		} else if (it.weaponType == WEAPON_AMMO) {
			bool begin = true;
			
			int32_t attack = item ? item->getAttack() : it.attack;
			if (attack != 0) {
				begin = false;
				s << " (Atk:" << attack;

				// Show dynamic elements (priority over static)
				std::vector<std::pair<CombatType_t, uint16_t>> dynamicElements;
				if (item) {
					dynamicElements.push_back({COMBAT_ICEDAMAGE, item->getElementDamage(COMBAT_ICEDAMAGE)});
					dynamicElements.push_back({COMBAT_EARTHDAMAGE, item->getElementDamage(COMBAT_EARTHDAMAGE)});
					dynamicElements.push_back({COMBAT_FIREDAMAGE, item->getElementDamage(COMBAT_FIREDAMAGE)});
					dynamicElements.push_back({COMBAT_ENERGYDAMAGE, item->getElementDamage(COMBAT_ENERGYDAMAGE)});
					dynamicElements.push_back({COMBAT_DEATHDAMAGE, item->getElementDamage(COMBAT_DEATHDAMAGE)});
					dynamicElements.push_back({COMBAT_HOLYDAMAGE, item->getElementDamage(COMBAT_HOLYDAMAGE)});
				}
				
				bool hasAnyDynamicElement = false;
				if (item) {
					for (const auto& element : dynamicElements) {
						if (element.second > 0) {
							hasAnyDynamicElement = true;
							break;
						}
					}
				}
				
				if (hasAnyDynamicElement) {
					// Show physical + dynamic elements
					s << " physical";
					for (const auto& element : dynamicElements) {
						if (element.second > 0) {
							const char* elementName = "unknown";
							switch (element.first) {
								case COMBAT_ICEDAMAGE: elementName = "ice"; break;
								case COMBAT_FIREDAMAGE: elementName = "fire"; break;
								case COMBAT_ENERGYDAMAGE: elementName = "energy"; break;
								case COMBAT_EARTHDAMAGE: elementName = "earth"; break;
								case COMBAT_DEATHDAMAGE: elementName = "death"; break;
								case COMBAT_HOLYDAMAGE: elementName = "holy"; break;
								default: break;
							}
							s << " + " << element.second << ' ' << elementName;
						}
					}
				} else if (it.abilities && it.abilities->elementType != COMBAT_NONE && it.abilities->elementDamage != 0) {
					// Fallback to static element from XML
					const char* elementName = "unknown";
					switch (it.abilities->elementType) {
						case COMBAT_ICEDAMAGE: elementName = "ice"; break;
						case COMBAT_FIREDAMAGE: elementName = "fire"; break;
						case COMBAT_ENERGYDAMAGE: elementName = "energy"; break;
						case COMBAT_EARTHDAMAGE: elementName = "earth"; break;
						case COMBAT_DEATHDAMAGE: elementName = "death"; break;
						case COMBAT_HOLYDAMAGE: elementName = "holy"; break;
						default: break;
					}
					s << " physical + " << it.abilities->elementDamage << ' ' << elementName;
				}
			}

			// Show max hit chance if available
			int32_t maxHitChance = it.maxHitChance;
			if (maxHitChance > 0) {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}
				s << "Max Hit%+" << maxHitChance;
			}

			if (!begin) {
				s << ')';
			}
		} else if (it.weaponType != WEAPON_NONE) {
			bool begin = true;

			int32_t attack, defense, extraDefense;
			if (item) {
				attack = item->getAttack();
				defense = item->getDefense();
				extraDefense = item->getExtraDefense();
			} else {
				attack = it.attack;
				defense = it.defense;
				extraDefense = it.extraDefense;
			}

			if (attack != 0) {
				begin = false;
				s << " (Atk:" << attack;

				// Show dynamic elements (priority over static)
				std::vector<std::pair<CombatType_t, uint16_t>> dynamicElements;
				if (item) {
					dynamicElements.push_back({COMBAT_ICEDAMAGE, item->getElementDamage(COMBAT_ICEDAMAGE)});
					dynamicElements.push_back({COMBAT_EARTHDAMAGE, item->getElementDamage(COMBAT_EARTHDAMAGE)});
					dynamicElements.push_back({COMBAT_FIREDAMAGE, item->getElementDamage(COMBAT_FIREDAMAGE)});
					dynamicElements.push_back({COMBAT_ENERGYDAMAGE, item->getElementDamage(COMBAT_ENERGYDAMAGE)});
					dynamicElements.push_back({COMBAT_DEATHDAMAGE, item->getElementDamage(COMBAT_DEATHDAMAGE)});
					dynamicElements.push_back({COMBAT_HOLYDAMAGE, item->getElementDamage(COMBAT_HOLYDAMAGE)});
				}
				
				bool hasAnyDynamicElement = false;
				if (item) {
					for (const auto& element : dynamicElements) {
						if (element.second > 0) {
							hasAnyDynamicElement = true;
							break;
						}
					}
				}
				
				if (hasAnyDynamicElement) {
					// Show physical + dynamic elements
					s << " physical";
					for (const auto& element : dynamicElements) {
						if (element.second > 0) {
							const char* elementName = "unknown";
							switch (element.first) {
								case COMBAT_ICEDAMAGE: elementName = "ice"; break;
								case COMBAT_FIREDAMAGE: elementName = "fire"; break;
								case COMBAT_ENERGYDAMAGE: elementName = "energy"; break;
								case COMBAT_EARTHDAMAGE: elementName = "earth"; break;
								case COMBAT_DEATHDAMAGE: elementName = "death"; break;
								case COMBAT_HOLYDAMAGE: elementName = "holy"; break;
								default: break;
							}
							s << " + " << element.second << ' ' << elementName;
						}
					}
				} else if (it.abilities && it.abilities->elementType != COMBAT_NONE && it.abilities->elementDamage != 0) {
					// Fallback to static element from XML
					const char* elementName = "unknown";
					switch (it.abilities->elementType) {
						case COMBAT_ICEDAMAGE: elementName = "ice"; break;
						case COMBAT_FIREDAMAGE: elementName = "fire"; break;
						case COMBAT_ENERGYDAMAGE: elementName = "energy"; break;
						case COMBAT_EARTHDAMAGE: elementName = "earth"; break;
						case COMBAT_DEATHDAMAGE: elementName = "death"; break;
						case COMBAT_HOLYDAMAGE: elementName = "holy"; break;
						default: break;
					}
					s << " physical + " << it.abilities->elementDamage << ' ' << elementName;
				}
			}

			if (defense != 0 || extraDefense != 0) {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << "Def:" << defense;
				if (extraDefense != 0) {
					s << ' ' << std::showpos << extraDefense << std::noshowpos;
				}
			}

			if (it.abilities) {
				for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
					if (!it.abilities->skills[i]) {
						continue;
					}

					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
				}

				for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
					if (!it.abilities->skills[i]) {
						continue;
					}

					if (begin) {
						begin = false;
						s << " (";
					}
					else {
						s << ", ";
					}
					s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos << '%';
				}

				if (it.abilities->stats[STAT_MAGICPOINTS]) {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "magic level " << std::showpos << it.abilities->stats[STAT_MAGICPOINTS] << std::noshowpos;
				}

				int16_t show = it.abilities->absorbPercent[0];
				if (show != 0) {
					for (size_t i = 1; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] != show) {
							show = 0;
							break;
						}
					}
				}

				if (show == 0) {
					bool tmp = true;

					for (size_t i = 0; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] == 0) {
							continue;
						}

						if (tmp) {
							tmp = false;

							if (begin) {
								begin = false;
								s << " (";
							} else {
								s << ", ";
							}

							s << "protection ";
						} else {
							s << ", ";
						}

						s << getCombatName(indexToCombatType(i)) << ' ' << std::showpos << it.abilities->absorbPercent[i] << std::noshowpos << '%';
					}
				} else {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "protection all " << std::showpos << show << std::noshowpos << '%';
				}

				show = it.abilities->fieldAbsorbPercent[0];
				if (show != 0) {
					for (size_t i = 1; i < COMBAT_COUNT; ++i) {
						if (it.abilities->absorbPercent[i] != show) {
							show = 0;
							break;
						}
					}
				}

				if (show == 0) {
					bool tmp = true;

					for (size_t i = 0; i < COMBAT_COUNT; ++i) {
						if (it.abilities->fieldAbsorbPercent[i] == 0) {
							continue;
						}

						if (tmp) {
							tmp = false;

							if (begin) {
								begin = false;
								s << " (";
							} else {
								s << ", ";
							}

							s << "protection ";
						} else {
							s << ", ";
						}

						s << getCombatName(indexToCombatType(i)) << " field " << std::showpos << it.abilities->fieldAbsorbPercent[i] << std::noshowpos << '%';
					}
				} else {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "protection all fields " << std::showpos << show << std::noshowpos << '%';
				}

				if (it.abilities->speed) {
					if (begin) {
						begin = false;
						s << " (";
					} else {
						s << ", ";
					}

					s << "speed " << std::showpos << (it.abilities->speed >> 1) << std::noshowpos;
				}
			}

			if (!begin) {
				s << ')';
			}
		}
	} else if (it.armor != 0 || (item && item->getArmor() != 0) || it.showAttributes) {
		bool begin = true;

		int32_t armor = (item ? item->getArmor() : it.armor);
		if (armor != 0) {
			s << " (Arm:" << armor;
			begin = false;
		}

		// Show Classification and Tier on item 
		uint32_t classification = item ? item->getClassification() : it.classification;
		uint32_t tier = item ? item->getTier() : it.tier;

		if (classification) {
			s << "\nClassification: " << classification << " Tier: " << tier;
		}

		if (it.abilities) {
			for (uint8_t i = SKILL_FIRST; i <= SKILL_FISHING; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos;
			}

			for (uint8_t i = SKILL_CRITICAL_HIT_CHANCE; i <= SKILL_LAST; i++) {
				if (!it.abilities->skills[i]) {
					continue;
				}

				if (begin) {
					begin = false;
					s << " (";
				}
				else {
					s << ", ";
				}

				s << getSkillName(i) << ' ' << std::showpos << it.abilities->skills[i] << std::noshowpos << '%';
			}

			if (it.abilities->stats[STAT_MAGICPOINTS]) {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << "magic level " << std::showpos << it.abilities->stats[STAT_MAGICPOINTS] << std::noshowpos;
			}

			int16_t show = it.abilities->absorbPercent[0];
			if (show != 0) {
				for (size_t i = 1; i < COMBAT_COUNT; ++i) {
					if (it.abilities->absorbPercent[i] != show) {
						show = 0;
						break;
					}
				}
			}

			if (!show) {
				bool protectionBegin = true;
				
				// First show static absorptions from ItemType
				for (size_t i = 0; i < COMBAT_COUNT; ++i) {
					if (it.abilities->absorbPercent[i] == 0) {
						continue;
					}

					if (protectionBegin) {
						protectionBegin = false;

						if (begin) {
							begin = false;
							s << " (";
						} else {
							s << ", ";
						}

						s << "protection ";
					} else {
						s << ", ";
					}

					// Check if this element has dynamic bonus and combine values
					CombatType_t combatType = indexToCombatType(i);
					int32_t totalAbsorb = it.abilities->absorbPercent[i];
					
					// Add dynamic absorb if item exists
					if (item) {
						itemAttrTypes dynamicAttr = ITEM_ATTRIBUTE_NONE;
						switch (combatType) {
							case COMBAT_ICEDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBICE; break;
							case COMBAT_EARTHDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBEARTH; break;
							case COMBAT_FIREDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBFIRE; break;
							case COMBAT_ENERGYDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBENERGY; break;
							case COMBAT_DEATHDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBDEATH; break;
							case COMBAT_HOLYDAMAGE: dynamicAttr = ITEM_ATTRIBUTE_ABSORBHOLY; break;
							default: break;
						}
						
						if (dynamicAttr != ITEM_ATTRIBUTE_NONE && item->hasAttribute(dynamicAttr)) {
							totalAbsorb += item->getIntAttr(dynamicAttr);
						}
					}
					
					s << getCombatName(combatType) << ' ' << std::showpos << totalAbsorb << std::noshowpos << '%';
				}
				
				// Now show ONLY dynamic absorptions that don't have static counterparts
				if (item) {
					std::vector<std::pair<itemAttrTypes, CombatType_t>> dynamicAttributes = {
						{ITEM_ATTRIBUTE_ABSORBICE, COMBAT_ICEDAMAGE},
						{ITEM_ATTRIBUTE_ABSORBEARTH, COMBAT_EARTHDAMAGE},
						{ITEM_ATTRIBUTE_ABSORBFIRE, COMBAT_FIREDAMAGE},
						{ITEM_ATTRIBUTE_ABSORBENERGY, COMBAT_ENERGYDAMAGE},
						{ITEM_ATTRIBUTE_ABSORBDEATH, COMBAT_DEATHDAMAGE},
						{ITEM_ATTRIBUTE_ABSORBHOLY, COMBAT_HOLYDAMAGE}
					};
					
					for (const auto& attr : dynamicAttributes) {
						// Only show if item has dynamic absorb BUT no static absorb for this element
						if (item->hasAttribute(attr.first) && it.abilities->absorbPercent[combatTypeToIndex(attr.second)] == 0) {
							int32_t dynamicValue = item->getIntAttr(attr.first);
							if (dynamicValue > 0) {
								if (protectionBegin) {
									protectionBegin = false;
									if (begin) {
										begin = false;
										s << " (";
									} else {
										s << ", ";
									}
									s << "protection ";
								} else {
									s << ", ";
								}
								
								s << getCombatName(attr.second) << ' ' << std::showpos << dynamicValue << std::noshowpos << '%';
							}
						}
					}
				}
				
			} else {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << "protection all " << std::showpos << show << std::noshowpos << '%';
			}

			show = it.abilities->fieldAbsorbPercent[0];
			if (show != 0) {
				for (size_t i = 1; i < COMBAT_COUNT; ++i) {
					if (it.abilities->absorbPercent[i] != show) {
						show = 0;
						break;
					}
				}
			}

			if (!show) {
				bool tmp = true;

				for (size_t i = 0; i < COMBAT_COUNT; ++i) {
					if (it.abilities->fieldAbsorbPercent[i] == 0) {
						continue;
					}

					if (tmp) {
						tmp = false;

						if (begin) {
							begin = false;
							s << " (";
						} else {
							s << ", ";
						}

						s << "protection ";
					} else {
						s << ", ";
					}

					s << getCombatName(indexToCombatType(i)) << " field " << std::showpos << it.abilities->fieldAbsorbPercent[i] << std::noshowpos << '%';
				}
			} else {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << "protection all fields " << std::showpos << show << std::noshowpos << '%';
			}

			if (it.abilities->speed) {
				if (begin) {
					begin = false;
					s << " (";
				} else {
					s << ", ";
				}

				s << "speed " << std::showpos << (it.abilities->speed >> 1) << std::noshowpos;
			}
		}

		if (!begin) {
			s << ')';
		}
	} else if (it.isContainer() || (item && item->getContainer())) {
		uint32_t volume = 0;
		if (!item || !item->hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
			if (it.isContainer()) {
				volume = it.maxItems;
			} else {
				volume = item->getContainer()->capacity();
			}
		}

		if (volume != 0) {
			s << " (Vol:" << volume << ')';
		}
	} else {
		bool found = true;

		if (it.abilities) {
			if (it.abilities->speed > 0) {
				s << " (speed " << std::showpos << (it.abilities->speed / 2) << std::noshowpos << ')';
			} else if (hasBitSet(CONDITION_DRUNK, it.abilities->conditionSuppressions)) {
				s << " (hard drinking)";
			} else if (it.abilities->invisible) {
				s << " (invisibility)";
			} else if (it.abilities->regeneration) {
				s << " (faster regeneration)";
			} else if (it.abilities->manaShield) {
				s << " (mana shield)";
			} else {
				found = false;
			}
		} else {
			found = false;
		}

		if (!found) {
			if (it.isKey()) {
				s << " (Key:" << std::setfill('0') << std::setw(4) << (item ? item->getActionId() : 0) << ')';
			} else if (it.isFluidContainer()) {
				if (subType > 0) {
					const std::string& itemName = items[subType].name;
					s << " of " << (!itemName.empty() ? itemName : "unknown");
				} else {
					s << ". It is empty";
				}
			} else if (it.isSplash()) {
				s << " of ";

				if (subType > 0 && !items[subType].name.empty()) {
					s << items[subType].name;
				} else {
					s << "unknown";
				}
			} else if (it.allowDistRead && (it.id < 7369 || it.id > 7371)) {
				s << '.' << std::endl;

				if (lookDistance <= 4) {
					if (item) {
						text = &item->getText();
						if (!text->empty()) {
							const std::string& writer = item->getWriter();
							if (!writer.empty()) {
								s << writer << " wrote";
								time_t date = item->getDate();
								if (date != 0) {
									s << " on " << formatDateShort(date);
								}
								s << ": ";
							} else {
								s << "You read: ";
							}
							s << *text;
						} else {
							s << "Nothing is written on it";
						}
					} else {
						s << "Nothing is written on it";
					}
				} else {
					s << "You are too far away to read it";
				}
			} else if (it.levelDoor != 0 && item) {
				uint16_t actionId = item->getActionId();
				if (actionId >= it.levelDoor) {
					s << " for level " << (actionId - it.levelDoor);
				}
			}
		}
	}

	if (it.showCharges) {
		s << " that has " << subType << " charge" << (subType != 1 ? "s" : "") << " left";
	}

	if (it.showDuration) {
		if (item && item->hasAttribute(ITEM_ATTRIBUTE_DURATION)) {
			uint32_t duration = item->getDuration() / 1000;
			s << " that will expire in ";

			if (duration >= 86400) {
				uint16_t days = duration / 86400;
				uint16_t hours = (duration % 86400) / 3600;
				s << days << " day" << (days != 1 ? "s" : "");

				if (hours > 0) {
					s << " and " << hours << " hour" << (hours != 1 ? "s" : "");
				}
			} else if (duration >= 3600) {
				uint16_t hours = duration / 3600;
				uint16_t minutes = (duration % 3600) / 60;
				s << hours << " hour" << (hours != 1 ? "s" : "");

				if (minutes > 0) {
					s << " and " << minutes << " minute" << (minutes != 1 ? "s" : "");
				}
			} else if (duration >= 60) {
				uint16_t minutes = duration / 60;
				s << minutes << " minute" << (minutes != 1 ? "s" : "");
				uint16_t seconds = duration % 60;

				if (seconds > 0) {
					s << " and " << seconds << " second" << (seconds != 1 ? "s" : "");
				}
			} else {
				s << duration << " second" << (duration != 1 ? "s" : "");
			}
		} else {
			s << " that is brand-new";
		}
	}

	if (!it.allowDistRead || (it.id >= 7369 && it.id <= 7371)) {
		s << '.';
	} else {
		if (!text && item) {
			text = &item->getText();
		}

		if (!text || text->empty()) {
			s << '.';
		}
	}

	if (it.wieldInfo != 0) {
		s << std::endl << marcador << "It can only be wielded properly by ";

		if (it.wieldInfo & WIELDINFO_PREMIUM) {
			s << "premium ";
		}

		if (!it.vocationString.empty()) {
			s << it.vocationString;
		} else {
			s << "players";
		}

		if (it.wieldInfo & WIELDINFO_LEVEL) {
			s << " of level " << it.minReqLevel << " or higher";
		}

		if (it.wieldInfo & WIELDINFO_MAGLV) {
			if (it.wieldInfo & WIELDINFO_LEVEL) {
				s << " and";
			} else {
				s << " of";
			}

			s << " magic level " << it.minReqMagicLevel << " or higher";
		}

		s << '.';
	}

	if (it.imbuingSlots > 0) {
		s << std::endl << marcador << "Imbuements: (";
		if (item) {
			Item* thisItem = const_cast<Item*>(item);
			Imbuement* imbuement = nullptr;
			BaseImbue* base = nullptr;
			for (uint8_t slot = 0; slot < it.imbuingSlots; slot++) {
				if (slot > 0) {
					s << ", ";
				}
				uint32_t info = thisItem->getImbuement(slot);
				if (info >> 8 != 0) {
					imbuement = g_imbuements.getImbuement(info & 0xFF);
					base = g_imbuements.getBaseByID(imbuement->getBaseID());
					s << base->name << " " << imbuement->getName() << " ";

					uint32_t hours = (info >> 8) / 3600;
					uint32_t minutes = ((info >> 8) / 60) % 60;

					s << hours << ":" << &"0"[minutes > 9] << minutes << "h";
				} else {
					s << "Empty Slot";
				}
			}
		} else {
			for (uint8_t slot = 0; slot < it.imbuingSlots; slot++) {
				if (slot > 0) {
					s << ", ";
				}
				s << "Empty Slot";
			}
		}
		s << ").";
	}

	if (lookDistance <= 1) {
		if (item) {
			const uint32_t weight = item->getWeight();
			if (weight != 0 && it.pickupable) {
				s << std::endl << marcador << getWeightDescription(it, weight, item->getItemCount());
			}
		} else if (it.weight != 0 && it.pickupable) {
			s << std::endl << marcador << getWeightDescription(it, it.weight);
		}
	}

	if (item) {
		const std::string& specialDescription = item->getSpecialDescription();
		if (!specialDescription.empty()) {
			s << std::endl << marcador << specialDescription;
		} else if (lookDistance <= 1 && !it.description.empty()) {
			s << std::endl << marcador << it.description;
		}
	} else if (lookDistance <= 1 && !it.description.empty()) {
		s << std::endl << marcador << it.description;
	}

	if (it.allowDistRead && it.id >= 7369 && it.id <= 7371) {
		if (!text && item) {
			text = &item->getText();
		}

		if (text && !text->empty()) {
			s << std::endl << *text;
		}
	}
	return s.str();
}

std::string Item::getDescription(int32_t lookDistance) const
{
	const ItemType& it = items[id];
	return getDescription(it, lookDistance, this);
}

std::string Item::getNameDescription(const ItemType& it, const Item* item /*= nullptr*/, int32_t subType /*= -1*/, bool addArticle /*= true*/)
{
	if (item) {
		subType = item->getSubType();
	}

	std::ostringstream s;

	const std::string& name = (item ? item->getName() : it.name);
	if (!name.empty()) {
		if (it.stackable && subType > 1) {
			if (it.showCount) {
				s << subType << ' ';
			}

			s << (item ? item->getPluralName() : it.getPluralName());
		} else {
			if (addArticle) {
				const std::string& article = (item ? item->getArticle() : it.article);
				if (!article.empty()) {
					s << article << ' ';
				}
			}

			s << name;
		}
	} else {
		s << "an item of type " << it.id;
	}
	return s.str();
}

std::string Item::getNameDescription() const
{
	const ItemType& it = items[id];
	return getNameDescription(it, this);
}

std::string Item::getWeightDescription(const ItemType& it, uint32_t weight, uint32_t count /*= 1*/)
{
	std::ostringstream ss;
	if (it.stackable && count > 1 && it.showCount != 0) {
		ss << "They weigh ";
	} else {
		ss << "It weighs ";
	}

	if (weight < 10) {
		ss << "0.0" << weight;
	} else if (weight < 100) {
		ss << "0." << weight;
	} else {
		std::string weightString = std::to_string(weight);
		weightString.insert(weightString.end() - 2, '.');
		ss << weightString;
	}

	ss << " oz.";
	return ss.str();
}

std::string Item::getWeightDescription(uint32_t weight) const
{
	const ItemType& it = Item::items[id];
	return getWeightDescription(it, weight, getItemCount());
}

std::string Item::getWeightDescription() const
{
	uint32_t weight = getWeight();
	if (weight == 0) {
		return std::string();
	}
	return getWeightDescription(weight);
}

void Item::setUniqueId(uint16_t n, bool force /* = false*/)
{
	if (hasAttribute(ITEM_ATTRIBUTE_UNIQUEID) && !force) {
		return;
	}

	if (g_game.addUniqueItem(n, this)) {
		getAttributes()->setUniqueId(n);
	}
}

bool Item::canDecay() const
{
	const Item* item = dynamic_cast<const Item*>(this);
	if (!item || item == nullptr) {
		return false;
	}

	Cylinder* dynamicParent = dynamic_cast<Cylinder*>(parent);
	if (dynamicParent == nullptr) {
		return false;
	}

	if (isRemoved()) {
		return false;
	}	

	const ItemType& it = Item::items[id];
	if (getDecayTo() < 0 || it.decayTime == 0) {
		return false;
	}

	if (hasAttribute(ITEM_ATTRIBUTE_UNIQUEID)) {
		return false;
	}

	return true;
}

uint32_t Item::getWorth() const
{
	switch (id) {
		case ITEM_GOLD_COIN:
			return count;

		case ITEM_PLATINUM_COIN:
			return count * 100;

		case ITEM_CRYSTAL_COIN:
			return count * 10000;

		default:
			return 0;
	}
}

LightInfo Item::getLightInfo() const
{
	const ItemType& it = items[id];
	return {it.lightLevel, it.lightColor};
}

std::string ItemAttributes::emptyString;
int64_t ItemAttributes::emptyInt;
double ItemAttributes::emptyDouble;
bool ItemAttributes::emptyBool;

const std::string& ItemAttributes::getStrAttr(itemAttrTypes type) const
{
	if (!isStrAttrType(type)) {
		return emptyString;
	}

	const Attribute* attr = getExistingAttr(type);
	if (!attr) {
		return emptyString;
	}
	return *attr->value.string;
}

void ItemAttributes::setStrAttr(itemAttrTypes type, const std::string& value)
{
	if (!isStrAttrType(type)) {
		return;
	}

	if (value.empty()) {
		return;
	}

	Attribute& attr = getAttr(type);
	delete attr.value.string;
	attr.value.string = new std::string(value);
}

void ItemAttributes::removeAttribute(itemAttrTypes type)
{
	if (!hasAttribute(type)) {
		return;
	}

	auto prev_it = attributes.cbegin();
	if ((*prev_it).type == type) {
		attributes.pop_front();
	} else {
		auto it = prev_it, end = attributes.cend();
		while (++it != end) {
			if ((*it).type == type) {
				attributes.erase_after(prev_it);
				break;
			}
			prev_it = it;

		}
	}
	attributeBits &= ~type;
}

int64_t ItemAttributes::getIntAttr(itemAttrTypes type) const
{
	if (!isIntAttrType(type)) {
		return 0;
	}

	const Attribute* attr = getExistingAttr(type);
	if (!attr) {
		return 0;
	}
	return attr->value.integer;
}

void ItemAttributes::setIntAttr(itemAttrTypes type, int64_t value)
{
	if (!isIntAttrType(type)) {
		return;
	}

	getAttr(type).value.integer = value;
}

void ItemAttributes::increaseIntAttr(itemAttrTypes type, int64_t value)
{
	if (!isIntAttrType(type)) {
		return;
	}

	getAttr(type).value.integer += value;
}

const ItemAttributes::Attribute* ItemAttributes::getExistingAttr(itemAttrTypes type) const
{
	if (hasAttribute(type)) {
		for (const Attribute& attribute : attributes) {
			if (attribute.type == type) {
				return &attribute;
			}
		}
	}
	return nullptr;
}

ItemAttributes::Attribute& ItemAttributes::getAttr(itemAttrTypes type)
{
	if (hasAttribute(type)) {
		for (Attribute& attribute : attributes) {
			if (attribute.type == type) {
				return attribute;
			}
		}
	}

	attributeBits |= type;
	attributes.emplace_front(type);
	return attributes.front();
}

void Item::startDecaying()
{
	g_game.startDecay(this);
}

bool Item::hasMarketAttributes() const
{
	if (attributes == nullptr) {
		return true;
	}

	if (items[id].imbuingSlots > 0) {
		Item* item = const_cast<Item*>(this);
		for (uint8_t slot = 0; slot < items[id].imbuingSlots; slot++) {
			uint32_t info = item->getImbuement(slot);
			if (info >> 8 != 0) {
				return false;
			}
		}

		// // desativado para parar o choro
		// if (item->hasAttribute(ITEM_ATTRIBUTE_IMBUED)) {
		// 	return false;
		// }

	}

	for (const auto& attr : attributes->getList()) {
		if (attr.type == ITEM_ATTRIBUTE_CHARGES) {
			uint16_t charges = static_cast<uint16_t>(attr.value.integer);
			if (charges != items[id].charges) {
				return false;
			}
		} else if (attr.type == ITEM_ATTRIBUTE_DURATION) {
			uint32_t duration = static_cast<uint32_t>(attr.value.integer);
			if (duration != getDefaultDuration()) {
				return false;
			}
		} else {
			return false;
		}
	}
	return true;
}

template<>
const std::string& ItemAttributes::CustomAttribute::get<std::string>() {
	if (value.type() == typeid(std::string)) {
		return boost::get<std::string>(value);
	}

	return emptyString;
}

template<>
const int64_t& ItemAttributes::CustomAttribute::get<int64_t>() {
	if (value.type() == typeid(int64_t)) {
		return boost::get<int64_t>(value);
	}

	return emptyInt;
}

template<>
const double& ItemAttributes::CustomAttribute::get<double>() {
	if (value.type() == typeid(double)) {
		return boost::get<double>(value);
	}

	return emptyDouble;
}

template<>
const bool& ItemAttributes::CustomAttribute::get<bool>() {
	if (value.type() == typeid(bool)) {
		return boost::get<bool>(value);
	}

	return emptyBool;
}