local dolls = {
-- panda teddy
	[5080] = {"Hug me."},
	
-- mysterious voodoo skull.	
	[5669] = {
		"It's not winning that matters, but winning in style.",
		"Today's your lucky day. Probably.",
		"Do not meddle in the affairs of dragons, for you are crunchy and taste good with ketchup.",
		"That is one stupid question.",
		"You'll need more rum for that.",
		"Do or do not. There is no try.",
		"You should do something you always wanted to.",
		"If you walk under a ladder and it falls down on you it probably means bad luck.",
		"Never say 'oops'. Always say 'Ah, interesting!'",
		"Five steps east, fourteen steps south, two steps north and seventeen steps west!"
	},
	
-- stuffed dragon	
	[6566] = {
		"Fchhhhhh!",
		"Zchhhhhh!",
		"Grooaaaaar*cough*",
		"Aaa... CHOO!",
		"You... will.... burn!!"
	},
	
-- christmas card	
	[6388] = {"Merry Christmas |PLAYERNAME|."},
	
-- santa doll	
	[6512] = {
		"Ho ho ho",
		"Jingle bells, jingle bells...",
		"Have you been naughty?",
		"Have you been nice?",
		"Merry Christmas!",
		"Can you stop squeezing me now... I'm starting to feel a little sick."
	},

-- oracle figurine	
	[8974] = {"ARE YOU PREPARED TO FACE YOUR DESTINY?"},

-- Tibiacity Encyclopedia
	[8977] = {
		"Weirdo, you're a weirdo! Actually all of you are!",
		"Pie for breakfast, pie for lunch and pie for dinner!",
		"All hail the control panel!",
		"I own, Tibiacity owns, perfect match!",
		"Hug me! Feed me! Hail me!"
	},
	
-- golden newspaper	
	[8981] = {
		"It's news to me.",
		"News, updated as infrequently as possible!",
		"Extra! Extra! Read all about it!",
		"Fresh off the press!"
	},
	
-- Norseman Doll	
	[8982] = {
		"Hail TibiaNordic!",
		"So cold..",
		"Run, mammoth!"
	},
	
-- Epaminondas Doll	
	[10063] = {
		"Hail |PLAYERNAME|!!!",
		"Hail Portal Tibia!",
		"Hauopa!",
		"WHERE IS MY HYDROMEL?!",
		"Yala Boom"
	},
	
-- Draken Doll
	[13030] = {
		"For zze emperor!",
		"Hail |PLAYERNAME|!!",
		"Hail TibiaJourney.com!"
	},
	
-- Dread Doll
	[13559] = {
		"Mhausheausheu! What a FAIL! Mwahaha!",
		"Hail |PLAYERNAME|! You are wearing old socks!",
		"You are so unpopular even your own shadow refuses to follow you.",
		"Have fun with FunTibia.com!"
	},
	
-- Evilina
	[13571] = {"Agha! Aghal!"},
	
-- Impward
	[13566] = {"GI GI GI GI!"},
	
-- Meandi
	[13565] = {"Gah! Gah! Gah!"},
	
-- Whinona
	[13568] = {"Ugi! Ugi!"},
	
	
-- Doll of Durin The Almighty
	[16107] = {
		"Hahaha!! |PLAYERNAME|",
		"what about a few demons in Thais?",
		"My powers are limitless!",
		"Hail Tibia Bariloche!"
	},
	
-- Pet Pig
	[18455] = {"Oink oink!"},
	
-- black knight doll
	[23806] = {
		"I can hear their whisperings... Revenge!",
		"You shall feel pain and terror, |PLAYERNAME|",
		"I do not need a sword to slaughter you",
		"My sword is broken, but my spirit is not dead",
		"I can say 469 and more...",
		"My dark magic lies on tibialatina.wikia.com"
	},
	
-- Midnight Panther Doll
	[24316] = {
	"Hail TibiaMagazine.com!",
	"Don't be afraid of the darkness!"; "Purrrrrrr!", 
	"Feel lucky, |PLAYERNAME|!"
	}, 
	
-- Assassin Doll
	[24331] = {
	"Ahhh... silent and deadly...",
	"Hail Tibia Brasileiros!", 
	"Hail |PLAYERNAME|.",
	"Only the real killers can touch me!",
	"The path of assassin is found in death, DIE!"
	}, 
	
-- little adventurer's doll
	[24776] = {
	"Silence! I smell something!",
	"Watch your steps - we found the pit latrine.", 
	"Let me guide you, |PLAYERNAME|!!",
	"For concrete information visit TibiaGuias.com.br",
	"I have a bad feeling about this.",
	"Hello, TibiaGuias!"
	}, 

-- Cateroide's Doll
	[24807] = {
	"Hail Cateroide!",
	"Oops, have BOH!", 
	"Hail tibians you have the right to remain silent!",
	"I am Cateroide and I always have BOH"
	},
	
-- Loremaster Doll
	[28308] = {"Let me enlighten you!!"},
	
-- Goromaphone
	[29321] = {
	"It's the Eye of the Panter!",
	"You are now listening too 66.6 RadioGoroma FM! Your Tibian Radio!", 
	"~ Keep spending most of our lives, Living in E.K's paradise~",
	"~ And Iiiiii-eeee-iii Will always Heal youuuuuu-hooooo!~",
	"~ I'm hungry Like the Warwolf ~",
	"~ I Love Loot 'N Gold! Put a Crystal Coin in my Backpack, Baby! ~"
	},
	
-- Citizen Doll
	[32069] = {
	"Thais is the oldest city in Tibia, did you know that?",
	"Looking for the great histories and adventures? Take a look at TibiaTV.com.br!", 
	"Have you heard about the Sword of Fury in Rookgaard? It's been a long time since I have seen it..."
	}, 
	
-- bookworm doll
	[33374] = {
	"Shhhhhh, please be quiet!",
	"Books are great!! Aren't they?",
	"Hail Tibia Library!"
	}, 
	
-- Badbara
	[35079] = {"Bah!"}, 
	
-- Tearesa	
	[35080] = {"Bah!"},
	
-- Cryana
	[35081] = {"Bah!"},
	
-- Omniscient Owl
	[36388] = {"I know the answer!"}, 	
	
	
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local sounds = dolls[item.itemid]
	if not sounds then
		return false
	end

	if fromPosition.x == CONTAINER_POSITION then
		fromPosition = player:getPosition()
	end

	local random = math.random(#sounds)
	local sound = sounds[random]
	if item.itemid == 6566 then
		if random == 3 then
			fromPosition:sendMagicEffect(CONST_ME_POFF)
		elseif random == 4 then
			fromPosition:sendMagicEffect(CONST_ME_FIREAREA)
		elseif random == 5 then
			doTargetCombatHealth(0, player, COMBAT_PHYSICALDAMAGE, -1, -1, CONST_ME_EXPLOSIONHIT)
		end
	elseif item.itemid == 5669 then
		fromPosition:sendMagicEffect(CONST_ME_MAGIC_RED)
		item:transform(item.itemid + 1)
		item:decay()	
		
	elseif item.itemid == 10063 then
		item:transform(10064)	
		item:decay()
		
	elseif item.itemid == 13030 then
		item:transform(13031)	
		item:decay()	
		
	elseif item.itemid == 13571 then
		item:transform(13567)
		item:decay()
	
	elseif item.itemid == 13565 then
		item:transform(13569)
		item:decay()
		
	elseif item.itemid == 13566 then
		item:transform(13582)
		item:decay()
	
	elseif item.itemid == 13568 then
		item:transform(13564)
		item:decay()
		
	elseif item.itemid == 16107 then
		item:transform(16108)	
		item:decay()
		
	elseif item.itemid == 18455 then
		item:transform(18456)	
		item:decay()
		
	elseif item.itemid == 24807 then
		item:transform(24808)	
		item:decay()
		
	elseif item.itemid == 24776 then
		item:transform(24777)	
		item:decay()
		
	elseif item.itemid == 28308  then
		item:transform(item.itemid + 1)
		item:decay()	
			
	elseif item.itemid == 29321 then
		item:transform(29322)	
		item:decay()
	
	elseif item.itemid == 32069 then
		item:transform(32070)	
		item:decay()
		
		elseif item.itemid == 35079 then
		item:transform(35076)
		item:decay()
	
	elseif item.itemid == 35080 then
		item:transform(item.itemid + 1)
		item:transform(35077)
		
	elseif item.itemid == 35081 then
		item:transform(35078)
		item:decay()
		
	elseif item.itemid == 6388 then
		fromPosition:sendMagicEffect(CONST_ME_SOUND_YELLOW)
	end

	sound = sound:gsub('|PLAYERNAME|', player:getName())
	player:say(sound, TALKTYPE_MONSTER_SAY, false, 0, fromPosition)
	return true
end
