local XActivity   = Class("XActivity")

-- Activity Types
_G.ACTIVITY_DUTY_SUPPORT       = 0
_G.ACTIVITY_GATHERING          = 1
_G.ACTIVITY_UNKNOWN            = 99

-- Navigation Types
_G.NAV_TYPE_NONE               = 0
_G.NAV_TYPE_DESTINATION        = 1
_G.NAV_TYPE_MOB                = 2
_G.NAV_TYPE_EVENT              = 3
_G.NAV_TYPE_GATHER             = 4

function XActivity:initialize()
    -- Activity Vars
    self.name        = "ACTIVITY_NAME"
    self.type        = ACTIVITY_UNKNOWN
    self.running     = false

    -- Current Navigation
	self.current_nav = nil
	self.nav_type    = 0

    -- Current Map
    self.map_id     = 0

    Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Update() end)
end

function XActivity:StartNav(pos, nav_type, append_end)
    if self.current_nav == nil then
		self.current_nav = Navigation(player.pos, pos, append_end)
	else
		if #self.current_nav.waypoints > 0 then
			self.nav_type = nav_type
			TaskManager:Navigate(self.current_nav, function () self:ResetNav() end)
		else
			print("Bad Navigation Received, Resetting")
			self.current_nav = nil
		end
	end
end

function XActivity:ResetNav()
	TaskManager:Stop()
	self.current_nav = nil
	self.nav_type    = NAV_TYPE_NONE
	TargetManager.SetTarget()
	Keyboard.SendKey(38)
end

function XActivity:SetJob(job)
    if player.classJob == job then return end

	local iconId = job + 62800

	-- Loops through all 18 HotBars
	for hotbar = 0, 17 do
		-- Loops through all 16 slots in hotbar
		for slotId = 0, 15 do
			local slot = HotBarManager[hotbar].slot[slotId]
			if slot.icon == iconId then
				print("Setting Job : " .. CLASS_JOBS[job])
				slot:execute()
				break
			end
		end
	end
end

function XActivity:Update()
    self.map_id = AgentManager.GetAgent("Map").currentMapId
end

return XActivity