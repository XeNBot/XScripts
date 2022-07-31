local menu = Menu("XPVP")
	
	menu:label("XPVP Version 1.1") menu:separator() menu:space()
	
	menu:subMenu("Target Settings", "TARGET")
		menu["TARGET"]:checkbox("Get Target Auto", "AUTO", true)
		menu["TARGET"]:checkbox("Don't Attack Guard", "GUARD_CHECK", true)
		menu["TARGET"]:checkbox("Lock on to Tab Targets", "LOCK", false)
		menu["TARGET"]:combobox("Mode", "MODE", {"Lowest Health", "Closest"})
	
	menu:subMenu("Action Settings", "ACTIONS")
		menu["ACTIONS"]:subMenu("Common", "COMMON")			
		menu["ACTIONS"]:subMenu("Tanks", "TANK")
		menu["ACTIONS"]:subMenu("Healers", "HEALER")
		menu["ACTIONS"]:subMenu("Melee DPS", "MELEE_DPS")
		menu["ACTIONS"]:subMenu("Physical Ranged DPS", "RANGE_DPS_P")			
		menu["ACTIONS"]:subMenu("Magic Ranged DPS", "RANGE_DPS_M")

	
	menu:subMenu("Extra Settings", "EXTRA")
		menu["EXTRA"]:checkbox("Practice Combo Dummies", "PRACTICE", true)

	menu:space() menu:space() menu:space()

	menu:combobox("Combo Mode", "COMBO_MODE", {"Always On", "On Hotkey"}, 0)

	menu:space() menu:space()

	menu:hotkey("ComboKey", "COMBO_KEY", 88)

return menu