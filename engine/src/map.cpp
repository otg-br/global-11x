/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
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

#include "iomap.h"
#include "iomapserialize.h"
#include "combat.h"
#include "creature.h"
#include "game.h"

extern Game g_game;

bool Map::loadMap(const std::string& identifier, bool loadHouses, const Position& relativePosition)
{
	IOMap loader;
	if (!loader.loadMap(this, identifier, relativePosition)) {
		std::cout << "[Fatal - Map::loadMap] " << loader.getLastErrorString() << std::endl;
		return false;
	}

	if (!IOMap::loadSpawns(this)) {
		std::cout << "[Warning - Map::loadMap] Failed to load spawn data." << std::endl;
	}

	if (loadHouses) {
		if (!IOMap::loadHouses(this)) {
			std::cout << "[Warning - Map::loadMap] Failed to load house data." << std::endl;
		}

		IOMapSerialize::loadHouseInfo();
		IOMapSerialize::loadHouseItems(this);
	}

	return true;
}

bool Map::save()
{
	bool saved = false;
	for (uint32_t tries = 0; tries < 3; tries++) {
		if (IOMapSerialize::saveHouseInfo()) {
			saved = true;
			break;
		}
	}

	if (!saved) {
		return false;
	}

	saved = false;
	for (uint32_t tries = 0; tries < 3; tries++) {
		if (IOMapSerialize::saveHouseItems()) {
			saved = true;
			break;
		}
	}

	return saved;
}

Tile* Map::getTile(uint16_t x, uint16_t y, uint8_t z) const
{
	if (z >= MAP_MAX_LAYERS) {
		return nullptr;
	}

	const QTreeLeafNode* leaf = root.getLeaf(x, y);
	if (!leaf) {
		return nullptr;
	}

	const Floor* floor = leaf->getFloor(z);
	if (!floor) {
		return nullptr;
	}
	return floor->tiles[x & FLOOR_MASK][y & FLOOR_MASK];
}

void Map::setTile(uint16_t x, uint16_t y, uint8_t z, Tile* newTile)
{
	if (z >= MAP_MAX_LAYERS) {
		std::cout << "ERROR: Attempt to set tile on invalid coordinate " << Position(x, y, z) << "!" << std::endl;
		return;
	}

	QTreeLeafNode* leaf = root.createLeaf(x, y);
	Floor* floor = leaf->createFloor(z);
	uint32_t offsetX = x & FLOOR_MASK;
	uint32_t offsetY = y & FLOOR_MASK;

	Tile*& tile = floor->tiles[offsetX][offsetY];
	if (tile) {
		TileItemVector* items = newTile->getItemList();
		if (items) {
			for (auto it = items->rbegin(), end = items->rend(); it != end; ++it) {
				tile->addThing(*it);
			}
			items->clear();
		}

		Item* ground = newTile->getGround();
		if (ground) {
			tile->addThing(ground);
			newTile->setGround(nullptr);
		}
		delete newTile;
	} else {
		tile = newTile;
	}
}

bool Map::placeCreature(const Position& centerPos, Creature* creature, bool extendedPos/* = false*/, bool forceLogin/* = false*/)
{
	bool foundTile;
	bool placeInPZ;

	Tile* tile = getTile(centerPos.x, centerPos.y, centerPos.z);
	if (tile) {
		placeInPZ = tile->hasFlag(TILESTATE_PROTECTIONZONE);
		ReturnValue ret = tile->queryAdd(0, *creature, 1, FLAG_IGNOREBLOCKITEM | FLAG_IGNOREFIELDDAMAGE);
		foundTile = (forceLogin && tile->getGround() != nullptr) || ret == RETURNVALUE_NOERROR || ret == RETURNVALUE_PLAYERISNOTINVITED;
	} else {
		placeInPZ = false;
		foundTile = false;
	}

	if (!foundTile) {
		static std::vector<std::pair<int32_t, int32_t>> extendedRelList {
			                   {0, -2},
			         {-1, -1}, {0, -1}, {1, -1},
			{-2, 0}, {-1,  0},          {1,  0}, {2, 0},
			         {-1,  1}, {0,  1}, {1,  1},
			                   {0,  2}
		};

		static std::vector<std::pair<int32_t, int32_t>> normalRelList {
			{-1, -1}, {0, -1}, {1, -1},
			{-1,  0},          {1,  0},
			{-1,  1}, {0,  1}, {1,  1}
		};

		std::vector<std::pair<int32_t, int32_t>>& relList = (extendedPos ? extendedRelList : normalRelList);

		if (extendedPos) {
			std::shuffle(relList.begin(), relList.begin() + 4, getRandomGenerator());
			std::shuffle(relList.begin() + 4, relList.end(), getRandomGenerator());
		} else {
			std::shuffle(relList.begin(), relList.end(), getRandomGenerator());
		}

		for (const auto& it : relList) {
			Position tryPos(centerPos.x + it.first, centerPos.y + it.second, centerPos.z);

			tile = getTile(tryPos.x, tryPos.y, tryPos.z);
			if (!tile || (placeInPZ && !tile->hasFlag(TILESTATE_PROTECTIONZONE))) {
				continue;
			}

			if (tile->queryAdd(0, *creature, 1, FLAG_IGNOREFIELDDAMAGE) == RETURNVALUE_NOERROR) {
				if (!extendedPos || isSightClear(centerPos, tryPos, false)) {
					foundTile = true;
					break;
				}
			}
		}

		if (!foundTile) {
			return false;
		}
	}

	int32_t index = 0;
	uint32_t flags = 0;
	Item* toItem = nullptr;

	Cylinder* toCylinder = tile->queryDestination(index, *creature, &toItem, flags);
	toCylinder->internalAddThing(creature);

	const Position& dest = toCylinder->getPosition();
	getQTNode(dest.x, dest.y)->addCreature(creature, dest);
	return true;
}

void Map::moveCreature(Creature& creature, Tile& newTile, bool forceTeleport/* = false*/)
{
	Tile& oldTile = *creature.getTile();

	Position oldPos = oldTile.getPosition();
	Position newPos = newTile.getPosition();

	bool teleport = forceTeleport || !newTile.getGround() || !Position::areInRange<1, 1, 0>(oldPos, newPos);

	SpectatorVec spectators;
	if (teleport) {
		getSpectators(spectators, oldPos, true);
		getSpectators(spectators, newPos, true);
	} else {
		int mnorth = newPos.getX() < oldPos.getX() ? 1 : 0;
		int msouth = newPos.getX() > oldPos.getX() ? 1 : 0;
		int mwest = newPos.getY() < oldPos.getY() ? 1 : 0;
		int meast = newPos.getY() > oldPos.getY() ? 1 : 0;
		getSpectators(spectators, oldPos, true, false, maxViewportX + mnorth, maxViewportX + msouth, maxViewportY + mwest, +maxViewportY + meast);
	}

	std::vector<int32_t> oldStackPosVector;
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			if (tmpPlayer->canSeeCreature(&creature)) {
				oldStackPosVector.push_back(oldTile.getClientIndexOfCreature(tmpPlayer, &creature));
			} else {
				oldStackPosVector.push_back(-1);
			}
		}
	}

	//remove the creature
	oldTile.removeThing(&creature, 0);

	QTreeLeafNode* leaf = getQTNode(oldPos.x, oldPos.y);
	QTreeLeafNode* new_leaf = getQTNode(newPos.x, newPos.y);

	// Switch the node ownership
	if (leaf != new_leaf) {
		leaf->removeCreature(&creature);
		new_leaf->addCreature(&creature, newPos);
	} else {
		leaf->moveCreature(&creature, newPos);
	}

	//add the creature
	newTile.addThing(&creature);

	if (!teleport) {
		if (oldPos.y > newPos.y) {
			creature.setDirection(DIRECTION_NORTH);
		} else if (oldPos.y < newPos.y) {
			creature.setDirection(DIRECTION_SOUTH);
		}

		if (oldPos.x < newPos.x) {
			creature.setDirection(DIRECTION_EAST);
		} else if (oldPos.x > newPos.x) {
			creature.setDirection(DIRECTION_WEST);
		}
	}

	//send to client
	size_t i = 0;
	for (Creature* spectator : spectators) {
		if (Player* tmpPlayer = spectator->getPlayer()) {
			//Use the correct stackpos
			int32_t stackpos = oldStackPosVector[i++];
			if (stackpos != -1) {
				tmpPlayer->sendCreatureMove(&creature, newPos, newTile.getStackposOfCreature(tmpPlayer, &creature), oldPos, stackpos, teleport);
			}
		}
	}

	//event method
	for (Creature* spectator : spectators) {
		spectator->onCreatureMove(&creature, &newTile, newPos, &oldTile, oldPos, teleport);
	}

	oldTile.postRemoveNotification(&creature, &newTile, 0);
	newTile.postAddNotification(&creature, &oldTile, 0);
}

void Map::getSpectators(FastSpectatorVector& spectators, const Position& centerPos, bool multifloor /*= false*/, bool onlyPlayers /*= false*/, int32_t minRangeX /*= 0*/, int32_t maxRangeX /*= 0*/, int32_t minRangeY /*= 0*/, int32_t maxRangeY /*= 0*/)
{
	if (centerPos.z >= MAP_MAX_LAYERS) {
		return;
	}

	bool doUnique = !spectators.empty();

	minRangeX = (minRangeX == 0 ? -maxViewportX : -minRangeX);
	maxRangeX = (maxRangeX == 0 ? maxViewportX : maxRangeX);
	minRangeY = (minRangeY == 0 ? -maxViewportY : -minRangeY);
	maxRangeY = (maxRangeY == 0 ? maxViewportY : maxRangeY);

	int32_t minRangeZ;
	int32_t maxRangeZ;

	if (multifloor) {
		if (centerPos.z > 7) {
			//underground

			//8->15
			minRangeZ = std::max<int32_t>(centerPos.getZ() - 2, 0);
			maxRangeZ = std::min<int32_t>(centerPos.getZ() + 2, MAP_MAX_LAYERS - 1);
		} else if (centerPos.z == 6) {
			minRangeZ = 0;
			maxRangeZ = 8;
		} else if (centerPos.z == 7) {
			minRangeZ = 0;
			maxRangeZ = 9;
		} else {
			minRangeZ = 0;
			maxRangeZ = 7;
		}
	} else {
		minRangeZ = centerPos.z;
		maxRangeZ = centerPos.z;
	}

	int_fast16_t min_y = centerPos.y + minRangeY;
	int_fast16_t min_x = centerPos.x + minRangeX;
	int_fast16_t max_y = centerPos.y + maxRangeY;
	int_fast16_t max_x = centerPos.x + maxRangeX;

	int32_t minoffset = centerPos.getZ() - maxRangeZ;
	uint16_t x1 = std::min<uint32_t>(0xFFFF, std::max<int32_t>(0, (min_x + minoffset)));
	uint16_t y1 = std::min<uint32_t>(0xFFFF, std::max<int32_t>(0, (min_y + minoffset)));

	int32_t maxoffset = centerPos.getZ() - minRangeZ;
	uint16_t x2 = std::min<uint32_t>(0xFFFF, std::max<int32_t>(0, (max_x + maxoffset)));
	uint16_t y2 = std::min<uint32_t>(0xFFFF, std::max<int32_t>(0, (max_y + maxoffset)));

	int32_t startx1 = x1 - (x1 % FLOOR_SIZE);
	int32_t starty1 = y1 - (y1 % FLOOR_SIZE);
	int32_t endx2 = x2 - (x2 % FLOOR_SIZE);
	int32_t endy2 = y2 - (y2 % FLOOR_SIZE);

	for (int_fast32_t ny = starty1; ny <= endy2; ny += FLOOR_SIZE) {
		for (int_fast32_t nx = startx1; nx <= endx2; nx += FLOOR_SIZE) {
			QTreeLeafNode* leaf = root.getLeaf(nx, ny);
			if (!leaf) {
				continue;
			}

			auto creatures = leaf->getSpectators().getCreatures();
			uint16_t capacity = leaf->getSpectators().getCapacity();
			for (uint16_t i = 0; i < capacity; ++i) {
				auto& it = creatures[i];
				if (!it.creature) {
					continue;
				}

				if (!it.player && onlyPlayers) {
					break;
				}

				if (minRangeZ > it.pos.z || maxRangeZ < it.pos.z) {
					continue;
				}

				int_fast16_t offsetZ = Position::getOffsetZ(centerPos, it.pos);
				if ((min_y + offsetZ) > it.pos.y || (max_y + offsetZ) < it.pos.y || (min_x + offsetZ) > it.pos.x || (max_x + offsetZ) < it.pos.x) {
					continue;
				}

				spectators.push_back(it.creature);
			}
		}
	}

	if (doUnique) {
		spectators.unique();
	}
}

bool Map::canThrowObjectTo(const Position& fromPos, const Position& toPos, bool checkLineOfSight /*= true*/,
                           int32_t rangex /*= Map::maxClientViewportX*/, int32_t rangey /*= Map::maxClientViewportY*/) const
{
	//z checks
	//underground 8->15
	//ground level and above 7->0
	if ((fromPos.z >= 8 && toPos.z < 8) || (toPos.z >= 8 && fromPos.z < 8)) {
		return false;
	}

	int32_t deltaz = Position::getDistanceZ(fromPos, toPos);
	if (deltaz > 2) {
		return false;
	}

	if ((Position::getDistanceX(fromPos, toPos) - deltaz) > rangex) {
		return false;
	}

	//distance checks
	if ((Position::getDistanceY(fromPos, toPos) - deltaz) > rangey) {
		return false;
	}

	if (!checkLineOfSight) {
		return true;
	}
	return isSightClear(fromPos, toPos, false);
}

bool Map::checkSightLine(const Position& fromPos, const Position& toPos) const
{
	if (fromPos == toPos) {
		return true;
	}

	Position start(fromPos.z > toPos.z ? toPos : fromPos);
	Position destination(fromPos.z > toPos.z ? fromPos : toPos);

	const int8_t mx = start.x < destination.x ? 1 : start.x == destination.x ? 0 : -1;
	const int8_t my = start.y < destination.y ? 1 : start.y == destination.y ? 0 : -1;

	int32_t A = Position::getOffsetY(destination, start);
	int32_t B = Position::getOffsetX(start, destination);
	int32_t C = -(A * destination.x + B * destination.y);

	while (start.x != destination.x || start.y != destination.y) {
		int32_t move_hor = std::abs(A * (start.x + mx) + B * (start.y) + C);
		int32_t move_ver = std::abs(A * (start.x) + B * (start.y + my) + C);
		int32_t move_cross = std::abs(A * (start.x + mx) + B * (start.y + my) + C);

		if (start.y != destination.y && (start.x == destination.x || move_hor > move_ver || move_hor > move_cross)) {
			start.y += my;
		}

		if (start.x != destination.x && (start.y == destination.y || move_ver > move_hor || move_ver > move_cross)) {
			start.x += mx;
		}

		const Tile* tile = getTile(start.x, start.y, start.z);
		if (tile && tile->hasProperty(CONST_PROP_BLOCKPROJECTILE)) {
			return false;
		}
	}

	// now we need to perform a jump between floors to see if everything is clear (literally)
	while (start.z != destination.z) {
		const Tile* tile = getTile(start.x, start.y, start.z);
		if (tile && tile->getThingCount() > 0) {
			return false;
		}

		start.z++;
	}

	return true;
}

bool Map::isSightClear(const Position& fromPos, const Position& toPos, bool floorCheck) const
{
	if (floorCheck && fromPos.z != toPos.z) {
		return false;
	}

	// Cast two converging rays and see if either yields a result.
	return checkSightLine(fromPos, toPos) || checkSightLine(toPos, fromPos);
}

const Tile* Map::canWalkTo(const Creature& creature, const Position& pos) const
{
	int32_t walkCache = creature.getWalkCache(pos);
	if (walkCache == 0) {
		return nullptr;
	} else if (walkCache == 1) {
		return getTile(pos.x, pos.y, pos.z);
	}

	//used for non-cached tiles
	Tile* tile = getTile(pos.x, pos.y, pos.z);
	if (creature.getTile() != tile) {
		if (!tile || tile->queryAdd(0, creature, 1, FLAG_PATHFINDING | FLAG_IGNOREFIELDDAMAGE) != RETURNVALUE_NOERROR) {
			return nullptr;
		}
	}
	return tile;
}

bool Map::getPathMatching(const Creature& creature, const Position& targetPos, std::vector<Direction>& dirList, const FrozenPathingConditionCall& pathCondition, const FindPathParams& fpp) const
{
    Position pos = creature.getPosition();
    Position endPos;
    const Position startPos = pos;

    int32_t bestMatch = 0;

    AStarNodes nodes(pos.x, pos.y);

    AStarNode* found = nullptr;
    while (fpp.maxSearchDist != 0 || nodes.getClosedNodes() < 100) {
        AStarNode* n = nodes.getBestNode();
        if (!n) {
            if (found) {
                break;
            }
            return false;
        }

        const int_fast32_t x = n->x;
        const int_fast32_t y = n->y;
        pos.x = x;
        pos.y = y;
        if (pathCondition(startPos, pos, fpp, bestMatch)) {
            found = n;
            endPos = pos;
            if (bestMatch == 0) {
                break;
            }
        }

        uint_fast32_t dirCount;
        int_fast32_t* neighbors;
        if (n->parent) {
            const int_fast32_t offset_x = n->parent->x - x;
            const int_fast32_t offset_y = n->parent->y - y;
            if (offset_y == 0) {
                if (offset_x == -1) {
                    neighbors = *dirNeighbors[DIRECTION_WEST];
                }
                else {
                    neighbors = *dirNeighbors[DIRECTION_EAST];
                }
            }
            else if (!fpp.allowDiagonal || offset_x == 0) {
                if (offset_y == -1) {
                    neighbors = *dirNeighbors[DIRECTION_NORTH];
                }
                else {
                    neighbors = *dirNeighbors[DIRECTION_SOUTH];
                }
            }
            else if (offset_y == -1) {
                if (offset_x == -1) {
                    neighbors = *dirNeighbors[DIRECTION_NORTHWEST];
                }
                else {
                    neighbors = *dirNeighbors[DIRECTION_NORTHEAST];
                }
            }
            else if (offset_x == -1) {
                neighbors = *dirNeighbors[DIRECTION_SOUTHWEST];
            }
            else {
                neighbors = *dirNeighbors[DIRECTION_SOUTHEAST];
            }
            dirCount = fpp.allowDiagonal ? 5 : 3;
        }
        else {
            dirCount = 8;
            neighbors = *allNeighbors;
        }

        for (uint_fast32_t i = 0; i < dirCount; ++i) {
            pos.x = x + *neighbors++;
            pos.y = y + *neighbors++;

            if (fpp.maxSearchDist != 0 && (Position::getDistanceX(startPos, pos) > fpp.maxSearchDist || Position::getDistanceY(startPos, pos) > fpp.maxSearchDist)) {
                continue;
            }

            if (fpp.keepDistance && !pathCondition.isInRange(startPos, pos, fpp)) {
                continue;
            }

            const Tile* tile;
            AStarNode* neighborNode = nodes.getNodeByPosition(pos.x, pos.y);
            if (neighborNode) {
                tile = getTile(pos.x, pos.y, pos.z);
            }
            else {
                tile = canWalkTo(creature, pos);
                if (!tile) {
                    continue;
                }
            }

            //The cost to walk to this neighbor
            const int_fast32_t G = AStarNodes::getMapWalkCost(n, pos);
            const int_fast32_t E = AStarNodes::getTileWalkCost(creature, tile);
            const int_fast32_t H = (Position::getDistanceX(pos, targetPos) + Position::getDistanceY(pos, targetPos));
            int_fast32_t newf = G + (H + E);

            if (neighborNode) {
                if (neighborNode->f <= newf) {
                    //The node on the closed/open list is cheaper than this one
                    continue;
                }

                neighborNode->f = newf;
                neighborNode->parent = n;
                nodes.openNode(neighborNode);
            }
            else {
                //Does not exist in the open/closed list, create a new node
                //g_game.addMagicEffect(pos, CONST_ME_TELEPORT);
                neighborNode = nodes.createOpenNode(n, pos.x, pos.y, newf);
                if (!neighborNode) {
                    if (found) {
                        break;
                    }
                    return false;
                }
            }
        }

        nodes.closeNode(n);
    }

    if (!found) {
        return false;
    }

    int_fast32_t prevx = endPos.x;
    int_fast32_t prevy = endPos.y;

    found = found->parent;
    while (found) {
        pos.x = found->x;
        pos.y = found->y;

        int_fast32_t dx = pos.getX() - prevx;
        int_fast32_t dy = pos.getY() - prevy;

        prevx = pos.x;
        prevy = pos.y;

        if (dx == 1 && dy == 1) {
            dirList.push_back(DIRECTION_NORTHWEST);
        }
        else if (dx == -1 && dy == 1) {
            dirList.push_back(DIRECTION_NORTHEAST);
        }
        else if (dx == 1 && dy == -1) {
            dirList.push_back(DIRECTION_SOUTHWEST);
        }
        else if (dx == -1 && dy == -1) {
            dirList.push_back(DIRECTION_SOUTHEAST);
        }
        else if (dx == 1) {
            dirList.push_back(DIRECTION_WEST);
        }
        else if (dx == -1) {
            dirList.push_back(DIRECTION_EAST);
        }
        else if (dy == 1) {
            dirList.push_back(DIRECTION_NORTH);
        }
        else if (dy == -1) {
            dirList.push_back(DIRECTION_SOUTH);
        }

        found = found->parent;
    }
    return true;
}

uint32_t Map::clean() const
{
	uint64_t start = OTSYS_TIME();
	size_t count = 0, tiles = 0;

	if (g_game.getGameState() == GAME_STATE_NORMAL) {
		g_game.setGameState(GAME_STATE_MAINTAIN);
	}

	std::vector<Item*> toRemove;
	for (int x = 0; x < 1024; ++x) {
		for (int y = 0; y < 1024; ++y) {
			auto& node = root.nodes[x][y];
			for (int i = 0; i < node.count; ++i) {
				for (uint8_t z = 0; z < MAP_MAX_LAYERS; ++z) {
					Floor *floor = node.nodes[i].getFloor(z);
					if (!floor) {
						continue;
					}

					for (auto &row : floor->tiles) {
						for (auto tile : row) {
							if (!tile
									|| dynamic_cast<HouseTile*>(tile)
									|| tile->getItemCount() == 0
									|| tile->hasFlag(TILESTATE_TELEPORT)
									|| tile->hasFlag(TILESTATE_FLOORCHANGE)
									|| tile->hasFlag(TILESTATE_DEPOT)
									|| tile->hasProperty(CONST_PROP_BLOCKPROJECTILE)) {
								continue;
							}

							++tiles;

							for (Item *item : *tile->getItemList()) {
								if (item->isCleanable()) {
									toRemove.push_back(item);
								}
							}

							for (Item *item : toRemove) {
								g_game.internalRemoveItem(item, -1);
							}

							count += toRemove.size();
							toRemove.clear();
						}
					}
				}
			}
		}
	}

	if (g_game.getGameState() == GAME_STATE_MAINTAIN) {
		g_game.setGameState(GAME_STATE_NORMAL);
	}

	std::cout << "> CLEAN: Removed " << count << " item" << (count != 1 ? "s" : "")
			  << " from " << tiles << " tile" << (tiles != 1 ? "s" : "") << " in "
			  << (OTSYS_TIME() - start) / (1000.) << " seconds." << std::endl;
	return count;
}

// AStarNodes

AStarNodes::AStarNodes(uint32_t x, uint32_t y)
	: nodes(), openNodes()
{
	curNode = 1;
	closedNodes = 0;
	openNodes[0] = true;

	AStarNode& startNode = nodes[0];
	startNode.parent = nullptr;
	startNode.x = x;
	startNode.y = y;
	startNode.f = 0;
	nodeTable[(x << 16) | y] = nodes;
}

AStarNode* AStarNodes::createOpenNode(AStarNode* parent, uint32_t x, uint32_t y, int_fast32_t f, int_fast32_t g)
{
	if (curNode >= MAX_NODES) {
		return nullptr;
	}

	size_t retNode = curNode++;
	openNodes[retNode] = true;

	AStarNode* node = nodes + retNode;
	nodeTable[(x << 16) | y] = node;
	node->parent = parent;
	node->x = x;
	node->y = y;
	node->f = f;
	node->g = g;
	return node;
}

AStarNode* AStarNodes::getBestNode()
{
	int32_t best_node_f = std::numeric_limits<int32_t>::max();
	int32_t best_node = -1;
	for (size_t i = 0; i < curNode; i++) {
		if (!openNodes[i]) {
			continue;
		}
		
		int32_t cost = nodes[i].f + nodes[i].g;
		if (cost < best_node_f) {
			best_node_f = cost;
			best_node = i;
		}
	}

	if (best_node >= 0) {
		return nodes + best_node;
	}
	return nullptr;
}

void AStarNodes::closeNode(AStarNode* node)
{
	size_t index = node - nodes;
	assert(index < MAX_NODES);
	openNodes[index] = false;
	++closedNodes;
}

void AStarNodes::openNode(AStarNode* node)
{
	size_t index = node - nodes;
	assert(index < MAX_NODES);
	if (!openNodes[index]) {
		openNodes[index] = true;
		--closedNodes;
	}
}

int_fast32_t AStarNodes::getClosedNodes() const
{
	return closedNodes;
}

AStarNode* AStarNodes::getNodeByPosition(uint32_t x, uint32_t y)
{
	auto it = nodeTable.find((x << 16) | y);
	if (it == nodeTable.end()) {
		return nullptr;
	}
	return it->second;
}

int_fast32_t AStarNodes::getMapWalkCost(AStarNode* node, const Position& neighborPos)
{
	if (std::abs(node->x - neighborPos.x) == std::abs(node->y - neighborPos.y)) {
		//diagonal movement extra cost
		return MAP_DIAGONALWALKCOST;
	}
	return MAP_NORMALWALKCOST;
}

int_fast32_t AStarNodes::getTileWalkCost(const Creature& creature, const Tile* tile)
{
	int_fast32_t cost = 0;
	if (tile->getTopVisibleCreature(&creature) != nullptr) {
		//destroy creature cost
		cost += MAP_NORMALWALKCOST * 3;
	}

	if (const MagicField* field = tile->getFieldItem()) {
		CombatType_t combatType = field->getCombatType();
		if (!creature.isImmune(combatType) && !creature.hasCondition(Combat::DamageToConditionType(combatType))) {
			cost += MAP_NORMALWALKCOST * 18;
		}
	}
	return cost;
}

// Floor
Floor::~Floor()
{
	for (auto& row : tiles) {
		for (auto tile : row) {
			delete tile;
		}
	}
}


void FastSpectatorHolder::add(Creature* creature, const Position& pos)
{
	if (count < capacity) {
		for (uint16_t i = index; i < capacity; ++i) {
			if (creatures[i].creature) {
				continue;
			}

			return _add(creature, pos, i);
		}

		for (uint16_t i = 0; i <= index; ++i) {
			if (creatures[i].creature) {
				continue;
			}

			return _add(creature, pos, i);
		}

		std::cout << count << " " << capacity << " " << index << std::endl;

		for (int i = 0; i < capacity; ++i) {
			std::cout << creatures[i].creature << std::endl;
		}

		throw "FastSpectatorHolder exception - count < capacity";
	}

	// resize and add
	SpectatorVector *newVec = new SpectatorVector[capacity * 2]{};
	for(uint16_t i = 0; i < capacity; ++i) {
		newVec[i] = creatures[i];
	}

	delete[] creatures;
	creatures = newVec;
	capacity *= 2;
	return _add(creature, pos, capacity / 2);
}

void FastSpectatorHolder::move(Creature* creature, const Position& pos)
{
	creatures[creature->getSpectatorId()].pos = pos;
}

void FastSpectatorHolder::remove(Creature* creature)
{
	uint16_t id = creature->getSpectatorId();
	if (creatures[id].player) {
		if (!creatures[player_index].creature) {
			player_index -= 1;
		}

		if (player_index != id) {
			std::swap(creatures[id], creatures[player_index]);
			creatures[id].creature->setSpectatorId(id);
			id = player_index;
		}

		player_index -= 1;
	}

	creatures[id].creature = nullptr;
	index = id;
	count -= 1;
	if (capacity != 2 && capacity > count * 2.5) {
		SpectatorVector *newVec = new SpectatorVector[capacity / 2]{};
		for (uint16_t i = 0; i < capacity / 2; ++i) {
			if (creatures[i].creature) {
				newVec[i] = creatures[i];
			}
		}

		for (uint16_t i = capacity / 2, j = 0; i < capacity; ++i) {
			if (!creatures[i].creature) {
				continue;
			}

			while (newVec[j].creature) {
				j += 1;
			}

			newVec[j] = creatures[i];
			newVec[j].creature->setSpectatorId(j);
		}

		index = 0;
		delete[] creatures;
		creatures = newVec;
		capacity /= 2;
	}
}

void FastSpectatorHolder::_add(Creature* creature, const Position& pos, uint16_t i)
{
	creatures[i].creature = creature;
	creatures[i].pos = pos;
	creatures[i].player = creature->getPlayer() ? true : false;
	index = (i + 1) % capacity;
	count += 1;

	if (creatures[i].player) {
		player_index += 1;
		std::swap(creatures[i], creatures[player_index]);
		if (creatures[i].creature) {
			creatures[i].creature->setSpectatorId(i);
		}

		creature->setSpectatorId(player_index);
	} else {
		creature->setSpectatorId(i);
	}
}