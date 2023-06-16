local XPVPClass = Class("XPVPClass")

function XPVPClass:initialize()
    -- Actions Table
    self.actions = {}

    -- Action Variables
	self.last_action         = 0
	self.action_before_last  = 0

    -- Class Information Variables
        -- Class Id
    self.class_id       = 0

    -- Class Menu Widget
    self.class_menu   = nil

    -- XPVP Module
    self.main_module  = nil

    -- Loads Log
	self.log = LoadModule("XScripts", "\\Utilities\\Log")

    -- Ticker Callback for Ticks
    Callbacks:Add(CALLBACK_PLAYER_TICK, function() self:Ticker() end)
    -- Drawer Callback for Draws
    Callbacks:Add(CALLBACK_PLAYER_DRAW, function() self:Drawer() end)
    -- Action Effect Callbacks
    Callbacks:Add(CALLBACK_ACTION_EFFECT, function(source, pos, action_id, target_id)
		if source.id == player.id and action_id ~= 7 and action_id ~= 8 then
			self.action_before_last = self.last_action
	        self.last_action        = action_id	       
		end
		self:ActionEffect(source, pos, action_id, target_id)
    end)

end

-- Virtual Functions
function XPVPClass:Tick() end
function XPVPClass:Draw() end
function XPVPClass:ActionEffect(source, pos, action_id, target_id) end

function XPVPClass:Drawer()
	if self:IsInPVP() and player.classJob == self.class_id then
		self:Draw()
	end
end

function XPVPClass:Ticker()
	
	if (os.clock() - _G.XPVP.last_guard < 4.5) or player:hasStatus(3054) then return end

	if self:IsInPVP() and player.classJob == self.class_id
	 and (_G.XPVP.current_class == nil or player.classJob ~= _G.XPVP.current_class.class_id) then
		_G.XPVP.current_class = self
		if self.class_menu ~= nil then
			self.class_menu.visible = true
		end	
	elseif player.classJob ~= self.class_id and self.class_menu ~= nil and self.class_menu.visible then
		self.class_menu.visible = false
	end

	if self:CanTick() then
		self:Tick()
	end
end

function XPVPClass:CanTick()
	if _G.XPVP.menu["MOVING_CHECK"].bool and player.isMoving and player.classJob ~= 23 and not player:hasStatus(1325) then 
		return false
	end

    if player.classJob ~= self.class_id or not self:IsInPVP() or player:hasStatus(3054) or player.isCasting then
		return false
    end

    return (self.main_module.menu["COMBO_MODE"].int == 0 and not self.main_module.menu["COMBO_KEY"].keyDown)  
    or (self.main_module.menu["COMBO_MODE"].int ~= 0 and self.main_module.menu["COMBO_KEY"].keyDown) 
    or self.main_module.menu["JUMP_KEY"].keyDown
end

function XPVPClass:SetClassId(class_id)
    self.class_id = class_id
end

function XPVPClass:LoadMenu(name)

	self.class_menu         = Menu(name , true)
	self.class_menu.width   = 250
	self.class_menu.visible = player ~= nil and player.classJob == self.class_id

end

function XPVPClass:SetMainModule(module)
    self.main_module = module
end

function XPVPClass:CanUse(action, target)
	if target == nil then
		return self.actions[action]:canUse()
	end
	return self.actions[action]:canUse(target)
end

function XPVPClass:Use(action, target)

	if target == nil then
		self.actions[action]:use()
		self.log:print("Using " .. self.actions[action].name)
	else
		self.actions[action]:use(target)
		self.log:print("Using " .. self.actions[action].name .. " on " .. target.name)
	end

end

function XPVPClass:IsInPVP()
    -- PVP Maps
	local mapId = 0

	local agentMap = AgentManager.GetAgent("Map")

	if agentMap ~= nil then
		mapId = agentMap.currentMapId
	end

	if not Game.InPvPArea and not Game.InPvPInstance and mapId ~= 51 then 
        return false
    end

    return true
end

function XPVPClass:GetTarget(range)

    return self.main_module:GetTarget(range)

end

return XPVPClass