--By Igor Labanca
--Fixes by Leu (jlcvp)

local petNames = {
	[1] = 'thundergiant',
	[2] = 'grovebeast',
	[3] = 'emberwing',
	[4] = 'skullfrost'
}

local STORAGE_PET = Storage.PetSummon

function onLogin(cid)
	local player = Player(cid)
	player:registerEvent("petlogout")

	local vocationid = player:getVocation():getId()
	local pet = ""
	local petTimeLeft = player:getStorageValue(STORAGE_PET)/1000

	if petTimeLeft > 0 then
		if vocationid == 5 then
			pet = "thundergiant"
		elseif vocationid == 6 then
			pet = "grovebeast"
		elseif vocationid == 7 then
			pet = "emberwing"
		elseif vocationid == 8 then
			pet = "skullfrost"
		end
	end

	if pet ~= "" then
		position = player:getPosition()
		summonpet = Game.createMonster(pet, position, false, true, cid)
		if summonpet then
			player:addSummon(summonpet)
			player:setPet(summonpet, player:getStorageValue(STORAGE_PET))
		end
		position:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end

function onLogout(player)
	local myPet = player:getPet()
	if not myPet then
		player:setStorageValue(STORAGE_PET, -1)
		return true
	end

	local pet = Monster(myPet:getId())
	if not pet then
		player:setStorageValue(STORAGE_PET, -1)
		return true
	end

	local decay = pet:getRemoveTime()
	if decay > 0 then
		player:setStorageValue(STORAGE_PET, decay)
	end

	return true
end

function onDeath(creature, corpse, lasthitkiller, mostdamagekiller, lasthitunjustified, mostdamageunjustified)
	local player = creature:getMaster()
	if not player then
		return false
	end

	if table.contains(petNames,creature:getName():lower()) then
		player:setStorageValue(STORAGE_PET, -1) --imeddiately expire creature

		-- maybe we need to remove creature from the game manually?
		-- doRemoveCreature (getCreatureSummons(player)[1])
	end

	return true
end
