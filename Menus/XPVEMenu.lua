local menu = Menu("XPVE")
	
	menu:label("XPVE Version 1.0") menu:separator() menu:space()
	
	menu:subMenu("Action Settings", "ACTIONS")
		menu["ACTIONS"]:subMenu("Tanks", "TANK")
		menu["ACTIONS"]:subMenu("Healers", "HEALER")
		menu["ACTIONS"]:subMenu("Melee DPS", "MELEE_DPS")
		menu["ACTIONS"]:subMenu("Physical Ranged DPS", "RANGE_DPS_P")			
		menu["ACTIONS"]:subMenu("Magic Ranged DPS", "RANGE_DPS_M")	

return menu