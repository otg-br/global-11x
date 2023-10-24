--[[
	TODO
		Unite all related variables / functions in a table
		rewrite functions like "getTasksByPlayer" to "Player.getTasks"
]]

RANK_NONE = 0
RANK_JOIN = 1
RANK_HUNTSMAN = 2
RANK_RANGER = 3
RANK_BIGGAMEHUNTER = 4
RANK_TROPHYHUNTER = 5
RANK_ELITEHUNTER = 6

REWARD_MONEY = 1
REWARD_EXP = 2
REWARD_ACHIEVEMENT = 3
REWARD_STORAGE = 4
REWARD_POINT = 5
REWARD_ITEM = 6

QUESTSTORAGE_BASE = 1500
JOIN_STOR = 100157
KILLSSTORAGE_BASE = 65000
REPEATSTORAGE_BASE = 48950
POINTSSTORAGE = 2500
tasks =
{
	[1] = {killsRequired = 100, raceName = "Trolls", level = {6, 999}, premium = true, creatures = {"troll", "troll champion", "island troll", "swamp troll"}, rewards = {{type = "exp", value = {200}},{type = "money", value = {200}}}},
    [2] = {killsRequired = 150, raceName = "Goblins", level = {6, 999}, premium = true, creatures = {"goblin", "goblin assassin", "goblin leader"}, rewards = {{type = "exp", value = {300}},{type = "money", value = {250}}}},
	[3] = {killsRequired = 300, raceName = "Crocodiles", level = {6, 999}, bossName = "The Snapper", bossStorage = 35000, premium = true, creatures = {"crocodile"}, rewards = {{type = "exp", value = {800}},{type = "achievement", value = {"Blood-Red Snapper"}},{type = "storage", value = {34100, 1}},{type = "points", value = {1}}}},
	[4] = {killsRequired = 300, raceName = "Badgers", level = {6, 999}, premium = true, creatures = {"badger"}, rewards = {{type = "exp", value = {500}},{type = "points", value = {1}}}},
	[5] = {killsRequired = 300, raceName = "Tarantulas", level = {6, 999}, bossName = "Hide", bossStorage = 35001, premium = true, creatures = {"tarantula"}, rewards = {{type = "exp", value = {1500}},{type = "achievement", value = {"No More Hiding"}},{type = "storage", value = {34101, 1}},{type = "points", value = {2}}}},
	[6] = {killsRequired = 150, raceName = "Carniphilas", level = {6, 999}, bossName = "Deathbine", bossStorage = 35002, premium = true, creatures = {"carniphila"}, rewards = {{type = "exp", value = {2500}},{type = "achievement", value = {"Rootless Behaviour"}},{type = "storage", value = {34102, 1}},{type = "points", value = {3}}}},
	[7] = {killsRequired = 200, raceName = "Stone Golems", level = {6, 999}, premium = true, creatures = {"stone golem"}, rewards = {{type = "exp", value = {2000}},{type = "points", value = {3}}}},
	[8] = {killsRequired = 300, raceName = "Mammoths", level = {6, 999}, bossName = "The Bloodtusk", bossStorage = 35003, premium = true, creatures = {"mammoth"}, rewards = {{type = "exp", value = {4000}},{type = "achievement", value = {"Meat Skewer"}},{type = "storage", value = {34103, 1}},{type = "points", value = {3}}}},
	[9] = {killsRequired = 300, raceName = "Gnarlhounds", level = {6, 999}, premium = true, creatures = {"gnarlhound"}, rewards = {{type = "exp", value = {1000}},{type = "points", value = {2}}}},
	[10] = {killsRequired = 300, raceName = "Terramites", level = {6, 999}, premium = true, creatures = {"terramite"}, rewards = {{type = "exp", value = {1000}},{type = "points", value = {2}}}},
	[11] = {killsRequired = 300, raceName = "Apes", level = {6, 999}, premium = true, creatures = {"kongra", "sibang", "merklin"}, rewards = {{type = "exp", value = {1000}},{type = "points", value = {2}}}},
	[12] = {killsRequired = 300, raceName = "Thornback Tortoises", level = {6, 999}, premium = true, creatures = {"thornback tortoise"}, rewards = {{type = "exp", value = {1500}},{type = "points", value = {2}}}},
	[13] = {killsRequired = 300, raceName = "Gargoyles", level = {6, 999}, premium = true, creatures = {"gargoyle"}, rewards = {{type = "exp", value = {1500}}}},
	[14] = {killsRequired = 300, raceName = "Ice Golems", level = {50, 999}, bossName = "Shardhead", bossStorage = 35004, premium = true, creatures = {"ice golem"}, rewards = {{type = "exp", value = {12000}},{type = "achievement", value = {"Breaking The Ice"}},{type = "storage", value = {34104, 1}},{type = "points", value = {2}}}},
	[15] = {killsRequired = 400, raceName = "Quara Scouts", level = {50, 999}, premium = true, creatures = {"quara pincher scout", "quara predator scout", "quara hydromancer scout", "quara constrictor scout", "quara mantassin scout"}, rewards = {{type = "exp", value = {10000}},{type = "points", value = {2}}}},
	[16] = {killsRequired = 400, raceName = "Mutated Rats", level = {50, 999}, bossName = "Esmerelda", bossStorage = 35005, premium = true, creatures = {"mutated rat"}, rewards = {{type = "exp", value = {10000}},{type = "achievement", value = {"Twisted Mutation"}},{type = "storage", value = {34105, 1}},{type = "points", value = {2}}}},
	[17] = {killsRequired = 250, raceName = "Ancient Scarabs", level = {50, 999}, bossName = "Fleshcrawler", bossStorage = 35006, premium = true, creatures = {"ancient scarab"}, rewards = {{type = "exp", value = {15000}},{type = "achievement", value = {"Crawling Death"}},{type = "storage", value = {34106, 1}},{type = "points", value = {2}}}},
	[18] = {killsRequired = 300, raceName = "Wyverns", level = {50, 999}, premium = true, creatures = {"wyvern"}, rewards = {{type = "exp", value = {12000}},{type = "points", value = {2}}}},
	[19] = {killsRequired = 300, raceName = "Lancer Beetles", level = {50, 999}, premium = true, creatures = {"lancer beetle"}, rewards = {{type = "exp", value = {8000}},{type = "points", value = {2}}}},
	[20] = {killsRequired = 400, raceName = "Wailing Widows", level = {50, 999}, premium = true, creatures = {"wailing widow"}, rewards = {{type = "exp", value = {12000}},{type = "points", value = {3}}}},
	[21] = {killsRequired = 250, raceName = "Killer Caimans", level = {50, 999}, premium = true, creatures = {"killer caiman"}, rewards = {{type = "exp", value = {10000}},{type = "points", value = {2}}}},
	[22] = {killsRequired = 300, raceName = "Bonebeasts", level = {50, 999}, bossName = "Ribstride", bossStorage = 35007, premium = true, creatures = {"bonebeast"}, rewards = {{type = "exp", value = {12000}},{type = "achievement", value = {"Spareribs for Dinner"}},{type = "storage", value = {34107, 1}},{type = "points", value = {2}}}},
	[23] = {killsRequired = 300, raceName = "Crystal Spiders", level = {50, 999}, bossName = "Bloodweb", bossStorage = 35008, creatures = {"crystal spider"}, premium = true, rewards = {{type = "exp", value = {15000}},{type = "achievement", value = {"Arachnoise"}},{type = "storage", value = {34108, 1}},{type = "points", value = {3}}}},
	[24] = {killsRequired = 300, raceName = "Mutated Tigers", level = {50, 999}, premium = true, creatures = {"mutated tiger"}, rewards = {{type = "exp", value = {12000}},{type = "points", value = {2}}}},
	[25] = {killsRequired = 450, raceName = "Underwater Quara", level = {80, 999}, bossName = "Thul", bossStorage = 35009, premium = true, creatures = {"quara hydromancer", "quara predator", "quara constrictor", "quara mantassin", "quara pincher"}, rewards = {{type = "exp", value = {15000}},{type = "achievement", value = {"Back into the Abyss"}},{type = "storage", value = {34109, 1}},{type = "points", value = {3}}}},
	[26] = {killsRequired = 450, raceName = "Giant Spiders", level = {80, 999}, bossName = "The Old Widow", bossStorage = 35010, premium = true, creatures = {"giant spider"}, rewards = {{type = "exp", value = {20000}},{type = "achievement", value = {"Choking on Her Venom"}},{type = "storage", value = {34110, 1}},{type = "points", value = {3}}}},
	[27] = {killsRequired = 300, raceName = "Werewolves", level = {80, 999}, bossName = "Hemming", bossStorage = 35011, premium = true, creatures = {"werewolf"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Howly Silence"}},{type = "storage", value = {34111, 1}},{type = "points", value = {4}}}},
	[28] = {killsRequired = 400, raceName = "Nightmares", level = {80, 999}, bossName = "Tormentor", bossStorage = 35012, premium = true, creatures = {"nightmare", "nightmare scion"}, rewards = {{type = "exp", value = {25000}},{type = "achievement", value = {"Dream is Over"}},{type = "storage", value = {34112, 1}},{type = "points", value = {3}}}},
	[29] = {killsRequired = 450, raceName = "Hellspawns", level = {80, 999}, bossName = "Flameborn", bossStorage = 35013, premium = true, creatures = {"hellspawn"}, rewards = {{type = "exp", value = {25000}},{type = "achievement", value = {"Scorched Flames"}},{type = "storage", value = {34113, 1}}}},
	[30] = {killsRequired = 450, raceName = "High Class Lizards", level = {80, 999}, bossName = "Fazzrah", bossStorage = 35014, premium = true, creatures = {"lizard chosen", "lizard dragon priest", "lizard high guard", "lizard legionnaire"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Zzztill Zzztanding!"}},{type = "storage", value = {34114, 1}},{type = "points", value = {3}}}},
	[31] = {killsRequired = 450, raceName = "Stampors", level = {80, 999}, bossName = "Tromphonyte", bossStorage = 35015, premium = true, creatures = {"stampor"}, rewards = {{type = "exp", value = {20000}},{type = "achievement", value = {"Stepped on a Big Toe"}},{type = "storage", value = {34115, 1}},{type = "points", value = {3}}}},
	[32] = {killsRequired = 450, raceName = "Brimstone Bugs", level = {80, 999}, bossName = "Sulphur Scuttler", bossStorage = 35016, premium = true, creatures = {"brimstone bug"}, rewards = {{type = "exp", value = {15000}},{type = "achievement", value = {"Something Smells"}},{type = "storage", value = {34116, 1}},{type = "points", value = {3}}}},
	[33] = {killsRequired = 400, raceName = "Mutated Bats", level = {80, 999}, bossName = "Bruise Payne", bossStorage = 35017, premium = true, creatures = {"mutated bat"}, rewards = {{type = "exp", value = {20000}},{type = "achievement", value = {"Kapow!"}},{type = "storage", value = {34117, 1}},{type = "points", value = {2}}}},
	[34] = {killsRequired = 450, raceName = "Hydras", level = {130, 9999}, bossName = "The Many", bossStorage = 35018, premium = true, creatures = {"hydra"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"One Less"}},{type = "storage", value = {34118, 1}},{type = "points", value = {3}}}},
	[35] = {killsRequired = 450, raceName = "Serpent Spawns", level = {130, 9999}, bossName = "The Noxious Spawn", bossStorage = 35019, premium = true, creatures = {"serpent spawn"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Hissing Downfall"}},{type = "storage", value = {34119, 1}},{type = "points", value = {4}}}},
	[36] = {killsRequired = 450, raceName = "Medusas", level = {130, 9999}, bossName = "Gorgo", bossStorage = 35020, premium = true, creatures = {"medusa"}, rewards = {{type = "exp", value = {40000}},{type = "achievement", value = {"The Serpent's Bride"}},{type = "storage", value = {34120, 1}},{type = "points", value = {5}}}},
	[37] = {killsRequired = 450, raceName = "Behemoths", level = {130, 9999}, bossName = "Stonecracker", bossStorage = 35021, premium = true, creatures = {"behemoth"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Just Cracked Me Up!"}},{type = "storage", value = {34121, 1}},{type = "points", value = {4}}}},
	[38] = {killsRequired = 450, raceName = "Sea Serpents and Young Sea Serpents", level = {130, 9999}, bossName = "Leviathan", bossStorage = 35022, premium = true, creatures = {"sea serpent", "young sea serpent"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"The Drowned Sea God"}},{type = "storage", value = {34122, 1}},{type = "points", value = {4}}}},
	[39] = {killsRequired = 250, raceName = "Hellhounds", level = {130, 9999}, bossName = "Kerberos", bossStorage = 35023, premium = true, creatures = {"hellhound"}, rewards = {{type = "exp", value = {40000}},{type = "achievement", value = {"The Gates of Hell"}},{type = "storage", value = {34123, 1}},{type = "points", value = {5}}}},
	[40] = {killsRequired = 450, raceName = "Ghastly Dragons", level = {130, 9999}, bossName = "Ethershreck", bossStorage = 35024, premium = true, creatures = {"ghastly dragon"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Beautiful Agony"}},{type = "storage", value = {34124, 1}},{type = "points", value = {5}}}},
	[41] = {killsRequired = 450, raceName = "Drakens", level = {130, 9999}, bossName = "Paiz the Pauperizer", bossStorage = 35025, premium = true, creatures = {"draken spellweaver", "draken warmaster", "draken abomination", "draken elite"} , rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Enter zze Draken!"}},{type = "storage", value = {34125, 1}},{type = "points", value = {3}}}},
	[42] = {killsRequired = 450, raceName = "Destroyers", level = {130, 9999}, bossName = "Bretzecutioner", bossStorage = 35026, premium = true, creatures = {"destroyer"}, rewards = {{type = "exp", value = {30000}},{type = "achievement", value = {"Best there was!"}},{type = "storage", value = {34126, 1}},{type = "points", value = {4}}}},
	[43] = {killsRequired = 400, raceName = "Undead Dragons", level = {130, 9999}, bossName = "Zanakeph", bossStorage = 35027, premium = true, creatures = {"undead dragon"}, rewards = {{type = "exp", value = {50000}},{type = "achievement", value = {"Back from the Dead"}},{type = "storage", value = {34127, 1}},{type = "points", value = {6}}}},
	[44] = {killsRequired = 666, raceName = "Demons", level = {130, 9999}, premium = true, creatures = {"demon"}, rewards = {{type = "item", value = {10305, 1}},{type = "storage", value = {41300, 1}}}},
	[45] = {killsRequired = 450, raceName = "Green Djinns or Efreets", level = {1, 9999}, storage = {12500, 1}, premium = true, creatures = {"green djinn", "efreet"}, rewards = {{type = "exp", value = {10000}},{type = "money", value = {5000}},{type = "storage", value = {34128, 1}}}},
	[46] = {killsRequired = 450, raceName = "Blue Djinns or Marids", level = {1, 9999}, storage = {12501, 1}, premium = true, creatures = {"blue djinn", "marid"}, rewards = {{type = "exp", value = {10000}},{type = "money", value = {5000}},{type = "storage", value = {34129, 1}}}},
	[47] = {killsRequired = 300, raceName = "Pirates", level = {1, 9999}, storage = {65047, 1}, premium = true, creatures = {"pirate ghost", "pirate marauder", "pirate cutthroad", "pirate buccaneer", "pirate corsair", "pirate skeleton"}, rewards = {{type = "exp", value = {10000}},{type = "money", value = {5000}},{type = "storage", value = {17523, 1}}}},
	[48] = {killsRequired = 300, raceName = "Pirates second task", level = {1, 9999}, storage = {REPEATSTORAGE_BASE + 47, 3}, norepeatable = true, premium = true, creatures = {"pirate ghost", "pirate marauder", "pirate cutthroad", "pirate buccaneer", "pirate corsair", "pirate skeleton"}, rewards = {{type = "exp", value = {10000}},{type = "money", value = {5000}},{type = "storage", value = {17523, 1}}}},
	[49] = {killsRequired = 450, raceName = "Minotaurs", level = {1, 9999}, storage = {12700, 1}, norepeatable = true, premium = false, creatures = {"minotaur", "minotaur mage", "minotaur archer", "minotaur guard", "minotaur cult zealot", "minotaur cult prophet", "minotaur cult follower"}, rewards = {{type = "storage", value = {17522, 1}}}},
	-- [50] = {killsRequired = 400, raceName = "Necromancers and Priestess", level = {60, 9999}, norepeatable = true, premium = true, creatures = {"necromancer", "priestess"}, rewards = {{type = "storage", value = {34133, 1}},{type = "storage", value = {17521, 1}}}},
}

tasksByPlayer = 3
repeatTimes = 3

function Player.getPawAndFurRank(self)
	return (self:getStorageValue(POINTSSTORAGE) >= 100 and RANK_ELITEHUNTER or self:getStorageValue(POINTSSTORAGE) >= 70 and RANK_TROPHYHUNTER or self:getStorageValue(POINTSSTORAGE) >= 40 and RANK_BIGGAMEHUNTER or self:getStorageValue(POINTSSTORAGE) >= 20 and RANK_RANGER or self:getStorageValue(POINTSSTORAGE) >= 10 and RANK_HUNTSMAN or self:getStorageValue(JOIN_STOR) == 1 and RANK_JOIN or RANK_NONE)
end

function Player.getPawAndFurPoints(self)
	return math.max(self:getStorageValue(POINTSSTORAGE), 0)
end

function getTaskByName(name, table)
	local t = (table and table or tasks)
	for k, v in pairs(t) do
		if v.name then
			if v.name:lower() == name:lower() then
				return k
			end
		else
			if v.raceName:lower() == name:lower() then
				return k
			end
		end
	end
	return false
end

function Player.getTasks(self)
	local canmake = {}
	local able = {}
	for k, v in pairs(tasks) do
		if self:getStorageValue(QUESTSTORAGE_BASE + k) < 1 and self:getStorageValue(REPEATSTORAGE_BASE + k) < repeatTimes then
			able[k] = true
			if self:getLevel() < v.level[1] or self:getLevel() > v.level[2] then
				able[k] = false
			end
			if v.storage and self:getStorageValue(v.storage[1]) < v.storage[2] then
				able[k] = false
			end

			if v.rank then
				if self:getPawAndFurRank() < v.rank then
					able[k] = false
				end
			end

			if v.premium then
				if not self:isPremium() then
					able[k] = false
				end
			end

			if able[k] then
				canmake[#canmake + 1] = k
			end
		end
	end
	return canmake
end

function Player.canStartTask(self, name, table)
	local v = ""
	local id = 0
	local t = (table and table or tasks)
	for k, i in pairs(t) do
		if i.name then
			if i.name:lower() == name:lower() then
				v = i
				id = k
				break
			end
		else
			if i.raceName:lower() == name:lower() then
				v = i
				id = k
				break
			end
		end
	end
	if v == "" then
		return false
	end
	if self:getStorageValue(QUESTSTORAGE_BASE + id) > 0 then
		return false
	end
	if self:getStorageValue(REPEATSTORAGE_BASE +  id) >= repeatTimes or v.norepeatable and self:getStorageValue(REPEATSTORAGE_BASE +  id) > 0 then
		return false
	end
	if v.level and self:getLevel() >= v.level[1] and self:getLevel() <= v.level[2] then
		if v.premium then
			if self:isPremium() then
				if v.rank then
					if self:getPawAndFurRank() >= v.rank then
						if v.storage then
							if self:getStorageValue(v.storage[1]) >= v.storage then
								return true
							end
						else
							return true
						end
					end
				else
					return true
				end
			else
				return true
			end
		else
			return true
		end
	end
	return false
end

function Player.getStartedTasks(self)
	local tmp = {}
	for k, v in pairs(tasks) do
		if self:getStorageValue(QUESTSTORAGE_BASE + k) > 0 and self:getStorageValue(QUESTSTORAGE_BASE + k) < 2 then
			tmp[#tmp + 1] = k
		end
	end
	return tmp
end

--in case other scripts are using these functions, i'll let them here
function getPlayerRank(cid) local p = Player(cid) return p and p:getPawAndFurRank() end
function getPlayerTasksPoints(cid) local p = Player(cid) return p and p:getPawAndFurPoints() end
function getTasksByPlayer(cid) local p = Player(cid) return p and p:getTasks() end
function canStartTask(cid, name, table) local p = Player(cid) return p and p:canStartTask(name, table) end
function getPlayerStartedTasks(cid) local p = Player(cid) return p and p:getStartedTasks() end
