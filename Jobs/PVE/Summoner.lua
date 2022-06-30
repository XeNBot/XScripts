local Summoner = Class("Summoner")

function Summoner:initialize()

	self.actions = {

		summon      = Action(1, 25798),
		ruiniv      = Action(1, 7426),
		ruinii      = Action(1, 172),
		outburst    = Action(1, 16511),
		gemshine    = Action(1, 25883),
		energydrain = Action(1, 16508),
		painflare   = Action(1, 3578),
		fester      = Action(1, 181),
		searing     = Action(1, 25801),

		deathflare  = Action(1, 3582),
		rekinkle    = Action(1, 25830),
		purgatory   = Action(1, 16515),
		astralflare = Action(1, 25821),
		fountain    = Action(1, 16514),
		astralimp   = Action(1, 25820),

		ifrit       = Action(1, 25805),
		titan       = Action(1, 25806),
		garuda      = Action(1, 25807),
		bahamut     = Action(1, 7427),
		phoenix     = Action(1, 25831),

		ruby        = Action(1, 25832),
		topaz       = Action(1, 25833),
		emerald     = Action(1, 25834),
		cyclone     = Action(1, 25835),
		mbuster     = Action(1, 25836),
		slipstream  = Action(1, 25837),

		aegis       = Action(1, 25799),

	}

	self.menu = nil
	
end

function Summoner:Load(mainMenu)
	
	self.menu = mainMenu

	self.menu["ACTIONS"]["RANGE_DPS_M"]:subMenu("Summoner", "SMN")
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use Aether Stacks", "AETHER", true)
		self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]:checkbox("Use AoE Rotations", "AOE", true)
		
end



function Summoner:Tick(log)

	local menu        = self.menu["ACTIONS"]["RANGE_DPS_M"]["SMN"]
	local actions     = self.actions

	local target = TargetManager.Target

	if not player.hasSummon and self.actions.summon:canUse() then
		self.actions.summon:use()
	end

	if not target.valid or target.kind ~= 2 or target.pos:dist(player.pos) >= 25 then return end

	if self.actions.searing:canUse() then
		self.actions.searing:use()
	elseif self.actions.aegis:canUse() and not player:hasStatus(2702) and player.healthPercent < 80 then
		self.actions.aegis:use()
	end

	self:Combo(target, menu, log)
end

function Summoner:Combo(target, menu, log)

	if self.actions.ruiniv:canUse(target) then
		self.actions.ruiniv:use(target)
	end

	local aoe       = ObjectManager.BattleEnemiesAroundObject(target, 5) > 0
	local attuned   = player.gauge.attunementTime > 0

	self:CheckPrimals(attuned, target, log)

	if not self:PrimalReady() then

		if player.gauge.summonTime > 0 then
			self:ManageSummon(aoe, target, log)
		else

			if self.actions.phoenix:canUse(target) then
				log:print("Summoning Phoenix on " .. target.name)
				self.actions.phoenix:use(target)
			elseif self.actions.bahamut:canUse(target) then
				log:print("Summoning Bahamut on " .. target.name)
				self.actions.bahamut:use(target)
			end
		end

	end

	if player.gauge.aetherStacks > 0 and menu["AETHER"].bool then
		self:UseAetherStacks(aoe, target, log)
	elseif self.actions.energydrain:canUse(target) then
		log:print("Using Energy Drain on " .. target.name)
		self.actions.energydrain:use(target)
	end

	-- Lower Level Spells
	self:LowLevel(aoe, target, log)
end

function Summoner:ManageSummon(aoe, target, log)
	
	if self.actions.rekinkle:canUse(target) then
		log:print("Using Rekinkle on " .. target.name)
		self.actions.rekinkle:use(target)
	elseif self.actions.deathflare:canUse(target) then
		log:print("Using Death Flare " .. target.name)
		self.actions.deathflare:use(target)
	end
	if aoe then
		if self.actions.purgatory:canUse(target) then
			log:print("Using Purgatory " .. target.name)
			self.actions.purgatory:use(target)
		elseif self.actions.astralflare:canUse(target) then
			log:print("Using Astral Flare on " .. target.name)
			self.actions.astralflare:use(target)
		end
	else
		if self.actions.fountain:canUse(target) then
			self.actions.fountain:use(target)
			log:print("Using Fountain on " .. target.name)
		elseif self.actions.astralimp:canUse(target) then
			log:print("Using Astral Implication " .. target.name)
			self.actions.astralimp:use(target)
		end
	end
end

function Summoner:PrimalReady()
	return player.gauge.ifritReady or player.gauge.garudaReady or player.gauge.titanReady
end

function Summoner:CheckPrimals(attuned, target, log)
	
	if attuned then
		if self.actions.mbuster:canUse(target) then
			log:print("Using Mountain  Buster on " .. target.name)
			self.actions.mbuster:use(target)
		elseif self.actions.topaz:canUse(target) then
			log:print("Using Topaz Catastrophe on " .. target.name)
			self.actions.topaz:use(target)
		elseif self.actions.slipstream:canUse(target) then
			log:print("Using Slipstream on " .. target.name)
			self.actions.slipstream:use(target)
		elseif self.actions.emerald:canUse(target) then
			log:print("Using Emerald Catastrophe on " .. target.name)
			self.actions.emerald:use(target)
		elseif self.actions.cyclone:canUse(target) then
			log:print("Using Crimson Cyclone on " .. target.name)
			self.actions.cyclone:use(target)
		elseif self.actions.ruby:canUse(target) then
			log:print("Using Ruby Catastrophe on " .. target.name)
			self.actions.ruby:use(target)
		end

	else
		if player.gauge.ifritReady and self.actions.ifrit:canUse(target) then
			log:print("Summoning Ifrit on " .. target.name)
			self.actions.ifrit:use(target)
		elseif player.gauge.garudaReady and self.actions.garuda:canUse(target) then
			log:print("Summoning Garuda on " .. target.name)
			self.actions.garuda:use(target)
		elseif player.gauge.titanReady and self.actions.titan:canUse(target) then
			log:print("Summoning Titan on " .. target.name)
			self.actions.titan:use(target)
		end

	end
end

function Summoner:UseAetherStacks(aoe, target, log)

	if aoe then

		if self.actions.painflare:canUse(target) then
			log:print("Using Painflare on " .. target.name)
			self.actions.painflare:use(target)
		end
	else		
		if self.actions.fester:canUse(target) then
			log:print("Using Fester on " .. target.name)
			self.actions.fester:use(target)
		end
	end
	
end


function Summoner:LowLevel(aoe, target, log)

	if self.actions.gemshine:canUse(target) then
		log:print("Using Gemshine on" .. target.name)
		self.actions.gemshine:use(target)
	end
	if aoe then
		if self.actions.outburst:canUse(target) then
			log:print("Using Outburst on" .. target.name)
			self.actions.outburst:use(target)
		end
	else
		if self.actions.ruinii:canUse(target) then
			log:print("Using Ruin II on" .. target.name)
			self.actions.ruinii:use(target)
		end		
	end
	
end
	
return Summoner:new()