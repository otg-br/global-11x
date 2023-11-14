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

#ifndef FS_MAP_H_E3953D57C058461F856F5221D359DAFA
#define FS_MAP_H_E3953D57C058461F856F5221D359DAFA

#include "position.h"
#include "item.h"
#include "fileloader.h"

#include "tools.h"
#include "tile.h"
#include "town.h"
#include "house.h"
#include "spawn.h"

class Creature;
class Player;
class Game;
class Tile;
class Map;

static constexpr int32_t MAP_MAX_LAYERS = 16;

struct FindPathParams;
struct AStarNode {
	AStarNode* parent;
	int_fast32_t f, g;
	uint16_t x, y;
};

static constexpr int32_t MAX_NODES = 512;

static constexpr int32_t MAP_NORMALWALKCOST = 10;
static constexpr int32_t MAP_DIAGONALWALKCOST = 25;

static int_fast32_t dirNeighbors[8][5][2] = {
        {{-1, 0}, {0, 1}, {1, 0}, {1, 1}, {-1, 1}},
        {{-1, 0}, {0, 1}, {0, -1}, {-1, -1}, {-1, 1}},
        {{-1, 0}, {1, 0}, {0, -1}, {-1, -1}, {1, -1}},
        {{0, 1}, {1, 0}, {0, -1}, {1, -1}, {1, 1}},
        {{1, 0}, {0, -1}, {-1, -1}, {1, -1}, {1, 1}},
        {{-1, 0}, {0, -1}, {-1, -1}, {1, -1}, {-1, 1}},
        {{0, 1}, {1, 0}, {1, -1}, {1, 1}, {-1, 1}},
        {{-1, 0}, {0, 1}, {-1, -1}, {1, 1}, {-1, 1}}
};
static int_fast32_t allNeighbors[8][2] = {
    {-1, 0}, {0, 1}, {1, 0}, {0, -1}, {-1, -1}, {1, -1}, {1, 1}, {-1, 1}
};

class AStarNodes
{
	public:
		AStarNodes(uint32_t x, uint32_t y);

		AStarNode* createOpenNode(AStarNode* parent, uint32_t x, uint32_t y, int_fast32_t f, int_fast32_t g);
		AStarNode* getBestNode();
		void closeNode(AStarNode* node);
		void openNode(AStarNode* node);
		int_fast32_t getClosedNodes() const;
		AStarNode* getNodeByPosition(uint32_t x, uint32_t y);

		static int_fast32_t getMapWalkCost(AStarNode* node, const Position& neighborPos);
		static int_fast32_t getTileWalkCost(const Creature& creature, const Tile* tile);

	private:
		AStarNode nodes[MAX_NODES];
		bool openNodes[MAX_NODES];
		std::unordered_map<uint32_t, AStarNode*> nodeTable;
		size_t curNode;
		int_fast32_t closedNodes;
};

static constexpr int32_t FLOOR_BITS = 3;
static constexpr int32_t FLOOR_SIZE = (1 << FLOOR_BITS);
static constexpr int32_t FLOOR_MASK = (FLOOR_SIZE - 1);

struct Floor {
	Floor() : tiles() {}
	~Floor();

	// non-copyable
	Floor(const Floor&) = delete;
	Floor& operator=(const Floor&) = delete;

	Tile* tiles[FLOOR_SIZE][FLOOR_SIZE];
};

class FrozenPathingConditionCall;

/* Much faster modified version of spectators holder - FastSpectatorHolder by bbarwik@gmail.com */
class FastSpectatorHolder {
	public:
		struct SpectatorVector {
			Creature* creature = nullptr;
			Position pos;
			bool player = false;
		};

		FastSpectatorHolder() {
			creatures = new SpectatorVector[2]{};
			capacity = 2;
		}
		~FastSpectatorHolder() {
			delete[] creatures;
		}
		void add(Creature* creature, const Position& pos);
		void move(Creature* creature, const Position& pos);
		void remove(Creature* creature);

		const SpectatorVector* getCreatures() const {
			return creatures;
		}
		uint16_t getCapacity() const {
			return capacity;
		}
		uint16_t getCount() const {
			return count;
		}

	private:
		void _add(Creature* creature, const Position& pos, uint16_t i);

		SpectatorVector *creatures = nullptr;
		uint16_t index = 0, count = 0, capacity = 0, player_index = 0xFFFF;
};

class QTreeLeafNode {
	public:
		~QTreeLeafNode() {
			for (auto* ptr : array) {
				if (ptr) {
					delete ptr;
				}
			}
		}

		QTreeLeafNode& operator=(QTreeLeafNode&& o) {
			spectators = std::move(o.spectators);
			x = o.x;
			y = o.y;
			for (int i = 0; i < MAP_MAX_LAYERS; ++i) {
				array[i] = o.array[i];
				o.array[i] = nullptr;
			}
			return *this;
		}

		Floor* createFloor(uint32_t z) {
			if (!array[z]) {
				array[z] = new Floor();
			}

			return array[z];
		}

		Floor* getFloor(uint8_t z) const {
			return array[z];
		}

		void addCreature(Creature* c, const Position& pos) {
			spectators.add(c, pos);
		}

		void moveCreature(Creature* c, const Position& pos) {
			spectators.move(c, pos);
		}

		void removeCreature(Creature* c) {
			spectators.remove(c);
		}

		void setXY(uint16_t _x, uint16_t _y) {
			x = _x;
			y = _y;
		}

		uint16_t getX() const { return x; };
		uint16_t getY() const { return y; };

		const FastSpectatorHolder& getSpectators() const {
			return spectators;
		};

	private:
		Floor* array[MAP_MAX_LAYERS] = {nullptr};
		FastSpectatorHolder spectators;
		uint16_t x, y;

		friend class Map;
		friend class QTreeNode;
};

/* Much faster modified version of QTreeNode by bbarwik@gmail.com */
class QTreeNodeHashMap {
	public:
		QTreeLeafNode* getLeaf(uint16_t x, uint16_t y) const {
			x >>= FLOOR_BITS;
			y >>= FLOOR_BITS;
			const Node& node = nodes[x % 1024][y % 1024];
			if (!node.nodes) {
				return nullptr;
			}

			for (int i = 0; i < node.count; ++i) {
				if (node.nodes[i].getX() == x && node.nodes[i].getY() == y) {
					return &node.nodes[i];
				}
			}

			return nullptr;
		};

		QTreeLeafNode* createLeaf(uint16_t x, uint16_t y) {
			x >>= FLOOR_BITS;
			y >>= FLOOR_BITS;
			Node& node = nodes[x % 1024][y % 1024];
			if (!node.nodes) {
				node.nodes = new QTreeLeafNode[1];
				node.count = 1;
				node.nodes[0].setXY(x,y);
				return &node.nodes[0];
			}

			for (int i = 0; i < node.count; ++i) {
				if (node.nodes[i].getX() == x && node.nodes[i].getY() == y) {
					return &node.nodes[i];
				}
			}

			QTreeLeafNode* newNodes = new QTreeLeafNode[node.count + 1];
			for (int i = 0; i < node.count; ++i) {
				newNodes[i] = std::move(node.nodes[i]);
			}

			delete[] node.nodes;
			node.nodes = newNodes;
			node.count += 1;
			node.nodes[node.count - 1].setXY(x,y);
			return &node.nodes[node.count - 1];
		};

		struct Node {
			QTreeLeafNode* nodes = nullptr;
			int count = 0;
		} nodes[1024][1024];
};

/**
  * Map class.
  * Holds all the actual map-data
  */

class Map
{
	public:
		static constexpr int32_t maxViewportX = 18; //min value: maxClientViewportX + 1
		static constexpr int32_t maxViewportY = 18; //min value: maxClientViewportY + 1
		static constexpr int32_t maxClientViewportX = 15;
		static constexpr int32_t maxClientViewportY = 8;

		uint32_t clean() const;

		/**
		  * Load a map.
		  * \returns true if the map was loaded successfully
		  */
		bool loadMap(const std::string& identifier, bool loadHouses, const Position& relativePosition);

		/**
		  * Save a map.
		  * \returns true if the map was saved successfully
		  */
		static bool save();

		/**
		  * Get a single tile.
		  * \returns A pointer to that tile.
		  */
		Tile* getTile(uint16_t x, uint16_t y, uint8_t z) const;
		Tile* getTile(const Position& pos) const {
			return getTile(pos.x, pos.y, pos.z);
		}

		/**
		  * Set a single tile.
		  */
		void setTile(uint16_t x, uint16_t y, uint8_t z, Tile* newTile);
		void setTile(const Position& pos, Tile* newTile) {
			setTile(pos.x, pos.y, pos.z, newTile);
		}

		/**
		  * Place a creature on the map
		  * \param centerPos The position to place the creature
		  * \param creature Creature to place on the map
		  * \param extendedPos If true, the creature will in first-hand be placed 2 tiles away
		  * \param forceLogin If true, placing the creature will not fail becase of obstacles (creatures/chests)
		  */
		bool placeCreature(const Position& centerPos, Creature* creature, bool extendedPos = false, bool forceLogin = false);

		void moveCreature(Creature& creature, Tile& newTile, bool forceTeleport = false);
		void getSpectators(SpectatorVec& list, const Position& centerPos, bool multifloor = false, bool onlyPlayers = false, int32_t minRangeX = 0, int32_t maxRangeX = 0, int32_t minRangeY = 0, int32_t maxRangeY = 0);

		/**
		  * Checks if you can throw an object to that position
		  *	\param fromPos from Source point
		  *	\param toPos Destination point
		  *	\param rangex maximum allowed range horizontially
		  *	\param rangey maximum allowed range vertically
		  *	\param checkLineOfSight checks if there is any blocking objects in the way
		  *	\returns The result if you can throw there or not
		  */
		bool canThrowObjectTo(const Position& fromPos, const Position& toPos, bool checkLineOfSight = true,
		                      int32_t rangex = Map::maxClientViewportX, int32_t rangey = Map::maxClientViewportY) const;

		/**
		  * Checks if path is clear from fromPos to toPos
		  * Notice: This only checks a straight line if the path is clear, for path finding use getPathTo.
		  *	\param fromPos from Source point
		  *	\param toPos Destination point
		  *	\param floorCheck if true then view is not clear if fromPos.z is not the same as toPos.z
		  *	\returns The result if there is no obstacles
		  */
		bool isSightClear(const Position& fromPos, const Position& toPos, bool floorCheck) const;
		bool checkSightLine(const Position& fromPos, const Position& toPos) const;

		const Tile* canWalkTo(const Creature& creature, const Position& pos) const;

		bool getPathMatching(const Creature& creature, const Position& targetPos, std::vector<Direction>& dirList,
                             const FrozenPathingConditionCall& pathCondition, const FindPathParams& fpp) const;


		std::map<std::string, Position> waypoints;

		QTreeLeafNode* getQTNode(uint16_t x, uint16_t y) {
			return root.getLeaf(x, y);
		}

		Spawns spawns;
		Towns towns;
		Houses houses;

	private:
		QTreeNodeHashMap root;

		std::string spawnfile;
		std::string housefile;

		uint32_t width = 0;
		uint32_t height = 0;

		friend class Game;
		friend class IOMap;
};

#endif