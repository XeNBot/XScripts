local XPVEClass  = LoadModule("XScripts", "\\Jobs\\PVE\\XPVEClass")
local Samurai    = Class("Samurai", XPVEClass)

function Samurai:initialize()

	XPVEClass.initialize(self)

	self.class_name           = "Samurai"
	self.class_name_short     = "SAM"
	self.class_category       = "MELEE_DPS"
	self.class_range          = 3

	self.actions = {
		hakaze            = Action(1, 7477),
		jinpu             = Action(1, 7478),
		shifu             = Action(1, 7479),
		yukikaze          = Action(1, 7480),
		gekko             = Action(1, 7481),
		kasha             = Action(1, 7482),
		enpi              = Action(1, 7486),
		midare_setsugekka = Action(1, 7487),
		higanbana         = Action(1, 7489),
		shinten           = Action(1, 7490),
		gyoten            = Action(1, 7492),
		hagakure          = Action(1, 7495),
		guren             = Action(1, 7496),
		meikyo            = Action(1, 7499),

		iajutsu           = Action(1, 7867),

		senei             = Action(1, 16481),
		ikishoten         = Action(1, 16482),
		tsubame           = Action(1, 16483),
		kaeshi_setugekka  = Action(1, 16486),
		shoha             = Action(1, 16487),

		true_north        = Action(1, 7546),

		namiriki          = Action(1, 25781),
		kaeshi_namikiri   = Action(1, 25782)

	}

	self.lvl_90_opener = {
		"gekko", "kasha", "ikishoten", "yukikaze","midare_setsugekka", "senei", 
		"kaeshi_setugekka", "meikyo", "gekko", "shinten", "higanbana", "shinten",
		"namiriki", "shoha", "kaeshi_namikiri", "kasha", "shinten", "gekko",
		"gyoten", "hakaze", "yukikaze", "shinten", "midare_setsugekka", "kaeshi_setugekka"
	}


	self.cool_down_phase = {
		"hakaze", "yukikaze", "hakaze", "jinpu", "gekko", "hakaze", "shifu",
		"kasha", "midare_setsugekka", "hakaze", "yukikaze", "hakaze", "jinpu", "gekko",
		"hakaze", "jinpu", "gekko", "hakaze", "shifu", "kasha"
	}

	self.odd_burst = {
		"midare_setsugekka", "kaeshi_setugekka", "meikyo", "gekko", "higanbana", "gekko", "kasha", "hakaze",
		"yukikaze", "midare_setsugekka"
	}

	self.even_burst = {
		"midare_setsugekka", "senei", "kaeshi_setugekka", "meikyo", "gekko", "higanbana", "namiriki", "kaeshi_namikiri",
		"kasha", "gekko", "hakaze", "yukikaze", "midare_setsugekka"
	}

	self.filler     = {
		"hakaze", "yukikaze", "hagakure"
	}

	self:AddRotation("Lvl 90 Opener", self.lvl_90_opener)
	self:AddRotation("Lvl 50-90 Cooldown Phase", self.cool_down_phase, true) -- 2
	self:AddRotation("Lvl 50-90 Odd Burst", self.odd_burst, true) -- 3
	self:AddRotation("Lvl 50-90 Even Burst", self.even_burst, true) -- 4
	self:AddRotation("Filler", self.filler, true) -- 5

	self.rotation_order = { 2, 3, 5, 2, 4, 5 }
	self.step           = 1
	
end

function Samurai:Tick()

	XPVEClass.Tick(self)

	local target = self.get_target()

	if not self.pre_pull_done and (self.menu["PREPULL_KEY"].keyDown or self.pre_pulling) then
		self.pre_pulling = true
		return self:Prepull()
	end

	if self.target == nil or not self.target.valid then return end

	local opener = self.rotations[1]

	if opener.can_use() and player.classLevel == 90 and not opener.done then
		opener.using = true
		return switch(opener.step, opener.switch)
	end

	if self.step == #self.rotation_order and self.current_rotation == 0 then
		self.step = 1
	end

	if player.classLevel > 50 then


		if self.current_rotation == 0 then
			
			for i, num in ipairs(self.rotation_order) do

				local rotation = self.rotations[num]
				if rotation.can_use() and i >= self.step then
					print("Setting Rotation : " .. rotation.name)
					self.current_rotation = num
					self.step             = self.step + 1
					break
				end
			end

		else
			local rot = self.rotations[self.current_rotation]
			rot.using = true
			switch(rot.step, rot.switch)			
		end
	end
end

function Samurai:Prepull()
	
	local meikyo     = player:getStatus(1233)
	local true_north = player:getStatus(1250)

	if not meikyo.valid and self.actions.meikyo:canUse() then
		self.actions.meikyo:use()
		self.log:print("Using Meikyo Shisui for Prepull!")
	elseif not true_north.valid and meikyo.valid and meikyo.remainingTime <= 10 and self.actions.true_north:canUse() then
		self.actions.true_north:use()
		self.log:print("Using True North for Prepull!")
	elseif true_north.valid and true_north.remainingTime <= 5 then
		self.pre_pull_done = true
		self.pre_pulling   = false
		print("Prepull Ready for Opener!")
	end

end


return Samurai:new()