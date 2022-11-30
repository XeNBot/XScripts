local XPVE = Class("XPVE")

function XPVE:initialize()
	--------------------------------------------------------------------
	-- Classes
	self.bard        = LoadModule("XScripts", "\\Jobs\\PVE\\Bard")
	self.machinist   = LoadModule("XScripts", "\\Jobs\\PVE\\Machinist")
	
	self.summoner    = LoadModule("XScripts", "\\Jobs\\PVE\\Summoner")
	self.blackmage   = LoadModule("XScripts", "\\Jobs\\PVE\\BlackMage")
	self.redmage     = LoadModule("XScripts", "\\Jobs\\PVE\\RedMage")

	self.paladin     = LoadModule("XScripts", "\\Jobs\\PVE\\Paladin")
	self.warrior     = LoadModule("XScripts", "\\Jobs\\PVE\\Warrior")
	self.darkknight  = LoadModule("Xscripts", "\\Jobs\\PVE\\DarkKnight")

	self.ninja       = LoadModule("XScripts", "\\Jobs\\PVE\\Ninja")
	self.reaper      = LoadModule("XScripts", "\\Jobs\\PVE\\Reaper")
	self.samurai     = LoadModule("XScripts", "\\Jobs\\PVE\\Samurai")
	self.dragoon     = LoadModule("XScripts", "\\Jobs\\PVE\\Dragoon")

	self.sage        = LoadModule("XScripts", "\\Jobs\\PVE\\Sage")
	self.whitemage   = LoadModule("XScripts", "\\Jobs\\PVE\\WhiteMage")

	--------------------------------------------------------------------
	-- Utilities
	self.log         = LoadModule("XScripts", "\\Utilities\\Log")
	self.lastToggle  = 0
	--------------------------------------------------------------------
	-- Menus
	self.menu        = LoadModule("XScripts", "\\Menus\\XPVEMenu")	
	
	self.bard:Load(self.menu)
	self.machinist:Load(self.menu)
	
	self.summoner:Load(self.menu)
	self.blackmage:Load(self.menu)
	self.redmage:Load(self.menu, self.log)

	self.paladin:Load(self.menu)
	self.warrior:Load(self.menu)
	self.darkknight:Load(self.menu)

	self.ninja:Load(self.menu)
	self.reaper:Load(self.menu)
	self.samurai:Load(self.menu, self.log)
	self.dragoon:Load(self.menu, self.log)
	
	self.sage:Load(self.menu, self.log)
	self.whitemage:Load(self.menu, self.log)

	--------------------------------------------------------------------
	-- Callbacks
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, function() self:Draw() end)
	--------------------------------------------------------------------	
end

function XPVE:Tick()

	if self.menu["ONOFF_KEY"].keyDown and (os.clock() - self.lastToggle) > 1 then
		local menuName = "ONOFF"

		if self.menu[menuName].bool then 
			self.menu[menuName].bool = false
		else
			self.menu[menuName].bool = true
		end
		self.log:print("Turned PVE Rotations to " .. tostring(self.menu[menuName].bool))
		self.lastToggle = os.clock()
	end

	if player.castInfo.isCasting or not self.menu["ONOFF"].bool then return end

	if player.classJob == 1 or  player.classJob == 19 then
		self.paladin:Tick(self.log)
	elseif player.classJob == 3 or player.classJob == 21 then
		self.warrior:Tick(self.log)
	elseif player.classJob == 5 or player.classJob == 23 then
		self.bard:Tick(self.log)
	elseif player.classJob == 6 or player.classJob == 24 then
		self.whitemage:Tick()
	elseif player.classJob == 7 or player.classJob == 25 then
		self.blackmage:Tick(self.log)
	elseif player.classJob == 22 then
		self.dragoon:Tick()	
	elseif player.classJob == 26 or player.classJob == 27 then
		self.summoner:Tick(self.log)
	elseif player.classJob == 29 or player.classJob == 30 then
		self.ninja:Tick(self.log)
	elseif player.classJob == 31 then
		self.machinist:Tick(self.log)
	elseif player.classJob == 32 then
		self.darkknight:Tick()
	elseif player.classJob == 34 then
		self.samurai:Tick()
	elseif player.classJob == 35 then
		self.redmage:Tick()
	elseif player.classJob == 39 then
	    self.reaper:Tick(self.log)
	elseif player.classJob == 40 then
	    self.sage:Tick()
	end

end

function XPVE:Draw()
	if self.menu["DRAWS"]["ONOFF"].bool then
		Graphics.DrawCircle3D(player.pos, 1, 1, Colors.Yellow)
		Graphics.DrawText3D(Vector3(player.pos.x + player.radius, player.pos.y, player.pos.z), "Rotations On: " .. tostring(self.menu["ONOFF"].bool), 15, RGBA(255, 248, 159, 255))
	end		
end

XPVE:new()