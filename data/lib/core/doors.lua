local DOOR ={}


VERTICAL = 0
HORIZONTAL = 1

local newdoors = {
	{close = 1209, open = 1211, type = VERTICAL},
	{close = 1210, open = 1211, type = VERTICAL},
	{close = 1212, open = 1214, type = HORIZONTAL},
	{close = 1213, open = 1214, type = HORIZONTAL},

	{close = 1219, open = 1220, type = VERTICAL},
	{close = 1221, open = 1222, type = HORIZONTAL},
	{close = 1223, open = 1224, type = VERTICAL, isQuestDoor = true},
	{close = 1225, open = 1226, type = HORIZONTAL, isQuestDoor = true},
	{close = 1227, open = 1228, type = VERTICAL, isLevelDoor = true},
	{close = 1229, open = 1230, type = HORIZONTAL, isLevelDoor = true},
	{close = 1231, open = 1233, type = VERTICAL},
	{close = 1232, open = 1233, type = VERTICAL},
	{close = 1234, open = 1236, type = HORIZONTAL},
	{close = 1235, open = 1236, type = HORIZONTAL},
	{close = 1237, open = 1238, type = VERTICAL},
	{close = 1239, open = 1240, type = HORIZONTAL},
	{close = 1241, open = 1242, type = VERTICAL, isQuestDoor = true},
	{close = 1243, open = 1244, type = HORIZONTAL, isQuestDoor = true},
	{close = 1245, open = 1246, type = VERTICAL, isLevelDoor = true},
	{close = 1247, open = 1248, type = HORIZONTAL, isLevelDoor = true},
	{close = 1249, open = 1251, type = VERTICAL},
	{close = 1250, open = 1251, type = VERTICAL},
	{close = 1252, open = 1254, type = HORIZONTAL},
	{close = 1253, open = 1254, type = HORIZONTAL},
	{close = 1255, open = 1256, type = VERTICAL, isQuestDoor = true},
	{close = 1257, open = 1258, type = HORIZONTAL, isQuestDoor = true},
	{close = 1259, open = 1260, type = VERTICAL, isLevelDoor = true},
	{close = 1261, open = 1262, type = HORIZONTAL, isLevelDoor = true},

	{close = 1539, open = 1540, type = VERTICAL},
	{close = 1541, open = 1542, type = HORIZONTAL},

	{close = 3535, open = 3537, type = HORIZONTAL},
	{close = 3536, open = 3537, type = HORIZONTAL},
	{close = 3538, open = 3539, type = HORIZONTAL},

	{close = 3540, open = 3541, type = HORIZONTAL, isLevelDoor = true},
	{close = 3542, open = 3543, type = HORIZONTAL, isQuestDoor = true},

	{close = 3544, open = 3546, type = VERTICAL},
	{close = 3545, open = 3546, type = VERTICAL},
	{close = 3547, open = 3548, type = VERTICAL},
	{close = 3549, open = 3550, type = VERTICAL, isLevelDoor = true},
	{close = 3551, open = 3552, type = VERTICAL, isQuestDoor = true},

	{close = 4913, open = 4915, type = VERTICAL},
	{close = 4914, open = 4915, type = VERTICAL},
	{close = 4916, open = 4918, type = HORIZONTAL},
	{close = 4917, open = 4918, type = HORIZONTAL},

	{close = 5082, open = 5083, type = VERTICAL},
	{close = 5084, open = 5085, type = HORIZONTAL},

	{close = 5098, open = 5100, type = HORIZONTAL},
	{close = 5099, open = 5100, type = HORIZONTAL},
	{close = 5101, open = 5102, type = HORIZONTAL},
	{close = 5103, open = 5104, type = HORIZONTAL, isLevelDoor = true},
	{close = 5105, open = 5106, type = HORIZONTAL, isQuestDoor = true},

	{close = 5107, open = 5109, type = VERTICAL},
	{close = 5108, open = 5109, type = VERTICAL},
	{close = 5110, open = 5111, type = VERTICAL},
	{close = 5112, open = 5113, type = VERTICAL, isLevelDoor = true},
	{close = 5114, open = 5115, type = VERTICAL, isQuestDoor = true},

	{close = 5116, open = 5118, type = HORIZONTAL},
	{close = 5117, open = 5118, type = HORIZONTAL},
	{close = 5119, open = 5120, type = HORIZONTAL},
	{close = 5121, open = 5122, type = HORIZONTAL, isLevelDoor = true},
	{close = 5123, open = 5124, type = HORIZONTAL, isQuestDoor = true},

	{close = 5125, open = 5127, type = VERTICAL},
	{close = 5126, open = 5127, type = VERTICAL},
	{close = 5128, open = 5129, type = VERTICAL},
	{close = 5130, open = 5131, type = VERTICAL, isLevelDoor = true},
	{close = 5132, open = 5133, type = VERTICAL, isQuestDoor = true},

	{close = 5134, open = 5136, type = HORIZONTAL},
	{close = 5135, open = 5136, type = HORIZONTAL},
	{close = 5137, open = 5139, type = HORIZONTAL},
	{close = 5138, open = 5139, type = HORIZONTAL},
	{close = 5140, open = 5142, type = VERTICAL},
	{close = 5141, open = 5142, type = VERTICAL},
	{close = 5143, open = 5145, type = VERTICAL},
	{close = 5144, open = 5145, type = VERTICAL},

	{close = 5278, open = 5280, type = HORIZONTAL},
	{close = 5279, open = 5280, type = HORIZONTAL},
	{close = 5281, open = 5283, type = VERTICAL},
	{close = 5282, open = 5283, type = VERTICAL},
	{close = 5284, open = 5285, type = VERTICAL},
	{close = 5286, open = 5287, type = HORIZONTAL},
	{close = 5288, open = 5289, type = VERTICAL, isQuestDoor = true},
	{close = 5290, open = 5291, type = HORIZONTAL, isQuestDoor = true},
	{close = 5292, open = 5293, type = VERTICAL, isLevelDoor = true},
	{close = 5294, open = 5295, type = HORIZONTAL, isLevelDoor = true},

	{close = 5515, open = 5516, type = VERTICAL},
	{close = 5517, open = 5518, type = HORIZONTAL},

	{close = 5732, open = 5734, type = HORIZONTAL},
	{close = 5733, open = 5734, type = HORIZONTAL},
	{close = 5735, open = 5737, type = VERTICAL},
	{close = 5736, open = 5737, type = VERTICAL},

	{close = 5745, open = 5746, type = HORIZONTAL, isQuestDoor = true},
	{close = 5748, open = 5749, type = VERTICAL, isQuestDoor = true},

	{close = 6192, open = 6194, type = VERTICAL},
	{close = 6193, open = 6194, type = VERTICAL},
	{close = 6195, open = 6197, type = HORIZONTAL},
	{close = 6196, open = 6197, type = HORIZONTAL},
	{close = 6198, open = 6199, type = VERTICAL},
	{close = 6200, open = 6201, type = HORIZONTAL},
	{close = 6202, open = 6203, type = VERTICAL, isQuestDoor = true},
	{close = 6204, open = 6205, type = HORIZONTAL, isQuestDoor = true},
	{close = 6206, open = 6207, type = VERTICAL, isLevelDoor = true},
	{close = 6208, open = 6209, type = VERTICAL, isLevelDoor = true},

	{close = 6249, open = 6251, type = VERTICAL},
	{close = 6250, open = 6251, type = VERTICAL},
	{close = 6252, open = 6254, type = HORIZONTAL},
	{close = 6253, open = 6254, type = HORIZONTAL},
	{close = 6255, open = 6256, type = VERTICAL},
	{close = 6257, open = 6258, type = HORIZONTAL},
	{close = 6259, open = 6260, type = VERTICAL, isQuestDoor = true},
	{close = 6261, open = 6262, type = HORIZONTAL, isQuestDoor = true},
	{close = 6263, open = 6264, type = VERTICAL, isLevelDoor = true},
	{close = 6265, open = 6266, type = HORIZONTAL, isLevelDoor = true},

	{close = 6795, open = 6796, type = HORIZONTAL},
	{close = 6797, open = 6798, type = VERTICAL},
	{close = 6799, open = 6800, type = HORIZONTAL},
	{close = 6801, open = 6802, type = VERTICAL},

	{close = 6891, open = 6893, type = HORIZONTAL},
	{close = 6892, open = 6893, type = HORIZONTAL},
	{close = 6894, open = 6895, type = HORIZONTAL},
	{close = 6896, open = 6897, type = HORIZONTAL, isLevelDoor = true},
	{close = 6898, open = 6899, type = HORIZONTAL, isQuestDoor = true},

	{close = 6900, open = 6902, type = VERTICAL},
	{close = 6901, open = 6902, type = VERTICAL},
	{close = 6903, open = 6904, type = VERTICAL},
	{close = 6905, open = 6906, type = VERTICAL, isLevelDoor = true},
	{close = 6907, open = 6908, type = VERTICAL, isQuestDoor = true},

	{close = 7033, open = 7035, type = HORIZONTAL},
	{close = 7034, open = 7035, type = HORIZONTAL},
	{close = 7036, open = 7037, type = HORIZONTAL},
	{close = 7038, open = 7039, type = HORIZONTAL, isLevelDoor = true},
	{close = 7040, open = 7041, type = HORIZONTAL, isQuestDoor = true},

	{close = 7042, open = 7044, type = VERTICAL},
	{close = 7043, open = 7044, type = VERTICAL},
	{close = 7045, open = 7046, type = VERTICAL},
	{close = 7047, open = 7048, type = VERTICAL, isLevelDoor = true},
	{close = 7049, open = 7050, type = VERTICAL, isQuestDoor = true},

	{close = 7054, open = 7055, type = VERTICAL},
	{close = 7056, open = 7057, type = HORIZONTAL},

	{close = 8541, open = 8543, type = VERTICAL},
	{close = 8542, open = 8543, type = VERTICAL},
	{close = 8544, open = 8546, type = HORIZONTAL},
	{close = 8545, open = 8546, type = HORIZONTAL},
	{close = 8547, open = 8548, type = VERTICAL},
	{close = 8549, open = 8550, type = HORIZONTAL},
	{close = 8551, open = 8552, type = VERTICAL, isQuestDoor = true},
	{close = 8553, open = 8554, type = HORIZONTAL, isQuestDoor = true},
	{close = 8555, open = 8556, type = VERTICAL, isLevelDoor = true},
	{close = 8557, open = 8558, type = HORIZONTAL, isLevelDoor = true},

	{close = 9165, open = 9167, type = VERTICAL},
	{close = 9166, open = 9167, type = VERTICAL},
	{close = 9168, open = 9170, type = HORIZONTAL},
	{close = 9169, open = 9170, type = HORIZONTAL},
	{close = 9171, open = 9172, type = VERTICAL},
	{close = 9173, open = 9174, type = HORIZONTAL},
	{close = 9175, open = 9176, type = VERTICAL, isQuestDoor = true},
	{close = 9177, open = 9178, type = HORIZONTAL, isQuestDoor = true},
	{close = 9179, open = 9180, type = VERTICAL, isLevelDoor = true},
	{close = 9181, open = 9182, type = HORIZONTAL, isLevelDoor = true},

	{close = 9267, open = 9269, type = VERTICAL},
	{close = 9268, open = 9269, type = VERTICAL},
	{close = 9270, open = 9272, type = HORIZONTAL},
	{close = 9271, open = 9272, type = HORIZONTAL},
	{close = 9273, open = 9274, type = VERTICAL},
	{close = 9275, open = 9276, type = HORIZONTAL},
	{close = 9277, open = 9278, type = VERTICAL, isQuestDoor = true},
	{close = 9279, open = 9280, type = HORIZONTAL, isQuestDoor = true},
	{close = 9281, open = 9282, type = VERTICAL, isLevelDoor = true},
	{close = 9283, open = 9284, type = HORIZONTAL, isLevelDoor = true},

	{close = 10268, open = 10270, type = VERTICAL},
	{close = 10269, open = 10270, type = VERTICAL},
	{close = 10271, open = 10273, type = HORIZONTAL},
	{close = 10272, open = 10273, type = HORIZONTAL},
	{close = 10274, open = 10275, type = VERTICAL},
	{close = 10276, open = 10277, type = HORIZONTAL},
	{close = 10278, open = 10279, type = VERTICAL, isQuestDoor = true},
	{close = 10280, open = 10281, type = HORIZONTAL, isQuestDoor = true},
	{close = 10282, open = 10283, type = VERTICAL, isLevelDoor = true},
	{close = 10284, open = 10285, type = HORIZONTAL, isLevelDoor = true},

	{close = 10468, open = 10470, type = HORIZONTAL},
	{close = 10469, open = 10470, type = HORIZONTAL},
	{close = 10471, open = 10472, type = HORIZONTAL},
	{close = 10473, open = 10474, type = HORIZONTAL, isLevelDoor = true},
	{close = 10475, open = 10476, type = HORIZONTAL, isQuestDoor = true},
	{close = 10477, open = 10479, type = VERTICAL},
	{close = 10478, open = 10479, type = VERTICAL},
	{close = 10480, open = 10481, type = VERTICAL},
	{close = 10482, open = 10483, type = VERTICAL, isLevelDoor = true},
	{close = 10484, open = 10485, type = VERTICAL, isQuestDoor = true},

	{close = 10775, open = 10777, type = HORIZONTAL},
	{close = 10776, open = 10777, type = HORIZONTAL},
	{close = 10780, open = 10781, type = HORIZONTAL, isLevelDoor = true},
	{close = 10782, open = 10783, type = HORIZONTAL, isQuestDoor = true},

	{close = 10784, open = 10786, type = VERTICAL},
	{close = 10785, open = 10786, type = VERTICAL},
	{close = 10789, open = 10790, type = VERTICAL, isLevelDoor = true},
	{close = 10791, open = 10792, type = VERTICAL, isQuestDoor = true},

	{close = 12092, open = 12094, type = HORIZONTAL},
	{close = 12093, open = 12094, type = HORIZONTAL},
	{close = 12095, open = 12096, type = HORIZONTAL, isLevelDoor = true},
	{close = 12097, open = 12098, type = HORIZONTAL, isQuestDoor = true},
	{close = 12099, open = 12101, type = VERTICAL},
	{close = 12100, open = 12101, type = VERTICAL},
	{close = 12102, open = 12103, type = VERTICAL, isLevelDoor = true},
	{close = 12104, open = 12105, type = VERTICAL, isQuestDoor = true},

	{close = 12188, open = 12190, type = HORIZONTAL},
	{close = 12189, open = 12190, type = HORIZONTAL},
	{close = 12193, open = 12194, type = HORIZONTAL, isLevelDoor = true},
	{close = 12195, open = 12196, type = HORIZONTAL, isQuestDoor = true},
	{close = 12197, open = 12199, type = VERTICAL},
	{close = 12198, open = 12199, type = VERTICAL},
	{close = 12202, open = 12203, type = VERTICAL, isLevelDoor = true},
	{close = 12204, open = 12205, type = VERTICAL, isQuestDoor = true},

	{close = 13020, open = 13021, type = VERTICAL},
	{close = 13022, open = 13023, type = HORIZONTAL},

	{close = 17235, open = 17236, type = HORIZONTAL},
	{close = 17237, open = 17238, type = VERTICAL},

	{close = 18208, open = 18209, type = HORIZONTAL},

	{close = 19840, open = 19842, type = HORIZONTAL},
	{close = 19841, open = 19842, type = HORIZONTAL},
	{close = 19843, open = 19844, type = HORIZONTAL},
	{close = 19845, open = 19846, type = HORIZONTAL, isLevelDoor = true},
	{close = 19847, open = 19848, type = HORIZONTAL, isQuestDoor = true},
	{close = 19849, open = 19851, type = VERTICAL},
	{close = 19850, open = 19851, type = VERTICAL},
	{close = 19852, open = 19853, type = VERTICAL},
	{close = 19854, open = 19855, type = VERTICAL, isLevelDoor = true},
	{close = 19856, open = 19857, type = VERTICAL, isQuestDoor = true},

	{close = 19980, open = 19982, type = HORIZONTAL},
	{close = 19981, open = 19982, type = HORIZONTAL},
	{close = 19983, open = 19984, type = HORIZONTAL},
	{close = 19985, open = 19986, type = HORIZONTAL, isLevelDoor = true},
	{close = 19987, open = 19988, type = HORIZONTAL, isQuestDoor = true},
	{close = 19989, open = 19991, type = VERTICAL},
	{close = 19990, open = 19991, type = VERTICAL},
	{close = 19992, open = 19993, type = VERTICAL},
	{close = 19994, open = 19995, type = VERTICAL, isLevelDoor = true},
	{close = 19996, open = 19997, type = VERTICAL, isQuestDoor = true},

	{close = 20273, open = 20275, type = HORIZONTAL},
	{close = 20274, open = 20275, type = HORIZONTAL},
	{close = 20276, open = 20277, type = HORIZONTAL},
	{close = 20278, open = 20279, type = HORIZONTAL, isLevelDoor = true},
	{close = 20280, open = 20281, type = HORIZONTAL, isQuestDoor = true},
	{close = 20282, open = 20284, type = VERTICAL},
	{close = 20283, open = 20284, type = VERTICAL},
	{close = 20285, open = 20286, type = VERTICAL},
	{close = 20287, open = 20288, type = VERTICAL, isLevelDoor = true},
	{close = 20289, open = 20290, type = VERTICAL, isQuestDoor = true},

	{close = 22814, open = 22816, type = HORIZONTAL},
	{close = 22815, open = 22816, type = HORIZONTAL},
	{close = 22817, open = 22818, type = HORIZONTAL},
	{close = 22819, open = 22820, type = HORIZONTAL},
	{close = 22821, open = 22822, type = HORIZONTAL, isQuestDoor = true},
	{close = 22823, open = 22825, type = VERTICAL},
	{close = 22824, open = 22825, type = VERTICAL},
	{close = 22826, open = 22827, type = VERTICAL},
	{close = 22828, open = 22829, type = VERTICAL},
	{close = 22830, open = 22831, type = VERTICAL, isQuestDoor = true},

	{close = 25158, open = 25159, type = VERTICAL},
	{close = 25160, open = 25161, type = HORIZONTAL},
	{close = 25162, open = 25163, type = VERTICAL, isQuestDoor = true},
	{close = 25164, open = 25165, type = HORIZONTAL, isQuestDoor = true},

	{close = 27209, open = 27210, type = HORIZONTAL},
	{close = 27211, open = 27212, type = VERTICAL},

	{close = 35486, open = 35490, type = HORIZONTAL},
	{close = 35487, open = 35490, type = HORIZONTAL},
	{close = 35488, open = 35490, type = VERTICAL},
	{close = 35489, open = 35491, type = VERTICAL},

	{close = 36208, open = 36210, type = HORIZONTAL},
	{close = 36209, open = 36211, type = VERTICAL},	
	{close = 35547, open = 35551, type = HORIZONTAL},
	
	{close = 32931, open = 32935, type = HORIZONTAL},
	{close = 32933, open = 32936, type = VERTICAL},

	{close = 36377, open = 36378, type = HORIZONTAL, isQuestDoor = true},
	{close = 36379, open = 36380, type = VERTICAL, isQuestDoor = true},

}

keysDoor = {2086, 2087, 2088, 2089, 2090, 2091, 2092, 10032}

function getDoorInfo(doorid)
	-- as quests/level sempre a fechada
	for _, p in pairs(newdoors) do
		if p.close == doorid or p.open == doorid then
			return p
		end
	end

	return false
end

-- registrar no actions
globalDoors = {}
for _, p in pairs(newdoors) do
	local has = false
	for x, t in pairs(globalDoors) do
		if t == p.open then
			has = true
		end
	end

	if not has then
		globalDoors[#globalDoors + 1] = p.open
	end

	local has = false
	for x, t in pairs(globalDoors) do
		if t == p.close then
			has = true
		end
	end

	if not has then
		globalDoors[#globalDoors + 1] = p.close
	end
end

function DOOR:new(itemid)
	local obj = getDoorInfo(itemid)
	if not obj then
		return nil
	end
	obj.itemid = itemid

	return setmetatable(obj, { __index = self })
end

function Door(itemid)
	return DOOR:new(itemid)
end

function DOOR:getOpened()
	return self.open
end

function DOOR:isOpened()
	return self.itemid == self.open
end

function DOOR:getClosed()
	return self.close
end

function DOOR:use()
	return (self.open == self.itemid and self.close or self.open)
end

function DOOR:isQuest()
	return self.isQuestDoor
end

function DOOR:isLevel()
	return self.isLevelDoor
end

function DOOR:isSpecial()
	if self.isQuestDoor then
		return true
	end

	if self.isLevelDoor then
		return true
	end

	return false
end

function DOOR:isVertical()
	return self.type == VERTICAL
end

function DOOR:isHorizontal()
	return self.type == HORIZONTAL
end
