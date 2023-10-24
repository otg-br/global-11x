function onUse(cid, item, fromPosition, itemEx, toPosition, isHotkey)
     local player = Player(cid)
	 if itemEx:getId() == 24716 then
		item:remove(1)
		itemEx:transform(itemEx:getId() + 1)
	 end
     return true
end
