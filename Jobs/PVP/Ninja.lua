local XPVPClass   = LoadModule("XScriptsT", "\\Jobs\\PVP\\XPVPClass")
local Ninja  = Class("Ninja", XPVPClass)

function Ninja:initialize()

	XPVPClass.initialize(self)

	self:SetClassId(30)
	self:LoadMenu("Ninja XPVP")
	self:Menu()

	self.actions = {

		-- Aeolian Edge Combo
		spinning_edge  = Action(1, 29500),
		gust_slash     = Action(1, 29501),
		aeolian_edge   = Action(1, 29502),
		assasinate     = Action(1, 29503),
		fuma_shuriken  = Action(1, 29505),
		mug            = Action(1, 29509),
		three_mudra    = Action(1, 29507),
		forked_raiju   = Action(1, 29510),
		bunshin        = Action(1, 29511),
		shukuchi       = Action(1, 29513),
		seiton         = Action(1, 29515),
		fleeting_raiju = Action(1, 29707),
	}

	self.last_shuriken = false

end

function Ninja:Menu()
	
	self.class_menu:subMenu("Aeolian Edge", "AEOLIAN_EDGE")
		self.class_menu["AEOLIAN_EDGE"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Aeolian_Edge.png")
		self.class_menu["AEOLIAN_EDGE"]:checkbox("Use",     "USE", true)

	self.class_menu:subMenu("Fuma Shuriken", "FUMA_SHURIKEN")
		self.class_menu["FUMA_SHURIKEN"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Fuma_Shuriken.png")
		self.class_menu["FUMA_SHURIKEN"]:checkbox("Use",     "USE", true)
		self.class_menu["FUMA_SHURIKEN"]:checkbox("Don't use while using bushin", "BUSHIN", true)

	self.class_menu:subMenu("Mug", "MUG")
		self.class_menu["MUG"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Mug.png")
		self.class_menu["MUG"]:checkbox("Use",     "USE", true)
		self.class_menu["MUG"]:checkbox("Only if can charge Shuriken", "SHURIKEN", true)


	self.class_menu:subMenu("Three Mudra", "THREE_MUDRA")
		self.class_menu["THREE_MUDRA"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Three_Mudra.png")
		self.class_menu["THREE_MUDRA"]:checkbox("Use",     "USE", true)
		self.class_menu["THREE_MUDRA"]:subMenu("Forked Raiju", "FORKED_RAIJU")
			self.class_menu["THREE_MUDRA"]["FORKED_RAIJU"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Forked_Raiju.png")
			self.class_menu["THREE_MUDRA"]["FORKED_RAIJU"]:checkbox("Use", "USE", true)
			self.class_menu["THREE_MUDRA"]["FORKED_RAIJU"]:checkbox("Force during bunshin", "BUNSHIN", true)
		self.class_menu["THREE_MUDRA"]:subMenu("Hyosho Ranryu", "HYOSHO_RANRYU")
			self.class_menu["THREE_MUDRA"]["HYOSHO_RANRYU"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Hyosho_Ranryu.png")
			self.class_menu["THREE_MUDRA"]["HYOSHO_RANRYU"]:checkbox("Use", "USE", true)
		self.class_menu["THREE_MUDRA"]:subMenu("Goka Mekkyaku", "GOKA_MEKKYAKU")
			self.class_menu["THREE_MUDRA"]["GOKA_MEKKYAKU"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Goka_Mekkyaku.png")
			self.class_menu["THREE_MUDRA"]["GOKA_MEKKYAKU"]:checkbox("Use", "USE", true)
			self.class_menu["THREE_MUDRA"]["GOKA_MEKKYAKU"]:slider("Min Enemies", "MIN_ENEMIES", 1, 1, 5, 2)
		self.class_menu["THREE_MUDRA"]:subMenu("Meisui", "MEISUI")
			self.class_menu["THREE_MUDRA"]["MEISUI"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Meisui.png")
			self.class_menu["THREE_MUDRA"]["MEISUI"]:checkbox("Use", "USE", true)
			self.class_menu["THREE_MUDRA"]["MEISUI"]:checkbox("Prioritize", "PRIO", true)
			self.class_menu["THREE_MUDRA"]["MEISUI"]:checkbox("Use on allies with less hp than me", "ALLIES", true)

		self.class_menu["THREE_MUDRA"]:subMenu("Huton", "HUTON")
			self.class_menu["THREE_MUDRA"]["HUTON"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Huton.png")
			self.class_menu["THREE_MUDRA"]["HUTON"]:checkbox("Use", "USE", true)
			self.class_menu["THREE_MUDRA"]["HUTON"]:checkbox("Use when in danger", "USE", true)
			self.class_menu["THREE_MUDRA"]["HUTON"]:slider("Min Enemies", "MIN_ENEMIES", 1, 1, 5, 3)

		self.class_menu["THREE_MUDRA"]:subMenu("Doton", "DOTON")
			self.class_menu["THREE_MUDRA"]["DOTON"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Doton.png")
			self.class_menu["THREE_MUDRA"]["DOTON"]:checkbox("Use", "USE", true)
			self.class_menu["THREE_MUDRA"]["DOTON"]:slider("Min Enemies", "MIN_ENEMIES", 1, 1, 5, 3)

	self.class_menu:subMenu("Bunshin", "BUNSHIN")
		self.class_menu["BUNSHIN"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Bunshin.png")
		self.class_menu["BUNSHIN"]:checkbox("Use",     "USE", true)

	self.class_menu:subMenu("Shukuchi", "SHUKUCHI")
		self.class_menu["SHUKUCHI"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Shukuchi.png")
		self.class_menu["SHUKUCHI"]:checkbox("Use",     "USE", true)
		self.class_menu["SHUKUCHI"]:checkbox("Jump to multiple enemies", "JUMP", true)
		self.class_menu["SHUKUCHI"]:slider("Max Enemies", "MAX_ENEMIES", 1, 1, 5, 3)
		self.class_menu["SHUKUCHI"]:checkbox("Jump to killable enemies", "KS", true)

	self.class_menu:subMenu("Seiton Tenchu", "SEITON_TENCHU")
		self.class_menu["SEITON_TENCHU"]:setIcon("XScriptsT", "\\Resources\\Icons\\Actions\\PvP\\Seiton_Tenchu.png")
		self.class_menu["SEITON_TENCHU"]:checkbox("Use",     "USE", true)

end

function Ninja:Tick()
	local far_target   = self:GetTarget(20)
	local close_target = self:GetTarget(7)

	if player:hasStatus(1316) and close_target.valid and not close_target.ally then
		self:Use("assasinate", close_target)
	end

	if self.class_menu["SEITON_TENCHU"]["USE"].bool then
		self:Seiton()
	end

	if self.class_menu["SHUKUCHI"]["USE"].bool then
		self:Shukuchi(far_target)
	end

	if self.class_menu["THREE_MUDRA"]["USE"].bool then
		self:ManageMudra(far_target)
	end

	if far_target.valid and not far_target.ally then
		if self.class_menu["FUMA_SHURIKEN"]["USE"].bool then
			self:FumaShuriken(far_target)
		end
	end

	if close_target.valid and not close_target.ally then
		if self.class_menu["BUNSHIN"]["USE"].bool and self:CanUse("bunshin") then
			self:Use("bunshin")
		end
		if self.class_menu["MUG"]["USE"].bool then
			self:Mug(close_target)
		end
		if self.class_menu["AEOLIAN_EDGE"]["USE"].bool then
			self:AeolianCombo(close_target)
		end
	end
end

function Ninja:Shukuchi(target)

	if not self:CanUse("shukuchi") then return end

	if self.class_menu["SHUKUCHI"]["KS"].bool then
		local seiton_dmg     = 10000
		ObjectManager.GetEnemyPlayers(function (e)
			local possible_dmg = 12000
			if self:CanUse("seiton", e) then
				possible_dmg = possible_dmg + seiton_dmg
			end
			if e.health < possible_dmg and e.health > 0 then
				self:UsePos("shukuchi", e.pos)
			end
		end)
	end
	if target.healt > 0 and target.valid and not target.ally and target.pos:dist(player.pos) > 7 and self.class_menu["SHUKUCHI"]["JUMP"].bool then
		local max_enemies = self.class_menu["SHUKUCHI"]["MAX_ENEMIES"].int
		if ObjectManager.EnemiesAroundObject(target, 5) < max_enemies then
			self:UsePos("shukuchi", target.pos)
		end
	end
end

function Ninja:ManageMudra(far_target)
	local mudra      = player:getStatus(1317)
	local mudra_menu = self.class_menu["THREE_MUDRA"]
	
	-- Fleeting Raiju Ready
	if player:hasStatus(3211) then
		if far_target.valid and not far_target.ally and self:CanUse("fleeting_raiju", far_target) then
			self:Use("fleeting_raiju", far_target)
		end
	end

	if mudra.valid then
		if mudra_menu["FORKED_RAIJU"]["USE"].bool and mudra_menu["FORKED_RAIJU"]["BUNSHIN"].bool and player:hasStatus(2010) then
			if far_target.valid and not far_target.ally and self:CanUse("forked_raiju", far_target) then
				self:Use("forked_raiju", far_target)
			end
		end
		if mudra_menu["MEISUI"]["USE"].bool and mudra_menu["MEISUI"]["PRIO"].bool then
			self:Meisui()
		end
		if mudra_menu["HUTON"]["USE"].bool and self:CanUse("bunshin") then
			local min_enemies = mudra_menu["HUTON"]["MIN_ENEMIES"].int
			if ObjectManager.EnemiesAroundObject(player, 5) > min_enemies then
				self:Use("bunshin")
			end
		end
		if mudra_menu["GOKA_MEKKYAKU"]["USE"].bool then
			local min_enemies = mudra_menu["GOKA_MEKKYAKU"]["MIN_ENEMIES"].int
			local list = ObjectManager.GetEnemyPlayers(function (e)
				return self:CanUse("mug", e) and ObjectManager.EnemiesAroundObject(e, 5) >= min_enemies
			end)
			if #list > 0 then
				self:Use("mug", list[1])
			end
		end
		if mudra_menu["DOTON"]["USE"].bool and self:CanUse("shukuchi") then
			local min_enemies = mudra_menu["DOTON"]["MIN_ENEMIES"].int
			if ObjectManager.EnemiesAroundObject(player, 5) > min_enemies then
				self:Use("shukuchi")
			end
		end
		if mudra_menu["HYOSHO_RANRYU"]["USE"].bool then
			if far_target.valid and not far_target.ally and self:CanUse("fuma_shuriken", far_target) then
				self:Use("fuma_shuriken", far_target)
			end
		end
		if mudra_menu["FORKED_RAIJU"]["USE"].bool then
			if far_target.valid and not far_target.ally and self:CanUse("forked_raiju", far_target) then
				self:Use("forked_raiju", far_target)
			end
		end
		if mudra_menu["MEISUI"]["USE"].bool then
			self:Meisui()
		end
	elseif ObjectManager.EnemiesAroundObject(player, 20) > 0 then
		self:Use("three_mudra")
	end
end

function Ninja:Meisui()
	if self.class_menu["THREE_MUDRA"]["MEISUI"]["ALLIES"].bool then
		local allies = ObjectManager.GetAllyPlayers(function (ally)
			return not ally.dead and self:CanUse("three_mudra", ally) and
				ally.health < 12000 and ally.health < player.health
		end)
		if #allies > 0 then
			self:Use("three_mudra", allies[1])
		end
	end
	if player.health < 12000 then
		self:Use("three_mudra")
	end
end

function Ninja:Seiton()
	local list = ObjectManager.GetEnemyPlayers(function (e)
		return self:CanUse("seiton", e) and e.health < 10000
	end)

	if #list > 0 then
		self:Use("seiton", list[1])
	end
end

function Ninja:Mug(target)
	if self.class_menu["MUG"]["SHURIKEN"].bool then
		local timer_elapsed = self.actions.fuma_shuriken.timerElapsed
		if timer_elapsed ~= 0 and timer_elapsed  < 20 then 
			return
		end
	end
	if self:CanUse("mug", target) then
		self:Use("mug", target)
	end
end

function Ninja:FumaShuriken(target)
	if self.class_menu["FUMA_SHURIKEN"]["BUSHIN"].bool and player:hasStatus(2010) then
		return
	end
	if not self.last_shuriken and self:CanUse("fuma_shuriken", target) then
		self:Use("fuma_shuriken", target)
	end
end

function Ninja:AeolianCombo(target)
	if self:CanUse("aeolian_edge", target) then
		self:Use("aeolian_edge", target)
	elseif self:CanUse("gust_slash", target) then
		self:Use("gust_slash", target)
	elseif self:CanUse("spinning_edge", target) then
		self:Use("spinning_edge", target)
	end
end

function Ninja:ActionEffect(source, pos, action_id, target_id) 

	if source.id == player.id then
		self.last_shuriken = action_id == self.actions.fuma_shuriken.id
	end
end

return Ninja:new()