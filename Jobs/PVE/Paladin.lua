local Paladin = Class("Paladin")

function Paladin:initialize()

	self.actions = {		
		
		fastblade  = Action(1, 9),
		riotblade  = Action(1, 15),
		shieldbash = Action(1, 16),
		fightorfly = Action(1, 20),
		halone     = Action(1, 21),
		scorn      = Action(1, 23),
		ironwill   = Action(1, 28),
		goring     = Action(1, 3538),
		holyspirit = Action(1, 7384),
		interject  = Action(1, 7538),
		lowblow    = Action(1, 7540),


	}

	self.menu       = nil
	self.lastAction = 0
	
	Callbacks:Add(CALLBACK_ACTION_REQUESTED, function(actionType, actionId, targetId, result)

		if result == 1 and actionType == 1 then
			self.lastAction = actionId
		end

	end)

end

function Paladin:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["TANK"]:subMenu("Paladin", "PLD")
end

function Paladin:Tick(log)
	
	local menu    = self.menu["ACTIONS"]["TANK"]["PLD"]
	local actions = self.actions


	local target = TargetManager.Target

	if not player:hasStatus(79) and self.actions.ironwill:canUse() then
		log:print("Using Iron Will")
		self.actions.ironwill:use()
	end

	if not target.valid or target.kind ~= 2 or target.pos:dist(player.pos) > 3 then return end

	-- tries to cancel target actions
	if target.isCasting then
		if self.actions.interject:canUse(target) then
			log:print("Using Interject on " .. target.name)
			self.actions.interject:use(target)
		elseif self.actions.lowblow:canUse(target) then
			log:print("Using Low Blow on " .. target.name)
			self.actions.lowblow:use(target)
		end
	end

	self:Combo(target, menu, log)
end

function Paladin:Combo(target, menu, log)
	

	-- Riot Blade
	if self.lastAction == self.actions.fastblade.id	and self.actions.riotblade:canUse(target) then
		log:print("Using Riot Blade on " .. target.name)
		self.actions.riotblade:use(target)
	end

	-- Opener
		-- Holy Spirit
	if self.actions.holyspirit:canUse(target) then
		log:print("Using Holy Spirit")
		self.actions.holyspirit:use(target)
		-- Fight or Flight
	elseif self.actions.fightorfly:canUse(target) then
		log:print("Using Fast Fight or Flight " .. target.name)
		self.actions.fightorfly:use(target)
		-- Goring Blade
	elseif self.actions.goring:canUse(target) then
		log:print("Using Goring Blade on " .. target.name)
		self.actions.goring:use(target)
		-- Fast Blade
	elseif self.actions.fastblade:canUse(target) then
		log:print("Using Fast Blade on " .. target.name)
		self.actions.fastblade:use(target)
	end

end

return Paladin:new()