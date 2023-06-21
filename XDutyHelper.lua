local XDutyRunner = Class("XDutyRunner")

function XDutyRunner:initialize()

	--[[ ==== Script Variables ==== ]]--
	self.started         = false
	self.current_mission = nil

	-- Timers
	self.last_enter_duty = 0
	self.last_shortcut   = 0
	self.last_exit       = 0

	-- Stats
	self.stats = {
		missions_started  = 0,
		missions_finished = 0,
		times_died        = 0
	}

	--[[ ==== Interactables === ]]--
	self.interactables = LoadModule("XScripts", "/Enums/Interactables")
	--[[ ==== Log === ]]--
	self.log           = LoadModule("XScripts", "/Utilities/Log")
	--[[ ==== Missions Table ==== ]]--
	self.missions = {
		{

			name           = "Deepcroft",
			tab_index      = 1,
			mission_index  = 2,
			module         = LoadModule("XScripts", "/Missions/Deepcroft"),
			map_ids        = {[8] = true},
			level          = 16,
		},
		{

			name           = "The Bowl of Embers",
			tab_index      = 1,
			mission_index  = 4,
			module         = LoadModule("XScripts", "/Missions/BowlofEmbers"),
			map_ids        = {[35] = true},
			level          = 20,
		},
		{
			name           = "The Thousand Maws of Toto-Rak",
			tab_index      = 1,
			mission_index  = 5,
			module         = LoadModule("XScripts", "/Missions/TotoRak"),
			map_ids        = {[9] = true},
			level          = 24,
		},
		{

			name           = "Brayflox's Longstop",
			tab_index      = 1,
			mission_index  = 7,
			module         = LoadModule("XScripts", "/Missions/Brayflox"),
			map_ids        = {[45] = true},
			level          = 32,
		},
		{

			name           = "The Navel",
			tab_index      = 1,
			mission_index  = 8,
			module         = LoadModule("XScripts", "/Missions/TheNavel"),
			map_ids        = {[33] = true},
			level          = 34,
		},
		{

			name           = "The Stone Vigil",
			tab_index      = 1,
			mission_index  = 9,
			module         = LoadModule("XScripts", "/Missions/StoneVigil"),
			map_ids        = {[37] = true},
			level          = 41,
		},
		{

			name           = "The Howling Eye",
			tab_index      = 1,
			mission_index  = 10,
			module         = LoadModule("XScripts", "/Missions/TheHowlingEye"),
			map_ids        = {[39] = true},
			level          = 44,
		},
		{

			name           = "Snowcloak",
			tab_index      = 1,
			mission_index  = 14,
			module         = LoadModule("XScripts", "/Missions/Snowcloak"),
			map_ids        = {[174] = true},
			level          = 50,
		},
		{

			name           = "Sohm Al",
			tab_index      = 2,
			mission_index  = 1,
			module         = LoadModule("XScriptsT", "/Missions/SohmAl"),
			map_ids        = {[227] = true, [228] = true, [229] = true},
			level          = 53,
		},
		{
		
			name           = "The Antitower",
			tab_index      = 2,
			mission_index  = 6,
			module         = LoadModule("XScripts", "/Missions/TheAntitower"),
			map_ids        = {[277] = true, [278] = true, [279] = true},
			level          = 60,
		},
	}

	for i, mission in ipairs(self.missions) do
		if mission.module ~= nil then
			mission.module:SetMainModule(self)
		else
			print("Failed to set main module in " .. mission.name)
		end
	end

	-- Sets up required callbacks
	self:setupCallbacks()
	-- Initializes Menu
	self:initializeMenu()

	Callbacks:Add(CALLBACK_PLAYER_TICK, self.callbacks.Tick)
	Callbacks:Add(CALLBACK_PLAYER_DRAW, self.callbacks.Draw)

end

function XDutyRunner:Tick()

	local map_id = AgentManager.GetAgent("Map").currentMapId

	if self:CanNotTick() then return end

	if self.current_mission == nil then
		self.current_mission = self.menu["AUTO_PICK"].bool and self:BestDuty() or self.missions[self.menu["MISSION_ID"].int + 1]
	end

	if self.current_mission == nil then return end

	if not self.current_mission.map_ids[map_id] then
		if not TaskManager:IsBusy() then
			TaskManager:EnterDutySupport(
				self.current_mission.tab_index,
				self.current_mission.mission_index,
				self.callbacks.EnterMission)
		end
	end

end

function XDutyRunner:CanNotTick()
	return
		_G.Evading or
		not self.started or
		player.classLevel < 15 or
		(os.clock() - self.last_enter_duty) < 8 or
		(os.clock() - self.last_shortcut) < 8 or
		(os.clock() - self.last_exit) < 8
end

function XDutyRunner:BestDuty()

	local highest_level = 0
	local result = nil

	for i, mission in ipairs(self.missions) do
		if not mission.module.is_trial and	mission.level < player.classLevel and mission.level > highest_level then
			highest_level = mission.level
			result = mission
		end
	end

	return result
end

function XDutyRunner:setupCallbacks()

	self.callbacks = {

		Tick          = function () return self:Tick() end,
		Shortcut = function ()
			self.last_shortcut = os.clock()
			self.log:print("Using Shortcut")
		end,
		ToggleStartBtn = function()
			if not self.started then
				self.menu["BTN_START"].str = "Stop"
				self.started = true
			else
				self.menu["BTN_START"].str = "Start"
				if TaskManager:IsBusy() then
					TaskManager:Stop()
				end
				self.started = false
			end
		end,
		EnterMission = function()
			self.last_enter_duty                = os.clock()
			self.stats.missions_started         = self.stats.missions_started + 1
			self.widget["MISSIONS_ENTERED"].str = "Missions Entered: " .. tostring(self.stats.missions_started)
			self.log:print("Entered Mission: " .. self.current_mission.name)
		end,
		ExitMission = function ()
			self.stats.missions_finished          = self.stats.missions_finished + 1
			self.widget["MISSIONS_FINISHED"].str  = "Missions Finished: " .. tostring(self.stats.missions_finished)
			self.current_mission                  = nil
		end,
		InteractFilter = function(obj) return obj.pos:dist(player.pos) < 4 and obj.isTargetable end
	}

end

function XDutyRunner:initializeMenu()

	self.menu = Menu("XDutyRunner")
	self.menu:label("~=[ XDutyRunner Ver 1.0 ]=~") self.menu:separator() self.menu:space()

	local mission_table = {}

	for i, mission in ipairs(self.missions) do
		table.insert(mission_table, mission.name .. " Lvl " .. tostring(mission.level))
	end

	self.menu:combobox("Mission Selector",       "MISSION_ID", mission_table, 0)
	self.menu:checkbox("Auto Pick Best Mission", "AUTO_PICK", true)

	self.menu:label("~=[ Other Settings ]=~") self.menu:space() self.menu:separator()
		self.menu:subMenu("Draw Settings", "DRAW_SETTINGS")
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Waypoints", "DRAW_WAYPOINTS", false)
			self.menu["DRAW_SETTINGS"]:number("Max Draw Distance", "MAX_DRAW_DISTANCE", 50)
			self.menu["DRAW_SETTINGS"]:checkbox("Draw Debug Info", "DEBUG_INFO", false)


	self.menu:space() self.menu:space()

	self.menu:button("Start", "BTN_START", self.callbacks.ToggleStartBtn)
	self.menu:button("Open Info Widget", "INFO_WIDGET", function() self.widget.visible = true end)

	self.widget = Menu("XDutyRunner Info", true)
	self.widget:label("~=[ Information ]=~") self.menu:separator() self.menu:space()
	self.widget:label("Missions Entered: 0",  "MISSIONS_ENTERED")
	self.widget:label("Missions Finished: 0", "MISSIONS_FINISHED")
	self.widget:label("Times We've Died: 0",  "TIMES_DIED")

end

_G.XDUTY_HELPER = XDutyRunner:new()