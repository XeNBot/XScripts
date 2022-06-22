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
		eclipse    = Action(1, 7381),
		holyspirit = Action(1, 7384),

		rampart    = Action(1, 7531),
		provoke    = Action(1, 7533),
		reprisal   = Action(1, 7535),
		interject  = Action(1, 7538),
		lowblow    = Action(1, 7540),


	}

	self.menu         = nil
	self.lastAction   = 0
	self.lastRotation = 0
	
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

	local target = TargetManager.Target

	if not player:hasStatus(79) and self.actions.ironwill:canUse() then
		log:print("Using Iron Will")
		self.actions.ironwill:use()
	end

	if not target.valid or target.kind ~= 2 or target.subKind ~= 5 or target.pos:dist(player.pos) > 3 then return end


	if ObjectManager.EnemiesAroundObject(player, 5) > 2 or player.healthPercent < 60 then
		if self.actions.reprisal:canUse() and not player:hasStatus(1191) then
			self.actions.reprisal:use()
		elseif self.actions.rampart:canUse() and not player:hasStatus(1193) then
			self.actions.rampart:use()
		end
	end

	--self:ProvokeCheck(log)

	self:Rotate(target)

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
	-- Rage of Halone
	elseif self.lastAction == self.actions.riotblade.id	and self.actions.halone:canUse(target) then
		log:print("Using Rage of Halone on " .. target.name)
		self.actions.halone:use(target)
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
		-- Total Eclipse
	elseif self.actions.eclipse:canUse(target) and ObjectManager.BattleEnemiesAroundObject(target, 5) > 0 then
		log:print("Using Total Eclipse on " .. target.name)
		self.actions.eclipse:use()
		-- Fast Blade
	elseif self.actions.fastblade:canUse(target) then
		log:print("Using Fast Blade on " .. target.name)
		self.actions.fastblade:use(target)
	end

end

function Paladin:ProvokeCheck(log)
	if self.actions.provoke.recastTime == 0 then

		local objects = ObjectManager.Battle(function(obj) return obj.subKind == 5 and obj.isTargetable and obj.pos:dist(player.pos) < 25 and obj.valid and obj.health > 0 end)

		if #objects > 0 then
			for i, obj in ipairs(objects) do
				if obj.valid and obj.targetId ~= 0 and obj.targetId ~= player.id then
					self:Rotate(obj)
					log:print("Provoking " .. obj.name)
					self.actions.provoke:use(obj)
					break
				end
			end
		end


	end
end

function Paladin:Rotate(obj)
	if os.clock() - self.lastRotation > 1 then
		player:rotateTo(obj.pos)
		self.lastRotation = os.clock()
	end
end

return Paladin:new()