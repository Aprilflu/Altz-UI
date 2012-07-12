local ADDON_NAME, ns = ...
local cfg = ns.cfg

if not cfg.raidcd then return end

--Allez

local spells = {
	--[20484] = 600,	-- ����
	--[61999] = 600,	-- ��������
	--[20707] = 900,	-- ���ʯ����
	--[6346] = 180,	-- �����־���
	--[29166] = 180,	-- ����
	--[32182] = 300,	-- Ӣ��
	--[2825] = 300,	-- ��Ѫ
	--[80353] = 300,	-- ʱ��Ť��
	--[90355] = 300,	-- Զ�ſ���

	--�Ŷ����˼���	
	[97462] = 180,  -- �����ź�
	[98008] = 180,  -- �������ͼ��
	[62618] = 180,  -- ������: ��
	[51052] = 120,  -- ��ħ������
	[31821] = 120,  -- �⻷����
	[64843] = 180,  -- ��ʥ����ʫ *
	[740]   = 180,  -- ���� *
	[87023] = 60,   --����
	[16190] = 180,  --��ϫ
	[105763] =120,  --���� 2T13
	[105914] =120,  --սʿ 4T13
	[105739] =180,  --С�� 4T13
	[115213] = 60,	-- �ȱ��ӻ�
	
	--[33076] = 10, --���ϵ���
	--[34861] = 10, --����֮��
}

--variables
local dragFrameList = {}
local color         = "DC143C"
local shortcut      = "atweaks"

--make variables available in the namespace
ns.dragFrameList    = dragFrameList
ns.addonColor       = color
ns.addonShortcut    = shortcut

local pos = {"TOPLEFT", Minimap, "TOPRIGHT", -10, 0}
local locked = true
local width, height = 140, 14
local spacing = 6
local iconsize = 14
local fontsize = 11
local flag = "OUTLINE"
local texture = "Interface\\AddOns\\aCore\\media\\statusbar"

local show = {
	raid = true,
	party = true,
	arena = true,
}

local filter = COMBATLOG_OBJECT_AFFILIATION_RAID + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_MINE
local band = bit.band
local sformat = string.format
local floor = math.floor
local timer = 0

local bars = {}

local anchorframe = CreateFrame("Frame", "RaidCD", UIParent)
anchorframe:SetSize(20, 30)
anchorframe:SetPoint(unpack(pos))
rCreateDragFrame(anchorframe, dragFrameList, -2 , true) --frame, dragFrameList, inset, clamp

local UpdatePositions = function()
	for i = 1, #bars do
		bars[i]:ClearAllPoints()
		if i == 1 then
			bars[i]:SetPoint("TOPLEFT", anchorframe, "TOPRIGHT", 5, 0)
		else
			bars[i]:SetPoint("TOPLEFT", bars[i-1], "BOTTOMLEFT", 0, -spacing)
		end
		bars[i].id = i
	end
end

local StopTimer = function(bar)
	bar:SetScript("OnUpdate", nil)
	bar:Hide()
	tremove(bars, bar.id)
	UpdatePositions()
end

local BarUpdate = function(self, elapsed)
	local curTime = GetTime()
	if self.endTime < curTime then
		StopTimer(self)
		return
	end
	self.status:SetValue(100 - (curTime - self.startTime) / (self.endTime - self.startTime) * 100)
	self.right:SetText(FormatTime(self.endTime - curTime))
end

local OnEnter = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.spell)
	GameTooltip:SetClampedToScreen(true)
	GameTooltip:Show()
end

local OnLeave = function(self)
	GameTooltip:Hide()
end

local OnMouseDown = function(self, button)
	if button == "LeftButton" then
		SendChatMessage(sformat("Cooldown %s %s: %s", self.left:GetText(), self.spell, self.right:GetText()), "RAID")
	elseif button == "RightButton" then
		StopTimer(self)
	end
end

local CreateBar = function()
	local bar = CreateFrame("Frame", nil, UIParent)
	bar:SetSize(width, height)
	
	bar.icon = CreateFrame("button", nil, bar)
	bar.icon:SetSize(iconsize, iconsize)
	bar.icon:SetPoint("BOTTOMLEFT", 0, 0)
	
	bar.status = CreateFrame("Statusbar", nil, bar)
	bar.status:SetPoint("BOTTOMLEFT", bar.icon, "BOTTOMRIGHT", 5, 0)
	bar.status:SetPoint("BOTTOMRIGHT", 0, 0)
	bar.status:SetHeight(height)
	bar.status:SetStatusBarTexture(texture)
	bar.status:SetMinMaxValues(0, 100)
	bar.status:SetFrameLevel(bar:GetFrameLevel()-1)	
	
	bar.left = createtext(bar, fontsize, flag, false)
	bar.left:SetPoint('LEFT', bar.status, 2, 1)
	bar.left:SetJustifyH('LEFT')
	
	bar.right = createtext(bar, fontsize, flag, false)
	bar.right:SetPoint('RIGHT', bar.status, -2, 1)
	bar.right:SetJustifyH('RIGHT')
	
	createnameplateBD(bar.icon, 0, 0, 0, 0.4, 1)
	createnameplateBD(bar.status, 0, 0, 0, 0.4, 1)
	return bar
end

local StartTimer = function(name, spellId)
	local spell, rank, icon = GetSpellInfo(spellId)
	for _, v in pairs(bars) do
		if v.name == name and v.spell == spell then
			return
		end
	end
	
	local bar = CreateBar()
	bar.endTime = GetTime() + spells[spellId]
	bar.startTime = GetTime()
	bar.left:SetText(name)
	bar.name = name
	bar.right:SetText(FormatTime(spells[spellId]))
	bar.spell = spell

	if icon and bar.icon then
		bar.icon:SetNormalTexture(icon)
		bar.icon:GetNormalTexture():SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
	
	bar:Show()
	
	local color = RAID_CLASS_COLORS[select(2, UnitClass(name))]
	bar.status:SetStatusBarColor(color.r, color.g, color.b)
	
	bar:EnableMouse(true)

	bar:SetScript("OnEnter", OnEnter)
	bar:SetScript("OnLeave", OnLeave)
	bar:SetScript("OnMouseDown", OnMouseDown)
	bar:SetScript("OnUpdate", BarUpdate)

	tinsert(bars, bar)
	UpdatePositions()
end

local OnEvent = function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local timestamp, eventType, _, sourceGUID, sourceName, sourceFlags = ...
		if band(sourceFlags, filter) == 0 then return end
		if eventType == "SPELL_RESURRECT" or eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_AURA_APPLIED" then
			local spellId = select(12, ...)
			if spells[spellId] and show[select(2, IsInInstance())] then
				StartTimer(sourceName, spellId)
			end
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" and select(2, IsInInstance()) == "arena" then
		for k, v in pairs(bars) do
			StopTimer(v)
		end
	end
end

local eventf = CreateFrame("frame")
eventf:SetScript('OnEvent', OnEvent)
eventf:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventf:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-----------------------------
-- FUNCTIONS
-----------------------------
SlashCmdList[shortcut] = rCreateSlashCmdFunction(ADDON_NAME, shortcut, dragFrameList, color)
SLASH_atweaks1 = "/"..shortcut;

local function test()
	  StartTimer(UnitName('player'), 97462)
	  StartTimer(UnitName('player'), 98008)
	  StartTimer(UnitName('player'), 51052)
end

SlashCmdList["raidcd"] = test;
SLASH_raidcd1 = "/raidcd"