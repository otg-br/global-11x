local config = {
        outfits = {"mummy", "vampire", "skeleton", "demon skeleton"}, -- possible outfits
        duration = 45, -- duration of the outfit in seconds
        breakChance = 2 -- a chance of losing the wand
}

function onUse(cid, item, fromPosition, itemEx, toPosition)
        if(math.random(1, 100) <= config.breakChance) then
			doSummonCreature("Mad Sheep", toPosition)
			doRemoveItem(item.uid, 1)
			return true
        end
        if(isPlayer(itemEx.uid)) then
			if getCreatureOutfit(itemEx.uid).lookMount > 0 then
				doSendMagicEffect(toPosition, CONST_ME_POFF)
				return true
			end
			doSetMonsterOutfit(itemEx.uid, config.outfits[math.random(1, table.maxn(config.outfits))], config.duration * 1000)
			doSendMagicEffect(toPosition, CONST_ME_MAGIC_BLUE)
        end
        return true
end
