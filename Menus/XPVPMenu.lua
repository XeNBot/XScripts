local menu = Menu("XPVP")

	menu:label("XPVP Version 1.15") menu:separator() menu:space()

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
		menu["ACTIONS"]:checkbox("Action Directional Check", "DIRECTION_CHECK", false)

	menu:checkbox("Disable Casting while moving", "MOVING_CHECK", true)

	menu:subMenu("Extra Settings", "EXTRA")
		menu["EXTRA"]:checkbox("Practice Combo Dummies", "PRACTICE", true)

	menu:space() menu:space() menu:space()

	menu:combobox("Combo Mode", "COMBO_MODE", {"Always On", "On Hotkey"}, 0)

	menu:space() menu:space()

	menu:hotkey("ComboKey", "COMBO_KEY", 88)
	menu:hotkey("Toggle Jump Key: ", "JUMP_KEY", 84)
	menu:hotkey("Set Auto Target on / off", "AUTO_TARGET_KEY", {16,  75})

	menu:space() menu:space()
	menu:separator()
	menu:button("Open Class Menu", "OPEN_CLASS_WIDGET", function()

		if _G.XPVP ~= nil and _G.XPVP.current_class ~= nil and _G.XPVP.current_class.class_menu ~= nil then
			_G.XPVP.current_class.class_menu.visible = true
		end
	end)
	menu:hotkey("Open Class Widget Key", "CLASS_WIDGET_KEY", {16,  80})
	menu:separator()

return menu