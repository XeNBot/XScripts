local Reaper = Class("Reaper")

function Reaper:initialize()

	self.actions = {

		-- Infernal Slice Combo
		slice    = Action(1, 29538),
		waxing   = Action(1, 29539),
		infernal = Action(1, 29540),
		gibbet   = Action(1, 29541),
		gallows  = Action(1, 29542),
		void     = Action(1, 29543),
		cross    = Action(1, 29544),

		soul     = Action(1, 29566),
		harvest  = Action(1, 29546),
		grim     = Action(1, 29547),
		death    = Action(1, 29549),
		hell     = Action(1, 29550),
		arcane   = Action(1, 29552),
		tenebrae = Action(1, 29553),
	}

	self.menu = nil

end

function Reaper:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["MELEE_DPS"]:subMenu("Reaper", "RPR")
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Infernal Slice Combo", "INFERNAL", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Soul Slice",           "SOUL",  true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Plentyful Harvest",    "HARVEST", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:number("Min Soul Sacrifice Stacks",  "HARVEST_MIN", 6)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Grim Swathe",          "GRIM", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Death Warrant",        "DEATH", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Hell's Ingress",           "HELL", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Arcane Crest",             "ARCANE", true)
		self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]:checkbox("Use Tenebrae Lemurum",     "TENEBRAE", true)

end

function Reaper:Enshrouded(target, status, actions)
	-- Communio
	if (status.remainingTime <= 2 or status.count == 1) and actions.tenebrae:canUse(target.id) then
		actions.tenebrae:use(target.id)
	-- Lemure's Slice
	elseif actions.grim:canUse(target.id) then
		actions.grim:use(target.id)
	-- Void Reaping
	elseif actions.void:canUse(target.id) then
		actions.void:use(target.id)
	-- Cross Reaping
	elseif actions.cross:canUse(target.id) then
		actions.cross:use(target.id)
	elseif actions.death:canUse(target.id) then
		actions.death:use(target.id)
	end
end

function Reaper:Tick(getTarget)

	local menu    = self.menu["ACTIONS"]["MELEE_DPS"]["RPR"]
	local actions = self.actions

	local farTarget = getTarget(14)

	if farTarget ~= nil and farTarget.valid and farTarget.pos:dist(player.pos) > 9 and menu["HELL"].bool and actions.hell:canUse(farTarget.id) and not player:hasStatus(2860) then
		player:rotateTo(farTarget.pos)
		actions.hell:use(farTarget.id)
		return
	end

	local target = getTarget(5)

	if target ~= nil and target.valid then

		local enshrouded     = player:getStatus(2863)
		local soul_sacrifice = player:getStatus(3204)

		if enshrouded.valid then 
			self:Enshrouded(target, enshrouded, actions)
		elseif menu["TENEBRAE"].bool and actions.tenebrae:canUse() then
			actions.tenebrae:use()
		elseif menu["DEATH"].bool and actions.death:canUse(target.id) then
			actions.death:use(target.id)
		elseif menu["HARVEST"].bool and actions.harvest:canUse(target.id) and soul_sacrifice.valid and soul_sacrifice.count >= menu["HARVEST_MIN"].int then
			actions.harvest:use(target.id)
		elseif menu["SOUL"].bool and actions.soul:canUse(target.id) and (not soul_sacrifice.valid or (soul_sacrifice.count < 8)) then
			actions.soul:use(target.id)
		elseif menu["GRIM"].bool and actions.grim:canUse(target.id) then
			actions.grim:use(target.id)
		elseif menu["INFERNAL"].bool and actions.gibbet:canUse(target.id) then
			actions.gibbet:use(target.id)
		elseif menu["INFERNAL"].bool and actions.gallows:canUse(target.id) then
			actions.gallows:use(target.id)
		elseif menu["INFERNAL"].bool and actions.infernal:canUse(target.id) then
			actions.infernal:use(target.id)
		elseif menu["INFERNAL"].bool and actions.waxing:canUse(target.id) then
			actions.waxing:use(target.id)
		elseif menu["INFERNAL"].bool and actions.slice:canUse(target.id) then
			actions.slice:use(target.id)
		end
	end
end

return Reaper:new()