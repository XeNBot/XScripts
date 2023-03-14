local HealingManager = Class("HealingManager")

function HealingManager:initialize()

	print("Healing Manager Initialized")

	self.menu = nil
	self.heal_actions   = {}
	self.revive_actions = {}
end

function HealingManager:Load(menu)

	self.menu = menu

	self.menu:subMenu("Healing Manager", "HEAL_MNG")
	self.menu["HEAL_MNG"]:setIcon("XXScripts", "\\Resources\\Icons\\Roles\\HealerRole.png")

		self.menu["HEAL_MNG"]:label("-=[ Healing Manager ]=-", "MENU_LABEL", true) self.menu["HEAL_MNG"]:separator()

		self.menu["HEAL_MNG"]:subMenu("Role Priority Settings", "PRIORITY")
		self.menu["HEAL_MNG"]["PRIORITY"]:setIcon("XXScripts", "\\Resources\\Icons\\Roles\\AllRounder.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("Tanks",  "TANKS",  1)
			self.menu["HEAL_MNG"]["PRIORITY"]["TANKS"]:setIcon("XXScripts", "\\Resources\\Icons\\Roles\\TankRole.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("DPS",    "DPS",    2)
			self.menu["HEAL_MNG"]["PRIORITY"]["DPS"]:setIcon("XXScripts", "\\Resources\\Icons\\Roles\\DPSRole.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("Healer", "HEALER", 3)
			self.menu["HEAL_MNG"]["PRIORITY"]["HEALER"]:setIcon("XXScripts", "\\Resources\\Icons\\Roles\\HealerRole.png")

		self.menu["HEAL_MNG"]:subMenu("Party Members", "PARTY_MEMBERS")
		self.menu["HEAL_MNG"]["PARTY_MEMBERS"]:setIcon("XXScripts", "\\Resources\\Icons\\Misc\\Party.png")		
	
	self.menu["HEAL_MNG"]:separator() self.menu["HEAL_MNG"]:label("-=[ Misc ]=-", "MISC_LABEL", true) self.menu["HEAL_MNG"]:separator()

	self.menu["HEAL_MNG"]:slider("Minimum # Low Health Players for AoE", "MIN_AOE", 1, 0, 5, 2)
	
	self.menu["HEAL_MNG"]:separator() self.menu["HEAL_MNG"]:label("-=[ Actions ]=-", "ACTIONS_LABEL", true) self.menu["HEAL_MNG"]:separator()
end

function HealingManager:AddActionTable(tbl)

	for i, action in pairs(tbl) do

		table.insert(self.heal_actions, action)

		self.menu["HEAL_MNG"]:subMenu(action.name .. " Settings", action.name)
		local action_icon = string.lower(action.name):gsub("%s+", "_")		
		self.menu["HEAL_MNG"][action.name]:setIcon("XXScripts", "\\Resources\\Icons\\Actions\\" .. action_icon .. ".png")
		self.menu["HEAL_MNG"][action.name]:checkbox("Use On Party Player Members",      "PARTY_MEMBERS",     true)
		self.menu["HEAL_MNG"][action.name]:checkbox("Use On People outside of Party",   "NON_PARTY_MEMBERS", true)
		self.menu["HEAL_MNG"][action.name]:slider("Minimum MP Percent",                 "MIN_MP", 1, 0, 100, 0)
	end

end

function HealingManager:HealWatch()

	local saved_target = TargetManager.Target

	if #self.heal_actions > 0 then

		for i, h in ipairs(self.heal_actions) do
			if h:canUse() and player.manaPercent >= self.menu["HEAL_MNG"][h.name]["MIN_MP"].int and self:ConditionsMet(h) then

				local potency = self:CalculateHealingPotential(h)

				local filter = function (p)
					return p.yalmX < h.range and h:canUse(p) and p.missingHealth > potency and not p.isDead and p.ally
				end

				local players = ObjectManager.Players(filter)
				local npc_players = ObjectManager.NPCPlayers(filter)

				if #players > 0 and self:ShouldHealTable(h, players, potency, saved_target) or
					#npc_players > 0 and self:ShouldHealTable(h, npc_players, potency, saved_target)then
					return true
				end

				return false
			end
		end
	end

	return false

end

function HealingManager:ShouldHealTable(action , tbl, potency, saved_target)

	if not action.aoe and ( #tbl < self.menu["HEAL_MNG"]["MIN_AOE"].int or not self:CanUseAoEHeal() ) then
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

	local total = heal_action:calcHealing(heal_action.potency)
	local bonus = 1

	if heal_action.bonus ~= nil then
		bonus = bonus + (heal_action.bonus() / 100)
	end

	--print(heal_action.name ..  " ->  Heal Potency :  " .. tostring(math.floor(total * bonus)))

	return math.floor(total * bonus) 
end

function HealingManager:CanUseAoEHeal()

	for i, h in ipairs(self.heal_actions) do
		if h.aoe and h:canUse() then
			return true
		end
	end

	return false
end

return HealingManager:new()