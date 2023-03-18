local HealingManager = Class("HealingManager")

function HealingManager:initialize()

	self.menu = nil
	self.heal_actions   = {}
	self.revive_action  = nil

	self.swiftcast = Action(1, 7561)
	self.surecast  = Action(1, 7559)
	self.esuna     = Action(1, 7568)

end

function HealingManager:Load(menu)

	self.menu = menu

	self.menu:subMenu("Healing Manager", "HEAL_MNG")
	self.menu["HEAL_MNG"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\HealerRole.png")

		self.menu["HEAL_MNG"]:label("-=[ Healing Manager ]=-", "MENU_LABEL", true) self.menu["HEAL_MNG"]:separator()

		self.menu["HEAL_MNG"]:subMenu("Role Priority Settings", "PRIORITY")
		self.menu["HEAL_MNG"]["PRIORITY"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\AllRounder.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("Tanks",  "TANKS",  1)
			self.menu["HEAL_MNG"]["PRIORITY"]["TANKS"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\TankRole.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("DPS",    "DPS",    2)
			self.menu["HEAL_MNG"]["PRIORITY"]["DPS"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\DPSRole.png")

			self.menu["HEAL_MNG"]["PRIORITY"]:number("Healer", "HEALER", 3)
			self.menu["HEAL_MNG"]["PRIORITY"]["HEALER"]:setIcon("XScripts", "\\Resources\\Icons\\Roles\\HealerRole.png")

		self.menu["HEAL_MNG"]:subMenu("Party Members", "PARTY_MEMBERS")
		self.menu["HEAL_MNG"]["PARTY_MEMBERS"]:setIcon("XScripts", "\\Resources\\Icons\\Misc\\Party.png")

		self.menu["HEAL_MNG"]:subMenu("Actions", "ACTIONS")
		self.menu["HEAL_MNG"]["ACTIONS"]:setIcon("XScripts", "\\Resources\\Icons\\Misc\\Actions.png")

	self.menu["HEAL_MNG"]:separator() self.menu["HEAL_MNG"]:label("-=[ Misc ]=-", "MISC_LABEL", true) self.menu["HEAL_MNG"]:separator()

		self.menu["HEAL_MNG"]:checkbox("Heal Party Members", "HEAL_PARTY_MEMBERS", true)
		self.menu["HEAL_MNG"]:checkbox("Heal Non Party Members", "HEAL_NON_PARTY_MEMBERS", false)
		self.menu["HEAL_MNG"]:checkbox("Heal Friendly NPCs", "HEAL_FRIENDLY_NPCS", true)
		self.menu["HEAL_MNG"]:checkbox("Heal Friendly Battle Allies", "HEAL_BATTLE_ALLIES", true)

		self.menu["HEAL_MNG"]:slider("Minimum # Low Health Players for AoE", "MIN_AOE", 1, 0, 5, 2)

	self:LoadEsunaManager()
end

function HealingManager:Tick()

	return self:DeathWatch() or self:HealWatch() or self:EsunaWatch()

end

function HealingManager:AddActionTable(tbl)

	for i, action in pairs(tbl) do

		table.insert(self.heal_actions, action)

		self.menu["HEAL_MNG"]["ACTIONS"]:subMenu(action.name .. " Settings", action.name)
		local action_icon = string.lower(action.name):gsub("%s+", "_")
		self.menu["HEAL_MNG"]["ACTIONS"][action.name]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\" .. action_icon .. ".png")
		self.menu["HEAL_MNG"]["ACTIONS"][action.name]:slider("Maximum Waste Percent", "MAX_WASTE", 1, 0, 100, 10)
		self.menu["HEAL_MNG"]["ACTIONS"][action.name]:slider("Minimum MP Percent",    "MIN_MP", 1, 0, 100, 0)
	end

end

function HealingManager:AddReviveAction(action)

	self.revive_action = action

	if self.menu ~= nil and self.menu["REVIVE_MNG"] == nil then
		self.menu:subMenu("Revive Manager", "REVIVE_MNG")
		self.menu["REVIVE_MNG"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\raise.png")

		self.menu["REVIVE_MNG"]:label("-=[ Revive Manager ]=-", "R_MENU_LABEL", true) self.menu["REVIVE_MNG"]:separator()

		self.menu["REVIVE_MNG"]:checkbox("Use Swiftcast", "USE_SWIFTCAST", true)
		self.menu["REVIVE_MNG"]:checkbox("Use Surecast if no Swiftcast", "USE_SURECAST", true)
		self.menu["REVIVE_MNG"]:checkbox("Use " .. action.name, "USE_REVIVE", true)

		self.menu["REVIVE_MNG"]:separator() self.menu["REVIVE_MNG"]:label("-=[ Misc ]=-", "R_MISC_LABEL", true) self.menu["REVIVE_MNG"]:separator()

			self.menu["REVIVE_MNG"]:checkbox("Revive Party Members", "REVIVE_PARTY_MEMBERS", true)
			self.menu["REVIVE_MNG"]:checkbox("Revive Non Party Members", "REVIVE_NON_PARTY_MEMBERS", true)
			self.menu["REVIVE_MNG"]:checkbox("Revive Friendly NPCs", "REVIVE_FRIENDLY_NPCS", true)
			self.menu["REVIVE_MNG"]:checkbox("Revive Friendly Battle Allies", "REVIVE_BATTLE_ALLIES", true)
	end

end

function HealingManager:LoadEsunaManager()

	self.menu:subMenu("Esuna Manager", "ESUNA_MNG")
	self.menu["ESUNA_MNG"]:setIcon("XScripts", "\\Resources\\Icons\\Actions\\esuna.png")

	self.menu["ESUNA_MNG"]:label("-=[ Esuna Manager ]=-", "E_MENU_LABEL", true) self.menu["ESUNA_MNG"]:separator()

		self.menu["ESUNA_MNG"]:checkbox("Esuna Party Members", "ESUNA_PARTY_MEMBERS", true)
		self.menu["ESUNA_MNG"]:checkbox("Esuna Non Party Members", "ESUNA_NON_PARTY_MEMBERS", true)
		self.menu["ESUNA_MNG"]:checkbox("Esuna Friendly NPCs", "ESUNA_FRIENDLY_NPCS", true)
		self.menu["ESUNA_MNG"]:checkbox("Esuna Friendly Battle Allies", "ESUNA_BATTLE_ALLIES", true)

end

function HealingManager:HealWatch()

	local saved_target = TargetManager.Target

	if #self.heal_actions > 0 then

		for i, h in ipairs(self.heal_actions) do
			if h:canUse() and player.manaPercent >= self.menu["HEAL_MNG"]["ACTIONS"][h.name]["MIN_MP"].int and self:ConditionsMet(h) then

				local potency   = self:CalculateHealingPotential(h)

				local player_filter = function (p)

					local max_waste = self.menu["HEAL_MNG"]["ACTIONS"][h.name]["MAX_WASTE"].int
					local waste_percent = potency * max_waste / 100

					if (p.yalmX > h.range) or not h:canUse(p) or (p.missingHealth < (potency - waste_percent)) or p.isDead or not p.ally then
						return false
					end

					if p.id == player.id then
						return true
					end

					if (p.inLocalParty and not self.menu["HEAL_MNG"]["HEAL_PARTY_MEMBERS"].bool)
						or (not p.inLocalParty and not self.menu["HEAL_MNG"]["HEAL_NON_PARTY_MEMBERS"].bool) then
							return false
					end

					return true
				end

				local npc_filter = function (p)

					local max_waste = self.menu["HEAL_MNG"]["ACTIONS"][h.name]["MAX_WASTE"].int
					local waste_percent = potency * max_waste / 100

					return p.yalmX < h.range and h:canUse(p) and p.missingHealth > (potency - waste_percent) and not p.isDead and p.ally
				end

				local players = ObjectManager.Players(player_filter)

				if #players > 0 and self:ShouldHealTable(h, players, potency, saved_target) then
					return true
				end

				if self.menu["HEAL_MNG"]["HEAL_FRIENDLY_NPCS"].bool then
					local npc_players = ObjectManager.NPCPlayers(npc_filter)

					if #npc_players > 0 and self:ShouldHealTable(h, npc_players, potency, saved_target) then
						return true
					end
				end

				if self.menu["HEAL_MNG"]["HEAL_BATTLE_ALLIES"].bool then
					local battle_allies = ObjectManager.Battle(npc_filter)

					if #battle_allies > 0 and self:ShouldHealTable(h, battle_allies, potency, saved_target) then
						return true
					end
				end

				return false
			end
		end
	end

	return false
end

function HealingManager:DeathWatch()

	if self.revive_action ~= nil and self.revive_action.recastTime == 0 then

		local player_filter = function (p)

			if (p.yalmX > self.revive_action.range) or not p.isDead or not p.ally or not self.revive_action:canUse(p) then
				return false
			end

			if (p.inLocalParty and not self.menu["REVIVE_MNG"]["REVIVE_PARTY_MEMBERS"].bool)
				or (not p.inLocalParty and not self.menu["REVIVE_MNG"]["REVIVE_NON_PARTY_MEMBERS"].bool) then
				return false
			end

			return true
		end

		local npc_filter = function (p)
			return p.yalmX < self.revive_action.range and p.isDead and p.ally
		end

		local player_object = ObjectManager.PlayerObject(player_filter)

		if player_object.valid then
			 return self:ReviveObject(player_object)
		end

		if self.menu["REVIVE_MNG"]["REVIVE_FRIENDLY_NPCS"].bool then
			local npc_player = ObjectManager.NPCPlayerObject(npc_filter)
			if npc_player.valid then
				return self:ReviveObject(npc_player)
			end
		end

		if self.menu["REVIVE_MNG"]["REVIVE_BATTLE_ALLIES"].bool then
			local battle_object = ObjectManager.BattleObject(npc_filter)
			if battle_object.valid then
				return self:ReviveObject(battle_object)
			end
		end

	end

	return false
end

function HealingManager:EsunaWatch()

	if not self.esuna:canUse() then
		return false
	end

	local player_filter = function (p)

		if (p.yalmX > self.esuna.range) or p.isDead or not p.ally or not self.esuna:canUse(p) then
			return false
		end

		if (p.inLocalParty and not self.menu["ESUNA_MNG"]["ESUNA_PARTY_MEMBERS"].bool)
			or (not p.inLocalParty and not self.menu["ESUNA_MNG"]["ESUNA_NON_PARTY_MEMBERS"].bool) then
			return false
		end

		return self:HasStatusAilment(p)
	end

	local npc_filter = function (p)
		return p.yalmX < self.esuna.range and not p.isDead and p.ally and self:HasStatusAilment(p)
	end

	local player_object = ObjectManager.PlayerObject(player_filter)

	if player_object.valid then
		return self:EsunaObject(player_object)
	end

	if self.menu["ESUNA_MNG"]["ESUNA_FRIENDLY_NPCS"].bool then
		local npc_player = ObjectManager.NPCPlayerObject(npc_filter)
		if npc_player.valid then
			return self:EsunaObject(npc_player)
		end
	end

	if self.menu["ESUNA_MNG"]["ESUNA_BATTLE_ALLIES"].bool then
		local battle_object = ObjectManager.BattleObject(npc_filter)
		if battle_object.valid then
			return self:EsunaObject(battle_object)
		end
	end


	return false
end

function HealingManager:EnsunaObject(object)

	if self.esuna:canUse(object) then
		print("Using Esuna on : " .. object.name)
		self.esuna:use(object)
		return true
	end

	return false
end

function HealingManager:ReviveObject(object)

	if self.revive_action:canUse(object) then

		if self.menu["REVIVE_MNG"]["USE_SWIFTCAST"].bool and self.swiftcast:canUse() and not player:hasStatus(167) then
			self.swiftcast:use()
		elseif self.menu["REVIVE_MNG"]["USE_SURECAST"].bool and self.surecast:canUse() and not player:hasStatus(160) then
			self.actions.surecast:use()
		end

		print("Reviving " .. object.name)
		self.revive_action:use(object)
		return true
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

function HealingManager:HasStatusAilment(object)

	for i, s in ipairs(object.status) do
		if s.inflictedByActor then
			return true
		end
	end

	return false
end

return HealingManager:new()