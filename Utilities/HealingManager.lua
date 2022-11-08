local HealingManager = Class("HealingManager")

function HealingManager:initialize()
	
	--print("Healing Manager Initialized")

	self.menu = nil
	self.heal_actions = {}


	-- Stats modifiers
	self.LEVEL_MODS = LoadModule("XScripts", "\\Enums\\LevelMod")
	self.JOB_MODS   = LoadModule("XScripts", "\\Enums\\JobMod")
end

function HealingManager:Load(menu)
	
	self.menu = menu

	self.menu:subMenu("Healing Manager", "HEAL_MNG")
		self.menu["HEAL_MNG"]:subMenu("Role Priority Settings", "PRIORITY")
			self.menu["HEAL_MNG"]["PRIORITY"]:number("Tanks",  "TANKS",  1)
			self.menu["HEAL_MNG"]["PRIORITY"]:number("DPS",    "DPS",    2)
			self.menu["HEAL_MNG"]["PRIORITY"]:number("Healer", "HEALER", 3)
		self.menu["HEAL_MNG"]:slider("Minimum # Low Health Players for AoE", "MIN_AOE", 1, 0, 100, 2)
end

function HealingManager:AddActionTable(tbl)
	
	for i, action in pairs(tbl) do

		table.insert(self.heal_actions, action)

		self.menu["HEAL_MNG"]:subMenu(action.name .. " Settings", action.name)
		self.menu["HEAL_MNG"][action.name]:checkbox("Use On Party Player Members",      "PARTY_MEMBERS",     true)
		self.menu["HEAL_MNG"][action.name]:checkbox("Use On People outside of Party",   "NON_PARTY_MEMBERS", true)
		self.menu["HEAL_MNG"][action.name]:slider("Minimum MP Percent",                 "MIN_MP", 1, 0, 100, 0)

	end

end

function HealingManager:HealWatch()
	
	local saved_target = TargetManager.Target

	if #self.heal_actions > 0 then
	
		for i, h in ipairs(self.heal_actions) do
			if h.recastTime == 0 and player.manaPercent >= self.menu["HEAL_MNG"][h.name]["MIN_MP"].int and self:ConditionsMet(h) then

				local potency = self:CalculateHealingPotential(h)

				local filter = function (p)
					return p.yalmX <= h.range and h:canUse(p) and p.missingHealth > potency and not p.isDead and
					( self.menu["HEAL_MNG"][h.name]["NON_PARTY_MEMBERS"].bool or p.ally)
				end

				local players = ObjectManager.Players(filter)
				local npc_players = ObjectManager.NPCPlayers(filter)

				if #players > 0 then
					return self:ShouldHealTable(h, players, potency)
				elseif #npc_players > 0 then
					return self:ShouldHealTable(h, npc_players, potency)				
				end				
			end
		end
	end

	return false

end

function HealingManager:ShouldHealTable(action , tbl, potency)
	if not action.aoe and #tbl < self.menu["HEAL_MNG"]["MIN_AOE"].int then
		for i, p in ipairs(tbl) do
			if action:canUse(p) then
				print(p.name .. " has " .. tostring(p.missingHealth) .. " missing life (" .. tostring(p.health) .. "/" .. tostring(p.maxHealth) .. ")")
				print("Healing : " .. p.name .. " with Action : " .. action.name .. " for ~ " .. tostring(potency) .. " life")
				action:use(p)
				if saved_target.valid and not saved_target.isDead then
					TargetManager.SetTarget(saved_target)
				end
				return true
			end

		end

	elseif action.aoe and #tbl >= self.menu["HEAL_MNG"]["MIN_AOE"].int then
		
		local best_target = nil
		local num_players = 0

		for i, p in ipairs(tbl) do

			local num = ObjectManager.PlayersAroundObject(p, action.range, function (p) return p.missingHealth >= potency end)
			if num > num_players then
				best_target = p
			end

		end

		if best_target ~= nil and action:canUse(best_target) then
			print(best_target.name .. " has " .. tostring(best_target.missingHealth) .. " missing life (" .. tostring(best_target.health) .. "/" .. tostring(best_target.maxHealth) .. ")")
			print("There are : " .. tostring(num_players) .. " low health players around target")
			print("Healing : " .. best_target.name .. " with Action : " .. best_target.name .. " for ~ " .. tostring(potency) .. " life")
			action:use(best_target)
			if saved_target.valid and not saved_target.isDead then
				TargetManager.SetTarget(saved_target)
			end
			return true
		end
	end

	return false

end

function HealingManager:ConditionsMet(action)
	return action.condition == nil  or action.condition()
end

-- Utility Functions

function HealingManager:CalculateHealingPotential(heal_action)
	
	--print("Calculating Healing Potential for Action : " .. heal_action.name)

	local levelModifier = self:GetLevelModifier()
	local jobModifier   = self:GetJobModifier()

	if levelModifier == nil or jobModifier == nil then
		print("[ HealingManager::Error ] - Could not find modifier" )
		return 0
	end

	local HMP   = self:CalculateHMP()
	--print("HMP Calculated " .. tostring(HMP))
	local DET   = self:CalculateDET(levelModifier)
	--print("DET Calculated " .. tostring(DET))
	local CRIT  = self:CalculateCRIT(levelModifier)
	--print("CRIT Calculated " .. tostring(CRIT))
	local TNC   = self:CalculateTNC(levelModifier)
	--print("TNC Calculated " .. tostring(TNC))
	local WD    = self:CalculateWD(levelModifier)
	--print("WD Calculated " .. tostring(WD))

	local main_heal = self:CalculateMainHeal(levelModifier)
	--print("Calculated Main Heal : " .. tostring(main_heal))
 
	local oh1   = math.floor( math.floor( math.floor(heal_action.potency * main_heal * DET) * TNC ) * WD )
	--print("Calculated Oh1 : " .. tostring(oh1))
	--local oh2   = math.floor( oh1 * CRIT)
	--print("Calculated Oh2 : " .. tostring(oh2))	
	local bonus = heal_action.bonus ~= nil and heal_action.bonus() or 0

	if bonus ~= 0 then
		bonus = ( oh1 * bonus ) / 100
	end

	local total = math.floor( oh1 + bonus)
	
	--print("Calculated to Heal ~ : " .. tostring(total))

	return total
	
end

function HealingManager:CalculateMainHeal(level_mod)
	
	if player.classLevel >= 80 then
		return (math.floor( 100 * (player.mind - level_mod.main) / 304 ) + 100) / 100 
	else
		return (math.floor( 100 * (player.mind - level_mod.main) / 264 ) + 100) / 100 
	end

end

function HealingManager:CalculateWD(level_mod)
	return math.floor( ( ( level_mod.main * player.attackMagicPotency ) / 1000) + InventoryManager.MainHand.magicDamage) / 100
end

function HealingManager:CalculateDET(level_mod)
	
	return math.floor( 130 * (player.determination - level_mod.main) / level_mod.div + 1000 ) / 1000

end

function HealingManager:CalculateTNC(level_mod)
	
	return math.floor( 100 * (player.tenacity - level_mod.sub) / level_mod.div + 1000 ) / 1000

end

function HealingManager:CalculateSPD(level_mod)
	return math.floor( 130 * (spellSpeed - level_mod.sub) / level_mod.div + 1000 ) / 1000
end

function HealingManager:CalculateCRIT(level_mod)
	return math.floor( 200 * (player.criticalHit - level_mod.sub) /  level_mod.div + 1400 ) / 1000
end

function HealingManager:CalculateHMP()

	if player.classLevel >= 80 then
		return math.floor ( 100 * (player.healingMagicPotency - 340) / 304 + 100)
	else
		return math.floor ( 100 * (player.healingMagicPotency - 292) / 264 + 100)
	end
end

function HealingManager:GetJobModifier()
	return self.JOB_MODS[tostring(player.classJob)]
end

function HealingManager:GetLevelModifier()
	
	return
		player.classLevel < 9  and self.LEVEL_MODS["1"] or
		player.classLevel < 19 and self.LEVEL_MODS["10"] or
		player.classLevel < 29 and self.LEVEL_MODS["20"] or
		player.classLevel < 39 and self.LEVEL_MODS["30"] or
		player.classLevel < 49 and self.LEVEL_MODS["40"] or
		player.classLevel < 59 and self.LEVEL_MODS["50"] or
		player.classLevel < 69 and self.LEVEL_MODS["60"] or
		player.classLevel < 79 and self.LEVEL_MODS["70"] or
		self.LEVEL_MODS["80"]
end

return HealingManager:new()