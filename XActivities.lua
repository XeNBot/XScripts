local XActivities = Class("XActivities")

-- Activity Types
ACTIVITY_DUTY_SUPPORT       = 0

function XActivities:initialize()

    -- XActivity Vars
    self.duty_supports    = {}

	-- XActivity Stats
	self.stats            = {
		started  = 0,
		finished = 0,
		deaths   = 0,
		run_time = 0
	}

    self.menu = Menu("XActivities")

    self:LoadDutySupportMenu()
	self:LoadGatheringMenu()
	self:LoadMenuStats()
	

	self.xa_queue = LoadModule("XScripts", "/Activities/XActivitiesQueue")
	self.xa_tools = LoadModule("XScripts", "/Activities/XActivitiesTool")
	
	self.xa_queue:Load(self.menu)
	self.xa_tools:Load(self.menu)

    Callbacks:Add(CALLBACK_PLAYER_TICK, function () self:Tick() end)
end

function XActivities:Tick()

	if self.xa_tools.widget.visible then
		self.xa_tools:Tick()
	end

	local activity = self.xa_queue:GetNextActivity()

	if activity ~= nil then
		if activity.type == ACTIVITY_DUTY_SUPPORT then
            self:HandleDutySupportActivity(activity)
        end
		
	end

end

function XActivities:CanTick()
	if self.xa_queue:GetNextActivity() then
		return true
	end
end

function XActivities:HandleDutySupportActivity(activity)

	if not activity.module:IsIn() and not TaskManager:IsBusy() then
		TaskManager:EnterDutySupport(
			activity.module.tab_index,
			activity.module.duty_index
		)
	elseif not activity.module.running then
		activity.module.running = true
		activity.module:Ticker()
	end
end

function XActivities:OnStartDutySupport()

	self.stats.started = self.stats.started + 1
	self.menu["STATS"]["STARTED"].str = "Activities Started:  " .. tostring(self.stats.started)

	self.menu["STATS"]["LIFETIME_STARTED"].int = self.menu["STATS"]["LIFETIME_STARTED"].int + 1

end

function XActivities:OnExitDutySupport()
	
	self.stats.run_time = self.stats.run_time + 1
	self.stats.finished = self.stats.finished + 1

	self.menu["STATS"]["FINISHED"].str = "Activities Finished: " .. tostring(self.stats.finished)

	self.menu["STATS"]["LIFETIME_FINISHED"].int = self.menu["STATS"]["LIFETIME_FINISHED"].int + 1

	local activity = self.xa_queue:GetNextActivity()

	if activity ~= nil then
		if activity.run_type == 1 and player.classLevel >= activity.run_value then
			self.xa_queue:RemoveActivity(activity)
			self.stats.run_time = 0
		elseif activity.run_type == 2 and self.stats.run_time >= activity.run_value then
			self.xa_queue:RemoveActivity(activity)
			self.stats.run_time = 0
		end
	end
end

function XActivities:OnPlayerDeath()

	self.stats.deaths = self.stats.deaths + 1
	self.menu["STATS"]["DEATHS"].str = "Number of Deaths:    " .. tostring(self.stats.deaths)

	self.menu["STATS"]["LIFETIME_DEATHS"].int = self.menu["STATS"]["LIFETIME_DEATHS"].int + 1

end

function XActivities:LoadMenuStats()
	self.menu:subMenu("Stats", "STATS")
	self.menu["STATS"]:label("Session Stats", "SESSION_STATS", true)
	self.menu["STATS"]:separator()
	self.menu["STATS"]:label("Activities Started:  0", "STARTED", true)
	self.menu["STATS"]:label("Activities Finished: 0", "FINISHED", true)
	self.menu["STATS"]:label("Number of Deaths:    0", "DEATHS", true)
	self.menu["STATS"]:separator()
	self.menu["STATS"]:label("Lifetime Stats", "LIFETIME_STATS", true)
	self.menu["STATS"]:separator()
	self.menu["STATS"]:number("Activities Started: ", "LIFETIME_STARTED", 0)
	self.menu["STATS"]:number("Activities Finished: ", "LIFETIME_FINISHED", 0)
	self.menu["STATS"]:number("Number of Deaths: ", "LIFETIME_DEATHS", 0)
	
end

function XActivities:LoadGatheringMenu()
	self.menu:subMenu("Gathering", "GATHERING")
end

function XActivities:LoadDutySupportMenu()

	self.menu:subMenu("Duty Support", "DUTY_SUPPORT")

    local ds_list = GetFileList("/Scripts/XScripts/Activities/DutySupport/")

    for i, duty in ipairs(ds_list) do

		if duty.find(duty, ".lua") then

			local duty_module = LoadModule("XScripts", "/Activities/DutySupport/" .. duty)
			local duty_id     = string.upper(duty_module.name)

			self.duty_supports[duty_id] = duty_module

			table.insert(self.duty_supports, duty_module)

			self.menu["DUTY_SUPPORT"]:subMenu(duty_module.name, duty_id)
				self.menu["DUTY_SUPPORT"][duty_id]:separator()
				self.menu["DUTY_SUPPORT"][duty_id]:label("Activity Info", "FoV", true)
				self.menu["DUTY_SUPPORT"][duty_id]:separator()
				self.menu["DUTY_SUPPORT"][duty_id]:label("FileName: " .. tostring(duty))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Level: " .. tostring(duty_module.level))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Expansion Tab: " .. tostring(duty_module.tab_index))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Duty Selection: " .. tostring(duty_module.duty_index))
				self.menu["DUTY_SUPPORT"][duty_id]:separator()
				self.menu["DUTY_SUPPORT"][duty_id]:label("Field of View", "FoV", true)
				self.menu["DUTY_SUPPORT"][duty_id]:separator()
				self.menu["DUTY_SUPPORT"][duty_id]:label("Battle Objects: " .. tostring(duty_module.battle_fov))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Event Objects: " .. tostring(duty_module.event_fov))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Treasure Objects: " .. tostring(duty_module.treasure_fov))
				self.menu["DUTY_SUPPORT"][duty_id]:label("Line of Sight: " .. tostring(duty_module.los_fov))
				self.menu["DUTY_SUPPORT"][duty_id]:separator()
				self.menu["DUTY_SUPPORT"][duty_id]:label("Queue Options", "Q_Options", true)
				self.menu["DUTY_SUPPORT"][duty_id]:separator()				
				self.menu["DUTY_SUPPORT"][duty_id]:combobox("Run Type", "RUN_TYPE", {"Infinite", "Until Level", "Count"}, 0)
				self.menu["DUTY_SUPPORT"][duty_id]:number("Until Level: ", "UNTIL_LEVEL", player ~= nil and player.classLevel or 0)
				self.menu["DUTY_SUPPORT"][duty_id]:number("Until Count: ", "UNTIL_COUNT", 0)
				self.menu["DUTY_SUPPORT"][duty_id]:button("Add To Queue", "ADD_" .. duty_id, function ()
					self.xa_queue:AddActivity(self:CreateDutySupportActivity(
						self.duty_supports[duty_id],
						self.menu["DUTY_SUPPORT"][duty_id]["RUN_TYPE"].int,
						self.menu["DUTY_SUPPORT"][duty_id]["UNTIL_LEVEL"].int,
						self.menu["DUTY_SUPPORT"][duty_id]["UNTIL_COUNT"].int
					))
					self.xa_queue.widget.visible = true
				end)
				self.menu["DUTY_SUPPORT"]:separator()
		end
    end

end

function XActivities:CreateDutySupportActivity(module, run_type, until_level, until_count)
	local activity = {}

	local id = string.upper(module.name)
	id = id:gsub(" ", "_")
	
	activity.id        = id
	activity.run_type  = run_type
	activity.type      = module.type
	activity.run_value = 0	

	if run_type == 1 then
		 activity.run_value = until_level
	elseif run_type == 2  then
		activity.run_value = until_count
	end

	activity.module    = module

	
	return activity
end

_G.XACTIVITIES = XActivities:new()