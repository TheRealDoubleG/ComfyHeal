ComfyHeal = ComfyHeal or {}
local A = ComfyHeal

A.version = "0.4"
A.buildDate = "04.10.2026"

local function EnsureDefaults()
    if not A.db then return end
    A.db.dispel = A.db.dispel or {}
    local d=A.db.dispel
    local defaults={
        visibility="always",
        onlyCombat=false,
        onlyActive=false,
        showBorder=true,
        backgroundAlpha=88,
        windowOpacity=100,
        iconSize=20,
        rowSpacing=24,
        manualHidden=false,
    }
    for k,v in pairs(defaults) do if d[k]==nil then d[k]=v end end
end

local originalInitializeDB=A.InitializeDB
function A:InitializeDB(...)
    local r
    if originalInitializeDB then r=originalInitializeDB(self,...) end
    EnsureDefaults(); return r
end

local function IsInGroupSafe()
    if type(IsInGroup)=="function" then local ok,v=pcall(IsInGroup); if ok then return v and true or false end end
    local n=type(GetNumSubgroupMembers)=="function" and tonumber(GetNumSubgroupMembers()) or 0
    return n>0
end
local function IsInRaidSafe()
    if type(IsInRaid)=="function" then local ok,v=pcall(IsInRaid); if ok then return v and true or false end end
    return false
end
local function IsInInstanceSafe()
    if type(IsInInstance)=="function" then local ok,v=pcall(IsInInstance); if ok then return v and true or false end end
    return false
end

function A:ShouldShowDispelCenter()
    if not self.db or not self.db.enabled or not self.db.dispel.center then return false end
    EnsureDefaults(); local d=self.db.dispel
    if d.manualHidden and not d.test then return false end
    if d.test then return true end
    if d.visibility=="never" then return false end
    if d.visibility=="instance" and not IsInInstanceSafe() then return false end
    if d.visibility=="group" and not IsInGroupSafe() then return false end
    if d.visibility=="raid" and not IsInRaidSafe() then return false end
    if d.visibility=="fullgroup" then
        if IsInRaidSafe() then return false end
        local members=1+(type(GetNumSubgroupMembers)=="function" and (tonumber(GetNumSubgroupMembers()) or 0) or 0)
        if members<5 then return false end
    end
    if d.onlyCombat then
        local inCombat=(type(InCombatLockdown)=="function" and InCombatLockdown()) or (type(UnitAffectingCombat)=="function" and UnitAffectingCombat("player"))
        if not inCombat then return false end
    end
    if d.onlyActive then
        local any=false
        for _,unit in ipairs(self:GetGroupUnits()) do if self:GetSelectedDebuff(unit) then any=true break end end
        if not any then return false end
    end
    return true
end

function A:ApplyDispelAppearance()
    local f=self.dispelCenter
    if not f or not self.db then return end
    EnsureDefaults(); local d=self.db.dispel
    f:SetAlpha(math.max(0,math.min(100,tonumber(d.windowOpacity) or 100))/100)
    local bg=math.max(0,math.min(100,tonumber(d.backgroundAlpha) or 88))/100
    f:SetBackdropColor(.03,.03,.03,bg)
    if d.showBorder then f:SetBackdropBorderColor(1,.82,0,.75) else f:SetBackdropBorderColor(0,0,0,0) end
    local iconSize=math.max(14,math.min(36,tonumber(d.iconSize) or 20))
    local spacing=math.max(20,math.min(40,tonumber(d.rowSpacing) or 24))
    for i,row in ipairs(f.rows or {}) do
        if row.icon then row.icon:SetSize(iconSize,iconSize) end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",10,-30-(i-1)*spacing)
    end
    local height=50+math.max(1,math.min(#(f.rows or {}),tonumber(d.maxEntries) or 8))*spacing
    f:SetHeight(math.max(120,height))
end

function A:ResetDispelCenterPosition()
    if not self.db then return end
    self.db.dispel.x=0; self.db.dispel.y=285
    if self.dispelCenter then self.dispelCenter:ClearAllPoints(); self.dispelCenter:SetPoint("CENTER",UIParent,"CENTER",0,285) end
end

function A:ShowDispelCenterManual()
    EnsureDefaults(); self.db.dispel.manualHidden=false; self.db.dispel.center=true; self:RefreshDispelCenter()
end

local originalCreateDispelCenter=A.CreateDispelCenter
function A:CreateDispelCenter(...)
    if originalCreateDispelCenter then originalCreateDispelCenter(self,...) end
    EnsureDefaults(); local f=self.dispelCenter; if not f or f.__enhanced then return end; f.__enhanced=true
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",2,2); close:SetSize(24,24)
    close:SetScript("OnClick",function() A.db.dispel.manualHidden=true; f:Hide() end)
    f.closeButton=close
    self:ApplyDispelAppearance()
end

local originalRefreshDispelCenter=A.RefreshDispelCenter
function A:RefreshDispelCenter(...)
    local center=self.dispelCenter
    if not center or not self.db then return end
    EnsureDefaults()
    center:SetShown(self:ShouldShowDispelCenter())
    if not center:IsShown() then return end
    if originalRefreshDispelCenter then originalRefreshDispelCenter(self,...) end
    self:ApplyDispelAppearance()
end

local function SelectTab(index)
    if not A.pages or not A.tabs then return end
    for i,page in ipairs(A.pages) do page:SetShown(i==index) end
    for i,tab in ipairs(A.tabs) do
        tab:SetEnabled(true)
        tab:SetButtonState(i==index and "PUSHED" or "NORMAL",false)
        local fs=tab:GetFontString(); if fs then fs:SetTextColor(1,.82,0) end
    end
    A.__selectedTab=index
end

local function RepairTabScripts()
    if not A.tabs then return end
    for i,tab in ipairs(A.tabs) do
        local index=i
        tab:SetScript("OnClick",function() SelectTab(index) end)
    end
    SelectTab(A.__selectedTab or 1)
end

local function Check(parent,text,x,y,get,set)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); c:SetPoint("TOPLEFT",x,y); local t=c.Text or c.text; if t then t:SetText(text) end
    c:SetChecked(get() and true or false); c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); A:RefreshDispelCenter() end); return c
end
local function Slider(parent,name,label,minv,maxv,step,x,y,get,set)
    local s=CreateFrame("Slider",name,parent,"OptionsSliderTemplate"); s:SetPoint("TOPLEFT",x,y); s:SetWidth(220); s:SetMinMaxValues(minv,maxv); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    _G[name.."Low"]:SetText(tostring(minv)); _G[name.."High"]:SetText(tostring(maxv)); _G[name.."Text"]:SetText(label); s:SetValue(tonumber(get()) or minv)
    s:SetScript("OnValueChanged",function(_,v) set(math.floor((tonumber(v) or minv)+.5)); A:ApplyDispelAppearance() end); return s
end
local function Dropdown(parent,x,y,w,items,get,set)
    local d=CreateFrame("Frame",nil,parent,"UIDropDownMenuTemplate"); d:SetPoint("TOPLEFT",x,y); UIDropDownMenu_SetWidth(d,w)
    UIDropDownMenu_Initialize(d,function(_,level)
        local cur=get(); for _,it in ipairs(items) do local info=UIDropDownMenu_CreateInfo(); info.text=it.text; info.value=it.value; info.checked=cur==it.value; info.func=function() set(it.value); UIDropDownMenu_SetText(d,it.text); CloseDropDownMenus(); A:RefreshDispelCenter() end; UIDropDownMenu_AddButton(info,level) end
    end)
    local cur=get(); for _,it in ipairs(items) do if it.value==cur then UIDropDownMenu_SetText(d,it.text) end end; return d
end

local originalInitializeOptions=A.InitializeOptions
function A:InitializeOptions(...)
    if originalInitializeOptions then originalInitializeOptions(self,...) end
    RepairTabScripts()
    if self.__enhancementOptionsBuilt or not self.pages then return end
    self.__enhancementOptionsBuilt=true; EnsureDefaults()
    local p=self.pages[3]; if not p then return end; local d=self.db.dispel
    local title=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",470,-210); title:SetText("Dispel-Center Fenster")
    Check(p,"Rahmen anzeigen",470,-245,function() return d.showBorder end,function(v) d.showBorder=v end)
    Check(p,"Nur im Kampf",650,-245,function() return d.onlyCombat end,function(v) d.onlyCombat=v end)
    Check(p,"Nur wenn etwas zu dispellen ist",470,-278,function() return d.onlyActive end,function(v) d.onlyActive=v end)
    local modes={{text="Immer",value="always"},{text="Nie",value="never"},{text="Nur Instanz",value="instance"},{text="Nur Gruppe",value="group"},{text="Nur volle 5er-Gruppe",value="fullgroup"},{text="Nur Raid",value="raid"}}
    Dropdown(p,455,-315,220,modes,function() return d.visibility end,function(v) d.visibility=v end)
    local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); b:SetSize(170,24); b:SetPoint("TOPLEFT",470,-365); b:SetText("Dispel-Center zeigen"); b:SetScript("OnClick",function() A:ShowDispelCenterManual() end)
    local r=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); r:SetSize(170,24); r:SetPoint("TOPLEFT",650,-365); r:SetText("Position zurücksetzen"); r:SetScript("OnClick",function() A:ResetDispelCenterPosition() end)
    Slider(p,"ComfyHealDispelBg","Hintergrund %",0,100,5,475,-430,function() return d.backgroundAlpha end,function(v) d.backgroundAlpha=v end)
    Slider(p,"ComfyHealDispelAlpha","Fenster %",0,100,5,475,-500,function() return d.windowOpacity end,function(v) d.windowOpacity=v end)
    Slider(p,"ComfyHealDispelIcon","Icon-Größe",14,36,1,475,-570,function() return d.iconSize end,function(v) d.iconSize=v end)
end

local originalInitializeDispel=A.InitializeDispel
function A:InitializeDispel(...)
    if originalInitializeDispel then originalInitializeDispel(self,...) end
    local f=self.dispelEventFrame
    if f then
        for _,ev in ipairs({"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","ZONE_CHANGED_NEW_AREA"}) do pcall(f.RegisterEvent,f,ev) end
    end
    self:ApplyDispelAppearance(); self:RefreshDispelCenter()
end
