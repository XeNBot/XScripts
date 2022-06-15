local XPVE = Class("XPVE")

function XPVE:initialize()
	--------------------------------------------------------------------
	-- Classes
	self.machinist   = LoadModule("XScripts", "\\Jobs\\PVE\\Machinist")
	
	self.summoner    = LoadModule("XScripts", "\\Jobs\\PVE\\Summoner")

	self.paladin     = LoadModule("XScripts", "\\Jobs\\PVE\\Paladin")
	--------------------------------------------------------------------
	-- Utilities
	self.log         = LoadModule("XScripts", "\\Utilities\\Log")
	--------------------------------------------------------------------
	-- Menus
	self.menu        = LoadModule("XScripts", "\\Menus\\XPVEMenu")	
	self.machinist:Load(self.menu)
	self.summoner:Load(self.menu)
	self.paladin:Load(self.menu)
	--------------------------------------------------------------------
	-- Callbacks
	Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Tick() end)
	--------------------------------------------------------------------	
end

function XPVE:Tick()
	if player.classJob == 19 or  player.classJob == 1 then
		self.paladin:Tick(self.log)
	elseif player.classJob == 27 then
		self.summoner:Tick(self.log)
	elseif player.classJob == 31 then
		self.machinist:Tick(self.log)
	end
end

XPVE:new()