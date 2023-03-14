local menu = Menu("XPVE")
	
	menu:label("XPVE Version 1.0.1") menu:separator() menu:space()
	
	menu:subMenu("Action Settings", "ACTIONS")
		menu["ACTIONS"]:subMenu("Tanks", "TANK")
		menu["ACTIONS"]:subMenu("Healers", "HEALER")
		menu["ACTIONS"]:subMenu("Melee DPS", "MELEE_DPS")
		menu["ACTIONS"]:subMenu("Physical Ranged DPS", "RANGE_DPS_P")			
		menu["ACTIONS"]:subMenu("Magic Ranged DPS", "RANGE_DPS_M")

	menu:subMenu("Draw Settings", "DRAWS")
		menu["DRAWS"]:checkbox("Draw On/Off Toggle", "ONOFF", true)

	menu:space() menu:space()

	menu:checkbox("Use Rotations", "ONOFF", true)
	menu:hotkey("Toggle On / Off", "ONOFF_KEY", 84)
	menu:hotkey("Prepull Key", "PREPULL_KEY", 90)
	menu:hotkey("Set AoE on / off", "AOE_KEY", {16,  76})

return menu