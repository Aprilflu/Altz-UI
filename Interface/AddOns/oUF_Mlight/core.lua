local ADDON_NAME, ns = ...
local cfg = ns.cfg

local symbols = "Interface\\Addons\\oUF_Mlight\\media\\PIZZADUDEBULLETS.ttf"

local colors = setmetatable({
	power = setmetatable({
		["MANA"] = {.9, .9, .9},
		["RAGE"] = {.9, .1, .1},
		["FUEL"] = {0, 0.55, 0.5},
		["FOCUS"] = {.9, .5, .1},
		["ENERGY"] = {.9, .9, .1},
		["AMMOSLOT"] = {0.8, 0.6, 0},
		["RUNIC_POWER"] = {.1, .9, .9},
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {__index = oUF.colors.power}),
	class = setmetatable({
		["DEATHKNIGHT"] = { 0.77,  0.12,  0.23},
		["DRUID"] = { 1,  0.49,  0.04},
		["HUNTER"] =  { 203/255,  245/255,  75/255},
		["MAGE"] = { 0,  0.76,  1},
		["MONK"] = { 0.0,  1.00 ,  0.59},
		["PALADIN"] = { 1,  0.22,  0.52},
		["PRIEST"] = { 0.8,  0.87,  .9},
		["ROGUE"] = { 1,  0.91,  0.2},
		["SHAMAN"] = { 32/255,  100/255,  255/255},
		["WARLOCK"] = { 0.6,  0.47,  0.85},
		["WARRIOR"] = { 0.9,  0.65,  0.45},
	}, {__index = oUF.colors.class}),
}, {__index = oUF.colors})

local function multicheck(check, ...)
    for i=1, select('#', ...) do
        if check == select(i, ...) then return true end
    end
    return false
end

local backdrop = {
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {top = 0, left = 0, bottom = 0, right = 0},
}

local frameBD = {
    edgeFile = cfg.glowTex, edgeSize = 3,
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {left = 3, right = 3, top = 3, bottom = 3}
}

-- Unit Menu
local dropdown = CreateFrame('Frame', ADDON_NAME .. 'DropDown', UIParent, 'UIDropDownMenuTemplate')

local function menu(self)
    dropdown:SetParent(self)
    return ToggleDropDownMenu(1, nil, dropdown, 'cursor', 0, 0)
end

local init = function(self)
    local unit = self:GetParent().unit
    local menu, name, id

    if(not unit) then
        return
    end

    if(UnitIsUnit(unit, "player")) then
        menu = "SELF"
    elseif(UnitIsUnit(unit, "vehicle")) then
        menu = "VEHICLE"
    elseif(UnitIsUnit(unit, "pet")) then
        menu = "PET"
    elseif(UnitIsPlayer(unit)) then
        id = UnitInRaid(unit)
        if(id) then
            menu = "RAID_PLAYER"
            name = GetRaidRosterInfo(id)
        elseif(UnitInParty(unit)) then
            menu = "PARTY"
        else
            menu = "PLAYER"
        end
    else
        menu = "TARGET"
        name = RAID_TARGET_ICON
    end

    if(menu) then
        UnitPopup_ShowMenu(self, menu, unit, name, id)
    end
end
UIDropDownMenu_Initialize(dropdown, init, 'MENU')

local createBackdrop = function(parent, anchor, a, m) 
    local frame = CreateFrame("Frame", nil, parent)
	
	local flvl = parent:GetFrameLevel()
	if flvl - 1 >= 0 then
    frame:SetFrameLevel(flvl-1)
	end
	
    frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", -m, m)
    frame:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", m, -m)
	
    frame:SetBackdrop(frameBD)
    frame:SetBackdropColor(.25, .25, .25, a)
    frame:SetBackdropBorderColor(0, 0, 0)

    return frame
end
ns.backdrop = createBackdrop

local fixStatusbar = function(bar)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
end

local createStatusbar = function(parent, tex, layer, height, width, r, g, b, alpha)
    local bar = CreateFrame"StatusBar"
    bar:SetParent(parent)
    if height then
        bar:SetHeight(height)
    end
    if width then
        bar:SetWidth(width)
    end
    bar:SetStatusBarTexture(tex, layer)
    bar:SetStatusBarColor(r, g, b, alpha)
    fixStatusbar(bar)

    return bar
end
ns.createStatusbar = createStatusbar

local createFont = function(parent, layer, f, fs, outline, r, g, b, justify)
    local string = parent:CreateFontString(nil, layer)
    string:SetFont(f, fs, outline)
    string:SetShadowOffset(0, 0)
    string:SetTextColor(r, g, b)
    if justify then
        string:SetJustifyH(justify)
    end

    return string
end

local updateEclipse = function(element, unit)
    if element.hasSolarEclipse then
        element.bd:SetBackdropBorderColor(1, .6, 0)
        element.bd:SetBackdropColor(1, .6, 0)
    elseif element.hasLunarEclipse then
        element.bd:SetBackdropBorderColor(0, .4, 1)
        element.bd:SetBackdropColor(0, .4, 1)
    else
        element.bd:SetBackdropBorderColor(0, 0, 0)
        element.bd:SetBackdropColor(0, 0, 0)
    end
end

local PostAltUpdate = function(altpp, min, cur, max)
    local self = altpp.__owner

    local tPath, r, g, b = UnitAlternatePowerTextureInfo(self.unit, 2)

    if(r) then
        altpp:SetStatusBarColor(r, g, b, 1)
    else
        altpp:SetStatusBarColor(1, 1, 1, .8)
    end 
end

local GetTime = GetTime
local floor, fmod = floor, math.fmod
local day, hour, minute = 86400, 3600, 60

local FormatTime = function(s)
    if s >= day then
        return format("%dd", floor(s/day + 0.5))
    elseif s >= hour then
        return format("%dh", floor(s/hour + 0.5))
    elseif s >= minute then
        return format("%dm", floor(s/minute + 0.5))
    end

    return format("%d", fmod(s, minute))
end

local CreateAuraTimer = function(self,elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed

    if self.elapsed < .2 then return end
    self.elapsed = 0

    local timeLeft = self.expires - GetTime()
    if timeLeft <= 0 then
        self.remaining:SetText(nil)
    else
        self.remaining:SetText(FormatTime(timeLeft))
    end
end

local debuffFilter = {
    --Update this
}

local auraIcon = function(auras, button)
    local count = button.count
    count:ClearAllPoints()
    count:SetPoint("BOTTOMRIGHT", 3, -3)
    count:SetFontObject(nil)
    count:SetFont(cfg.font, 12, "OUTLINE")
    count:SetTextColor(.8, .8, .8)

    auras.disableCooldown = true

    button.icon:SetTexCoord(.1, .9, .1, .9)
    button.bg = createBackdrop(button, button,0,3)

    if cfg.auraborders then
        auras.showDebuffType = true
        button.overlay:SetTexture(cfg.buttonTex)
        button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
        button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        button.overlay:SetTexCoord(0, 1, 0.02, 1)
    else
        button.overlay:Hide()
    end

    local remaining = createFont(button, "OVERLAY", cfg.font, 12, "OUTLINE", .8, .8, .8)
    remaining:SetPoint("TOPLEFT", -3, 2)
    button.remaining = remaining
end

local PostUpdateIcon
do
    local playerUnits = {
        player = true,
        pet = true,
        vehicle = true,
    }

    PostUpdateIcon = function(icons, unit, icon, index, offset)
        local name, _, _, _, dtype, duration, expirationTime, unitCaster = UnitAura(unit, index, icon.filter)

        local texture = icon.icon
        if playerUnits[icon.owner] or debuffFilter[name] or UnitIsFriend('player', unit) or not icon.debuff then
            texture:SetDesaturated(false)
        else
            texture:SetDesaturated(true)
        end

        if duration and duration > 0 then
            icon.remaining:Show()
        else
            icon.remaining:Hide()
        end

        icon.duration = duration
        icon.expires = expirationTime
        icon:SetScript("OnUpdate", CreateAuraTimer)
    end
end

local aurafilter = {
    ["Chill of the Throne"] = true,
}

local CustomFilter = function(icons, ...)
    local _, icon, name, _, _, _, _, _, _, caster = ...

    if aurafilter[name] then
        return false
    end

    local isPlayer

    if multicheck(caster, 'player', 'vechicle') then
        isPlayer = true
    end

    if((icons.onlyShowPlayer and isPlayer) or (not icons.onlyShowPlayer and name)) then
        icon.isPlayer = isPlayer
        icon.owner = caster
        return true
    end
end

local PostCastStart = function(castbar, unit)
    if unit ~= 'player' then
        if castbar.interrupt then
            castbar.Backdrop:SetBackdropBorderColor(1, .9, .4)
            castbar.Backdrop:SetBackdropColor(1, .9, .4)
        else
            castbar.Backdrop:SetBackdropBorderColor(0, 0, 0)
            castbar.Backdrop:SetBackdropColor(0, 0, 0)
        end
    end
end

local CustomTimeText = function(castbar, duration)
    if castbar.casting then
        castbar.Time:SetFormattedText("%.1f / %.1f", duration, castbar.max)
    elseif castbar.channeling then
        castbar.Time:SetFormattedText("%.1f / %.1f", castbar.max - duration, castbar.max)
    end
end

--========================--
--  Castbars
--========================--
local castbar = function(self, unit)
    local u = unit:match('[^%d]+')
    if multicheck(u, "target", "player", "focus", "boss") then
        local cb = createStatusbar(self, cfg.texture, "OVERLAY", 5, nil, 0.2, .8, 1, 1)
        cb:SetToplevel(true)

        cb.Spark = cb:CreateTexture(nil, "OVERLAY")
        cb.Spark:SetBlendMode("ADD")
        cb.Spark:SetAlpha(0.5)
        cb.Spark:SetHeight(30)

        local cbbg = cb:CreateTexture(nil, "BACKGROUND")
        cbbg:SetAllPoints(cb)
        cbbg:SetTexture(cfg.texture)
        cbbg:SetVertexColor(.1,.1,.1)

        cb.Time = createFont(cb, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1)
        cb.Time:SetPoint("RIGHT", cb, -2, 0)
        cb.CustomTimeText = CustomTimeText

        cb.Text = createFont(cb, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1, "LEFT")
        cb.Text:SetPoint("LEFT", cb, 2, 0)
        cb.Text:SetPoint("RIGHT", cb.Time, "LEFT")

        cb.Icon = cb:CreateTexture(nil, 'ARTWORK')
        cb.Icon:SetSize(cfg.cbIconsize, cfg.cbIconsize)
        cb.Icon:SetTexCoord(.1, .9, .1, .9)
		
		--safezone for castbar of player
        if (unit == "player") then
            cb.SafeZone = cb:CreateTexture(nil,'ARTWORK')
            cb.SafeZone:SetPoint('TOPRIGHT')
            cb.SafeZone:SetPoint('BOTTOMRIGHT')
            cb.SafeZone:SetTexture(cfg.texture)
            cb.SafeZone:SetVertexColor(1,1,0.3, 1)
        end
		
		if cfg.CBuserplaced then
		    cb:SetWidth(cfg.CBwidth-cfg.cbIconsize-7)
		    if (unit == "player") then
			cb:SetPoint(unpack(cfg.playerCBposition))
            cb.Icon:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", -7, 0)
			elseif unit == "target" then
			cb:SetPoint(unpack(cfg.targetCBposition))
			cb.Icon:SetPoint("BOTTOMLEFT", cb, "BOTTOMRIGHT", 7, 0)
			elseif unit == "focus" then
			cb:SetPoint(unpack(cfg.focusCBposition))
			cb.Icon:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", -7, 0)
			else
		    cb:SetPoint("BOTTOMLEFT", self, "TOPLEFT", cfg.cbIconsize+5, 50)
            cb.Icon:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", -7, 0)
			cb:SetWidth(cfg.width-cfg.cbIconsize-7)
			end
		else
		    if (unit == "player") then
                cb:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -cfg.cbIconsize-5, 50)
                cb.Icon:SetPoint("BOTTOMLEFT", cb, "BOTTOMRIGHT", 7, 0)
				cb:SetWidth(cfg.width-cfg.cbIconsize-7)
			else
		        cb:SetPoint("BOTTOMLEFT", self, "TOPLEFT", cfg.cbIconsize+5, 50)
                cb.Icon:SetPoint("BOTTOMRIGHT", cb, "BOTTOMLEFT", -7, 0)
				cb:SetWidth(cfg.width-cfg.cbIconsize-7)
		    end
		end
		
        cb.Backdrop = createBackdrop(cb, cb,0,3)
        cb.IBackdrop = createBackdrop(cb, cb.Icon,0,3)

        cb.PostCastStart = PostCastStart
        cb.PostChannelStart = PostCastStart

        cb.bg = cbbg
        self.Castbar = cb
    end
end

--========================--
--  Shared
--========================--
--[[ Update health bar colour ]]
local UpdateHealth = function(self, event, unit)

	self.colors = colors
	
	if(self.unit == unit) then
		local r, g, b
		local min, max, perc

		self.colors.smooth = {1,0,0, 1,1,0, 1,1,0}
		
		min, max = UnitHealth(unit), UnitHealthMax(unit)
		perc = min/max
		
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			r, g, b = .6, .6, .6
		elseif(unit == "pet") then
			local _, class = UnitClass("player")
			if cfg.classcolormode then
				r, g, b = unpack(self.colors.class[class])
			else
				r, g, b = self.ColorGradient(perc, unpack(self.colors.smooth))
			end
		elseif(UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			if cfg.classcolormode then
				if class then r, g, b = unpack(self.colors.class[class]) else r, g, b = 1, 1, 1 end
			else
				r, g, b = self.ColorGradient(perc, unpack(self.colors.smooth))
			end
		elseif(unit and unit:find("boss%d")) then
			r, g, b = self.ColorGradient(perc, unpack(self.colors.smooth))
		elseif unit then
			r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player") or 5])
		end

		self.Health:GetStatusBarTexture():SetGradient("VERTICAL", r, g, b, r/3, g/3, b/3)
	end
end

ns.updatehealthcolor = UpdateHealth

local func = function(self, unit)
	
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    self:RegisterForClicks"AnyUp"
	
	self.menu = menu
	
    -- height, width and scale --
    if(unit == "targettarget" or unit == "focustarget" or unit == "pet") then
        self:SetSize(cfg.width1, cfg.height)
	else
	    self:SetSize(cfg.width, cfg.height)
    end
    self:SetScale(cfg.scale)
	
	-- shadow border for health bar --
    createBackdrop(self, self, 0, 3)

	-- health bar --
    local hp = createStatusbar(self, cfg.texture, nil, cfg.height, nil, .1, .1, .1, 0.5)
    hp:SetPoint"TOP"
    hp:SetPoint"LEFT"
    hp:SetPoint"RIGHT"
    hp.frequentUpdates = true
    hp.Smooth = true

	-- health and power text on health frame --
    if not (unit == "targettarget" or unit == "focustarget" or unit == "pet") then
        local hpt = createFont(hp, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1)
        hpt:SetPoint("RIGHT", hp, -2, 0)
        local pt = createFont(hp, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1)
        pt:SetPoint("LEFT", hp, 2, 0)
		
        self:Tag(hpt, '[Mlight:hp]')
		self:Tag(pt, '[Mlight:pp]')
    end
	
		-- reverse fill health --
		
	if not cfg.classcolormode then
		hp:SetReverseFill(true)
	end
	
	hp.PostUpdate = function(hp, unit, min, max)
	
		if not cfg.classcolormode then
			if UnitIsDeadOrGhost(unit) then hp:SetValue(0)
			else hp:SetValue(max - hp:GetValue()) end
		end
		
		return UpdateHealth(hp:GetParent(), 'PostUpdateHealth', unit)
	end
	
    self.Health = hp

	-- backdrop color --
	local gradient = hp:CreateTexture(nil, "BACKGROUND")
	gradient:SetPoint("TOPLEFT")
	gradient:SetPoint("BOTTOMRIGHT")
	gradient:SetTexture(cfg.texture)
	if cfg.classcolormode then
		gradient:SetGradientAlpha("VERTICAL", .6, .6, .6, .6, .1, .1, .1, .6)
	else
		gradient:SetGradientAlpha("VERTICAL", .3, .3, .3, .2, .1, .1, .1, .2)
	end
	self.gradient = gradient

	-- power bar --
    if not (unit == "targettarget" or unit == "focustarget") then
    local pp = createStatusbar(self, cfg.texture, nil, cfg.height*-(cfg.hpheight-1), nil, 1, 1, 1, 1)
    pp:SetPoint"LEFT"
    pp:SetPoint"RIGHT"
	pp:SetPoint("TOP", self, "BOTTOM", 0, -3)

    pp.frequentUpdates = false
    pp.Smooth = true
		
	-- power color --	
    if not cfg.classcolormode then
        pp.colorClass = true
		pp.colorReaction = true
    else
        pp.colorPower = true
    end
	
	-- shadow border for health bar --	
    createBackdrop(pp, pp, 1, 3)
	
    self.Power = pp
    end

	-- altpower bar --
	local u = unit:match('[^%d]+')
    if multicheck(u, "player", "boss") then
    local altpp = createStatusbar(self, cfg.texture, nil, 4, nil, 1, 1, 1, .8)
    altpp:SetPoint('TOPLEFT', self, 'TOPLEFT', 20, 2)
    altpp:SetWidth(100)
	altpp:SetFrameLevel(self:GetFrameLevel()+10)
    altpp.bg = altpp:CreateTexture(nil, 'BORDER')
    altpp.bg:SetAllPoints(altpp)
    altpp.bg:SetTexture(cfg.texture)
    altpp.bg:SetVertexColor(.1, .1, .1)
    altpp.bd = createBackdrop(altpp, altpp,0,3)

    altpp.Text =  createFont(altpp, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1)
    altpp.Text:SetPoint("CENTER")
    self:Tag(altpp.Text, "[Mlight:altpower]")

    altpp.PostUpdate = PostAltUpdate
    self.AltPowerBar = altpp
    end
	
	-- little thing around unit frames --
    local leader = hp:CreateTexture(nil, "OVERLAY")
    leader:SetSize(12, 12)
    leader:SetPoint("BOTTOMLEFT", hp, "BOTTOMLEFT", 5, -5)
    self.Leader = leader

    local masterlooter = hp:CreateTexture(nil, 'OVERLAY')
    masterlooter:SetSize(12, 12)
    masterlooter:SetPoint('LEFT', leader, 'RIGHT')
    self.MasterLooter = masterlooter

    local LFDRole = hp:CreateTexture(nil, 'OVERLAY')
    LFDRole:SetSize(12, 12)
    LFDRole:SetPoint('LEFT', masterlooter, 'RIGHT')
    self.LFDRole = LFDRole

    local Combat = hp:CreateTexture(nil, 'OVERLAY')
    Combat:SetSize(20, 20)
    Combat:SetPoint('BOTTOMRIGHT', hp, 3, -26)
    self.Combat = Combat
	
    local ricon = hp:CreateTexture(nil, 'OVERLAY')
    ricon:SetPoint("CENTER", hp, "CENTER", 0, 0)
    ricon:SetSize(16, 16)
    self.RaidIcon = ricon
	
	-- name --
    local name = createFont(hp, "OVERLAY", cfg.font, cfg.fontsize, cfg.fontflag, 1, 1, 1)
	name:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -cfg.height*(1-cfg.hpheight)-5)
    if(unit == "player" or unit == "pet") then
        name:Hide()
	elseif(unit == "targettarget" or unit == "focustarget") then
	    name:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -2)
        if cfg.classcolormode then
            self:Tag(name, '[Mlight:shortname]')
        else
            self:Tag(name, '[Mlight:color][Mlight:shortname]')
        end
    elseif cfg.classcolormode then
        self:Tag(name, '[Mlight:info] [Mlight:name]')
    else
        self:Tag(name, '[Mlight:info] [Mlight:color][Mlight:name]')
    end
    
    if cfg.castbars then
        castbar(self, unit)
    end
	
    self.FadeMinAlpha = 0
	self.FadeInSmooth = 0.4
	self.FadeOutSmooth = 1.5
    self.FadeCasting = true
    self.FadeCombat = true
    self.FadeTarget = true
    self.FadeHealth = true
    self.FadePower = true
    self.FadeHover = true

end

local UnitSpecific = {

    --========================--
    --  Player
    --========================--
    player = function(self, ...)
        func(self, ...)
		
	
        local _, class = UnitClass("player")
		
        -- Runes, Shards, HolyPower --
        if multicheck(class, "DEATHKNIGHT", "WARLOCK", "PALADIN", "MONK", "SHAMAN", "PRIEST") then
            local count
            if class == "DEATHKNIGHT" then 
                count = 6
			elseif class == "MONK" then
				count = UnitPowerMax("player" , SPELL_POWER_LIGHT_FORCE)
			elseif class == "SHAMAN" then
				count = 4
			elseif class == "WARLOCK" then
				count = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
            elseif class == "PALADIN" then
                count = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)
			elseif class == "PRIEST" then
				count = UnitPowerMax("player", SPELL_POWER_SHADOW_ORBS)
            end

            local bars = CreateFrame("Frame", nil, self)

			if cfg.Ruserplaced and class == "DEATHKNIGHT" then
			bars:SetSize(cfg.Rwidth,cfg.Rheight)
			bars:SetPoint(unpack(cfg.Runesp))
			createBackdrop(bars, bars, 0, 3)
			else
			bars:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -8)
            bars:SetSize(cfg.width, 10)
			end

            local i = count
            for index = 1, count do
                bars[i] = createStatusbar(bars, cfg.texture, nil, cfg.height*-(cfg.hpheight-1), (cfg.width+3)/count-3, 1, 1, 1, 1)

                if class == "WARLOCK" or class == "PRIEST" then
                    bars[i]:SetStatusBarColor(253/255, 91/255, 176/255)
                elseif class == "PALADIN" or class == "MONK" then
                    bars[i]:SetStatusBarColor(255/255, 255/255, 53/255)
                end 
				
                if cfg.Ruserplaced and class == "DEATHKNIGHT" then
				bars[i]:SetSize((cfg.Rwidth+3)/count-3,cfg.Rheight)
				end
				
                if i == count then
                    bars[i]:SetPoint("TOPRIGHT", bars, "TOPRIGHT")
                else
                    bars[i]:SetPoint("RIGHT", bars[i+1], "LEFT", -3, 0)
                end

                bars[i].bg = bars[i]:CreateTexture(nil, "BACKGROUND")
                bars[i].bg:SetAllPoints(bars[i])
                bars[i].bg:SetTexture(0.3, 0.3, 0.3, 1)

                bars[i].bd = createBackdrop(bars[i], bars[i],1,3)
                i=i-1
            end

            if class == "DEATHKNIGHT" then
                bars[3], bars[4], bars[5], bars[6] = bars[5], bars[6], bars[3], bars[4]
                self.Runes = bars
            elseif class == "WARLOCK" then
                self.SoulShards = bars
				if cfg.customsp then bars:Hide() end
            elseif class == "PALADIN" then
                self.HolyPower = bars
				if cfg.customsp then bars:Hide() end
			elseif class == "MONK" then
				self.Harmony = bars
				if cfg.customsp then bars:Hide() end
			elseif class == "SHAMAN" then
				self.TotemBar = bars
			elseif class == "PRIEST" then
				self.ShadowOrbs = bars
				if cfg.customsp then bars:Hide() end
            end
        end
		
		-- the special soulshards/holypower --
		if cfg.customsp then
        local sp = CreateFrame("Frame", nil, self)
		local spt = createFont(sp, "OVERLAY", symbols, cfg.spfontsize, "OUTLINE", nil, nil, nil)
		spt:SetPoint(unpack(cfg.spp))
		self:Tag(spt, '[Mlight:sp]')
        end

		-- eclipse bar --
        if class == "DRUID" then
            local ebar = CreateFrame("Frame", nil, self)
		    local Ewidth,Eheight
			
			if cfg.Euserplaced then
			Ewidth = cfg.Ewidth 
			Eheight = cfg.Eheight
			else
			Ewidth = cfg.width
			Eheight = cfg.height*-(cfg.hpheight-1)
			end
			
			if cfg.Euserplaced then
			ebar:SetPoint(unpack(cfg.Eclipsep))
			else
            ebar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -12)
			end
			
			ebar:SetSize(Ewidth, Eheight)
            ebar.bd = createBackdrop(ebar, ebar,1,3)

            local lbar = createStatusbar(ebar, cfg.texture, nil, Eheight, Ewidth, .2, .9, 1, 1)
            lbar:SetPoint("LEFT", ebar, "LEFT")
            ebar.LunarBar = lbar

            local sbar = createStatusbar(ebar, cfg.texture, nil, Eheight, Ewidth, 1, 1, 0.15, 1)
            sbar:SetPoint("LEFT", lbar:GetStatusBarTexture(), "RIGHT")
            ebar.SolarBar = sbar

            ebar.Spark = sbar:CreateTexture(nil, "OVERLAY")
            ebar.Spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
            ebar.Spark:SetBlendMode("ADD")
            ebar.Spark:SetAlpha(0.5)
            ebar.Spark:SetHeight(25)
            ebar.Spark:SetPoint("LEFT", sbar:GetStatusBarTexture(), "LEFT", -15, 0)

            self.EclipseBar = ebar
            self.EclipseBar.PostUnitAura = updateEclipse
        end
		
		-- resting Zzz ---
		local ri = createFont(self.Health, "OVERLAY", cfg.font, 10, "OUTLINE", nil, nil, nil)
		ri:SetPoint("CENTER", self.Health, "CENTER",0,-2)
		ri:SetText("|cff8AFF30Zzz|r")
		self.Resting = ri
		
		-- auras --
        if cfg.auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(cfg.height*2)
            debuffs:SetWidth(cfg.width)
            debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            debuffs.spacing = 6
            debuffs.size = cfg.height+2
            debuffs.initialAnchor = "BOTTOMRIGHT"
			debuffs["growth-x"] = "LEFT"
            debuffs["growth-y"] = "UP"


            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon
            debuffs.CustomFilter = CustomFilter

            self.Debuffs = debuffs
            self.Debuffs.num = 12 
        end
    end,

    --========================--
    --  Target
    --========================--
    target = function(self, ...)
        func(self, ...)
		
		-- auras --
        if cfg.auras then
            local Auras = CreateFrame("Frame", nil, self)
            Auras:SetHeight(cfg.height*2)
            Auras:SetWidth(cfg.width)
            Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            Auras.spacing = 6
            Auras.gap = true
            Auras.size = cfg.height+2
            Auras.initialAnchor = "BOTTOMLEFT"

            Auras.PostCreateIcon = auraIcon
            Auras.PostUpdateIcon = PostUpdateIcon
            Auras.CustomFilter = CustomFilter
            Auras.onlyShowPlayer = cfg.onlyShowPlayer
			
            self.Auras = Auras
            self.Auras.numDebuffs = 8
            self.Auras.numBuffs = 16
        end

		-- combo points --
        local cpoints = createFont(self, "OVERLAY", symbols, cfg.combofontsize, "THINOUTLINE",1,1,1)
        cpoints:SetPoint(unpack(cfg.combop))
        self:Tag(cpoints, '[Mlight:cp]')
    end,

    --========================--
    --  Focus
    --========================--
    focus = function(self, ...)
        func(self, ...)

        if cfg.auras then 
            local Auras = CreateFrame("Frame", nil, self)
            Auras:SetHeight(cfg.height*2)
            Auras:SetWidth(cfg.width)
            Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            Auras.spacing = 6
            Auras.gap = true
            Auras.size = cfg.height+2
            Auras.initialAnchor = "BOTTOMLEFT"

            Auras.PostCreateIcon = auraIcon
            Auras.PostUpdateIcon = PostUpdateIcon
            Auras.CustomFilter = CustomFilter

            self.Auras = Auras
            self.Auras.numDebuffs = 8
            self.Auras.numBuffs = 16
        end
    end,

    --========================--
    --  Focus Target
    --========================--
    focustarget = function(self, ...)
        func(self, ...)

    end,

    --========================--
    --  Pet
    --========================--
    pet = function(self, ...)
        func(self, ...)

        if cfg.auras then 
            local debuffs = CreateFrame("Frame", nil, self)
            debuffs:SetHeight(cfg.height)
            debuffs:SetWidth(cfg.width)
            debuffs:SetPoint("RIGHT", self, "LEFT", -5, 0)
            debuffs.spacing = 6
            debuffs.size = cfg.height
            debuffs.initialAnchor = "BOTTOMRIGHT"
	        debuffs["growth-x"] = "LEFT"
            debuffs["growth-y"] = "UP"

            debuffs.PostCreateIcon = auraIcon
            debuffs.PostUpdateIcon = PostUpdateIcon

            self.Debuffs = debuffs
            self.Debuffs.num = 5
        end
    end,

    --========================--
    --  Target Target
    --========================--
    targettarget = function(self, ...)
        func(self, ...)

    end,

    --========================--
    --  Boss
    --========================--
    boss = function(self, ...)
        func(self, ...)
	
    -- width --	
	self:SetWidth(150)
	self.Power:SetWidth(150)
	
	if cfg.castbars then	
	self.Castbar:SetWidth(150-cfg.cbIconsize-5)
	self.Castbar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", cfg.cbIconsize+5, 5)
	end
	
    -- auras --	
    local Auras = CreateFrame("Frame", nil, self)
    Auras:SetHeight(cfg.height)
    Auras:SetWidth(cfg.width)
    Auras:SetPoint("RIGHT", self, "LEFT", -5, 0)
    Auras.spacing = 6
    Auras.gap = true
    Auras.size = cfg.height
	Auras.initialAnchor = "BOTTOMRIGHT"
	Auras["growth-x"] = "LEFT"
    Auras["growth-y"] = "UP"

    Auras.PostCreateIcon = auraIcon
    Auras.PostUpdateIcon = PostUpdateIcon
    Auras.CustomFilter = CustomFilter
	Auras.onlyShowPlayer = true

    self.Auras = Auras
    self.Auras.numDebuffs = 4
    self.Auras.numBuffs = 3
    end,
}

oUF:RegisterStyle("Mlight", func)
for unit,layout in next, UnitSpecific do
    oUF:RegisterStyle('Mlight - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
    if(UnitSpecific[unit]) then
        self:SetActiveStyle('Mlight - ' .. unit:gsub("^%l", string.upper))
    elseif(UnitSpecific[unit:match('[^%d]+')]) then -- boss1 -> boss
        self:SetActiveStyle('Mlight - ' .. unit:match('[^%d]+'):gsub("^%l", string.upper))
    else
        self:SetActiveStyle'Mlight'
    end

    local object = self:Spawn(unit)
    object:SetPoint(...)
    return object
end

oUF:Factory(function(self)
    spawnHelper(self, "player","TOPRIGHT","UIParent","BOTTOM", -cfg.playerx, cfg.playery)
    spawnHelper(self, "target","TOPLEFT","UIParent","BOTTOM", cfg.playerx, cfg.playery)
    spawnHelper(self, "targettarget", "TOPLEFT", "UIParent", "BOTTOM", cfg.playerx +cfg.width +10, cfg.playery)
    spawnHelper(self, "focus","BOTTOMLEFT","UIParent","BOTTOM", cfg.playerx, cfg.playery + cfg.focusy)
    spawnHelper(self, "focustarget", "BOTTOMLEFT", "UIParent", "BOTTOM", cfg.playerx +cfg.width +10, cfg.playery + cfg.focusy)
    spawnHelper(self, "pet", "TOPRIGHT", "UIParent", "BOTTOM", -(cfg.playerx +cfg.width +10), cfg.playery)

    if cfg.bossframes then
        for i = 1, MAX_BOSS_FRAMES do
            spawnHelper(self,'boss' .. i, "RIGHT", -8, 170 - (60 * i))
        end
    end
end)

---------------------------------------------------------------------------
-- helper functions for user
---------------------------------------------------------------------------

local Helper = CreateFrame"Frame"
Helper:SetFrameStrata"HIGH"

local xleft, xright, ybottom, ytop
local Ccolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

local centertext = Helper:CreateFontString(nil, "OVERLAY")
centertext:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
centertext:SetFont(cfg.font, 20, "OUTLINE")
centertext:SetTextColor(Ccolor.r, Ccolor.g, Ccolor.b)
centertext:SetText("Target and focus yourself. \n Move the cursor on each line to see it's height/width and understand how the value works. \n \n /mhelp to show or hide this frame.")

local createhelpBackdrop = function(parent) 
    local frame = CreateFrame("Frame", nil, parent)
	
	local flvl = parent:GetFrameLevel()
	if flvl - 1 >= 0 then
    frame:SetFrameLevel(flvl-1)
	end
	
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -5)
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -5, 5)
	
    frame:SetBackdrop(frameBD)

    return frame
end

local function createX()
	f = CreateFrame("Frame", nil, Helper)
	f:SetSize(cfg.playerx, 18)
	f:SetFrameStrata("TOOLTIP")
	
	local bg = createhelpBackdrop(f)
	bg:SetBackdropColor(Ccolor.r/2, Ccolor.g/2, Ccolor.b/2)
	bg:SetBackdropBorderColor(0.3, 0.3, 0.3) 
	
	f.bg = bg
	
	return f
end

xleft = createX()
xleft:SetPoint("RIGHT", UIParent, "BOTTOM", 0, cfg.playery)

xright = createX()
xright:SetPoint("LEFT", UIParent, "BOTTOM", 0, cfg.playery)

local xtext = Helper:CreateFontString(nil, "OVERLAY")
xtext:SetPoint("BOTTOM", xleft, "BOTTOM", 0, 15)
xtext:SetFont(cfg.font, 20, "OUTLINE")
xtext:SetTextColor(0.5, 0.5, 0.5)
xtext:SetText("cfg.playerx")
xtext:SetShadowOffset(0,0)

local function createY(y)
	f = CreateFrame("Frame", nil, Helper)
	f:SetSize(18, y)
	f:SetFrameStrata("TOOLTIP")
	
	local bg = createhelpBackdrop(f)
	bg:SetBackdropColor(Ccolor.r/2, Ccolor.g/2, Ccolor.b/2)
	bg:SetBackdropBorderColor(0.3, 0.3, 0.3) 
	f.bg = bg
	
	return f
end

ybottom = createY(cfg.playery)
ybottom:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)

ytop = createY(cfg.focusy)
ytop:SetPoint("BOTTOM", UIParent, "BOTTOM", cfg.playerx, cfg.playery)

local ybottomtext = Helper:CreateFontString(nil, "OVERLAY")
ybottomtext:SetPoint("LEFT", ybottom, "RIGHT", 10, 0)
ybottomtext:SetFont(cfg.font, 20, "OUTLINE")
ybottomtext:SetTextColor(0.5, 0.5, 0.5)
ybottomtext:SetText("cfg.playery")
ybottomtext:SetShadowOffset(0,0)

local ytoptext = Helper:CreateFontString(nil, "OVERLAY")
ytoptext:SetPoint("LEFT", ytop, "RIGHT", 10, 0)
ytoptext:SetFont(cfg.font, 20, "OUTLINE")
ytoptext:SetTextColor(0.5, 0.5, 0.5)
ytoptext:SetText("cfg.focusy")
ytoptext:SetShadowOffset(0,0)

local function highlight(frame, text)
frame:SetScript('OnEnter', function() 
	text:SetTextColor(1, 1, 1) 
	text:SetShadowOffset(5,-5)
	frame.bg:SetBackdropColor(Ccolor.r, Ccolor.g, Ccolor.b)
	frame.bg:SetBackdropBorderColor(1, 1, 0.8) 
end)
frame:SetScript('OnLeave', function()
	text:SetVertexColor(.5, 0.5, 0.5) 
	text:SetShadowOffset(0, 0) 
	frame.bg:SetBackdropColor(Ccolor.r/2, Ccolor.g/2, Ccolor.b/2)
	frame.bg:SetBackdropBorderColor(0.3, 0.3, 0.3) 
end)
end

highlight(xleft, xtext)
highlight(xright, xtext)
highlight(ybottom, ybottomtext)
highlight(ytop, ytoptext)

Helper:Hide()

local function toggleHelper()
if Helper:IsShown() then
	Helper:Hide()
else
	Helper:Show()
end
end

SlashCmdList["MlightHelper"] = toggleHelper;
SLASH_MlightHelper1 = "/mhelp"