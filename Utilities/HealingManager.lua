local HealingManager = Class("HealingManager")

function HealingManager:initialize()
	
	print("Healing Manager Initialized")

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

		--print("Adding Action " .. action.name)

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

				local players = ObjectManager.Players(function (p)
					
					return p.yalmX <= h.range and p.missingHealth >= potency and not p.isDead and
					( self.menu["HEAL_MNG"][h.name]["NON_PARTY_MEMBERS"].bool or p.ally)

				end)

				if not h.aoe and #players < self.menu["HEAL_MNG"]["MIN_AOE"].int then

					for i, p in ipairs(players) do
						if h:canUse(p) then
							print(p.name .. " has " .. tostring(p.missingHealth) .. " missing life (" .. tostring(p.health) .. "/" .. tostring(p.maxHealth) .. ")")
							print("Healing : " .. p.name .. " with Action : " .. h.name .. " for ~ " .. tostring(potency) .. " life")
							h:use(p)
							if saved_target.valid and not saved_target.isDead then
								TargetManager.SetTarget(saved_target)
							end
							return true
						end

					end

				elseif h.aoe and #players >= self.menu["HEAL_MNG"]["MIN_AOE"].int then
					
					local best_target = nil
					local num_players = 0

					for i, p in ipairs(players) do

						local num = ObjectManager.PlayersAroundObject(p, action.range, function (p) return p.missingHealth >= potency end)
						if num > num_players then
							best_target = p
						end

					end

					if best_target ~= nil and h:canUse(best_target) then
						print(best_target.name .. " has " .. tostring(best_target.missingHealth) .. " missing life (" .. tostring(best_target.health) .. "/" .. tostring(best_target.maxHealth) .. ")")
						print("There are : " .. tostring(num_players) .. " low health players around target")
						print("Healing : " .. best_target.name .. " with Action : " .. best_target.name .. " for ~ " .. tostring(potency) .. " life")
						h:use(best_target)
						if saved_target.valid and not saved_target.isDead then
							TargetManager.SetTarget(saved_target)
						end
						return true
					end
				end
			end
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
		return
	end

	local HMP   = self:CalculateHMP(levelModifier)
	local DET   = self:CalculateDET(levelModifier)
	local CRIT  = self:CalculateCRIT(levelModifier)
	local TNC   = self:CalculateTNC(levelModifier)
	local WD    = self:CalculateWD(levelModifier)
	local h1    = math.floor( math.floor( math.floor(heal_action.potency * HMP * DET ) / 100 ) / 1000)
	local h2    = math.floor( math.floor( math.floor( math.floor( h1 * TNC ) / 1000 ) * CRIT ) / 1000 )
	local bonus = heal_action.bonus ~= nil and heal_action.bonus() or 0

	if bonus ~= 0 then
		bonus = ( h2 * bonus ) / 100
	end

	local total = math.floor( h2 + bonus)
	
	--print("Calculated to Heal ~ : " .. tostring(total))

	return total
	
end

function HealingManager:CalculateMainHeal(mod)
	
	return (math.floor( 100 * (player.mind - mod.main) / 304 ) + 100) / 100 

end

function HealingManager:CalculateWD(mod)
	return math.floor( (mod.main * player.mind / 1000) + 100)
end

function HealingManager:CalculateDET(mod)
	
	return math.floor( 130 * (player.determination - mod.main) / mod.div + 1000 )

end

function HealingManager:CalculateTNC(mod)
	
	return math.floor( 100 * (player.tenacity - mod.sub) / mod.div + 1000 )

end

function HealingManager:CalculateCRIT(mod)
	return math.floor( 200 * (player.criticalHit - mod.sub) /  mod.div + 1400 )
end

function HealingManager:CalculateHMP()
	return math.floor ( 100 * (player.healingMagicPotency - 340) / 304 ) + 100
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
		LEVEL_MODS["80"]
end

return HealingManager:new()