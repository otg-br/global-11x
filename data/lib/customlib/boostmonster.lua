if not boostCreature then 
    boostCreature = {} 
end

BoostedCreature = {
    db = true,
    monsters = {
        normal = {
            "war wolf", "orc", "orc shaman", "orc warrior", "orc berserker",
            "necromancer", "hunter", "black sheep", "sheep", "troll",
            "bear", "bonelord", "ghoul", "slime", "squidgy slime",
            "rat", "cyclops", "minotaur mage", "minotaur archer", "minotaur",
            "rotworm", "wolf", "snake", "spider", "deer", "dog",
            "skeleton", "poison spider", "demon skeleton", "fire devil",
            "lion", "polar bear", "scorpion", "wasp", "bug",
            "wild warrior", "fire elemental", "orc spearman", "winter wolf",
            "witch", "monk", "priestess", "orc leader", "pig", "goblin",
            "elf", "elf scout", "dwarf geomancer", "stone golem", "vampire",
            "dwarf", "dwarf soldier", "stalker", "amazon", "cobra",
            "larva", "scarab", "hyaena", "gargoyle"
        },
        second = {
            "orc warlord", "dwarf guard", "mummy", "ancient scarab",
            "minotaur guard", "dragon", "poison spider", "demon skeleton",
            "giant spider", "fire devil", "hero", "lich",
            "bonebeast", "black knight", "pirate ghost", "dragon hatchling",
            "dragon lord hatchling", "haunted treeling", "wailing widow",
            "spectre", "diabolic imp", "wyvern", "hellfire fighter",
            "frost torog", "vampire bride", "werewolf", "nightstalker"
        },
        third = {
            "warlock", "demon", "frost dragon", "dragon lord", "stampor",
            "stone rhino", "uruloki", "behemoth", "hydra", "undead dragon",
            "serpent spawn", "terminator", "juggernaut", "oxyurus",
            "medusa", "bloodboil", "solarian", "shade of akama",
            "guzzlemaw", "frazzlemaw", "burning book", "icecold book",
            "cursed book", "energetic book", "werelion", "werelioness",
            "white lion", "gazer spectre", "burster spectre",
            "ripper spectre", "shadow spectre", "draken warmaster",
            "draken elite", "dark torturer", "gravedigger", "ironblight",
            "elder wyrm", "shock head", "silencer", "retching horror",
            "dawnfire asura", "midnight asura", "ogre brute",
            "rage squid", "squid warden", "cobra assassin",
            "cobra scout", "glooth anemone", "blood beast", "enyd",
            "allukard", "ogre shaman", "true midnight asura",
            "falcon knight", "thanatursus", "crazed summer vanguard",
            "soul-broken harbinger", "insane siren", "cobra vizier",
            "flimsy lost soul"
        },
        boss = {
			"ferumbras", "ghazbaran", "morgaroth", "orshabaal", "the handmaiden",
			"demodras", "dharalion", "the imperor", "the old widow", "the plasmother",
			"the maw", "bragrumol", "deathstrike", "the welter", "the many",
			"zushuka", "zavarash", "zamulosh", "zugurosh", "mawhawk",
			"tanjis", "jaul", "shardhead", "esmeralda", "leviathan",
			"kerberos", "ethershreck", "ocyakao", "necropharus", "the horned fox",
			"the evil eye", "the pale count", "massacre", "dracola", "zoralurk",
			"hairman the huge", "hellgorak", "bibby bloodbath", "grimgor guteater",
			"rocky", "tirecz", "bazir", "zomba", "countess sorrow", "mr. punish",
			"the abomination", "the pit lord", "the voice of ruin", "grand master oberon",
			"scarlett etzel", "the lord of the elements", "black bert", "undead cavebear"
		}
    },
    bonuses = {
        normal = { exp = {min = 30, max = 30}, loot = {min = 15, max = 45} },
        second = { exp = {min = 30, max = 30}, loot = {min = 15, max = 45} },
        third = { exp = {min = 30, max = 30}, loot = {min = 15, max = 45} },
        boss = { exp = {min = 30, max = 30}, loot = {min = 15, max = 45} }
    },
    positions = {
        normal = Position(32367, 32232, 7),
        second = Position(32369, 32232, 7),
        third = Position(32371, 32232, 7),
        boss = Position(32373, 32232, 7)
    },
    messages = {
        normal = "The chosen creature is %s. When killed, you receive +%d experience and +%d loot.",
        second = "The second chosen creature is %s. When killed, you receive +%d experience and +%d loot.",
        third = "The third chosen creature is %s. When killed, you receive +%d experience and +%d loot.",
        boss = "The boss chosen creature is %s. When killed, you receive +%d experience and +%d loot."
    }
}

function BoostedCreature:start()
    local rand = math.random
    boostCreature = {}
    for category, monsterList in pairs(self.monsters) do
        local monsterRand = monsterList[rand(#monsterList)]
        local expRand = rand(self.bonuses[category].exp.min, self.bonuses[category].exp.max)
        local lootRand = rand(self.bonuses[category].loot.min, self.bonuses[category].loot.max)
        table.insert(boostCreature, {name = monsterRand:lower(), exp = expRand, loot = lootRand, category = category})
        local monster = Game.createMonster(boostCreature[#boostCreature].name, self.positions[category], false, true)
        if monster then
            monster:setDirection(SOUTH)
        else
            print(string.format("Failed to create monster: %s", boostCreature[#boostCreature].name))
        end
        print(string.format(self.messages[category], monsterRand, expRand, lootRand))
    end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end