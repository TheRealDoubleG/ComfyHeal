ComfyHeal=ComfyHeal or {}
local A=ComfyHeal
local controls={}
local function Label(p,t,x,y,font,w) local l=p:CreateFontString(nil,"ARTWORK",font or "GameFontNormal"); l:SetPoint("TOPLEFT",x,y); if w then l:SetWidth(w); l:SetJustifyH("LEFT") end; l:SetText(t); return l end
local function Button(p,t,x,y,w,fn) local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); b:SetSize(w or 130,24); b:SetPoint("TOPLEFT",x,y); b:SetText(t); b:SetScript("OnClick",fn); return b end
local function Check(p,t,x,y,get,set)
 local c=CreateFrame("CheckButton",nil,p,"UICheckButtonTemplate"); c:SetPoint("TOPLEFT",x,y); local l=c.Text or c.text or c:CreateFontString(nil,"ARTWORK","GameFontNormal"); if not c.Text and not c.text then l:SetPoint("LEFT",c,"RIGHT",3,1); c.Text=l end; l:SetText(t); c._get=get
 c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); A:RefreshFeature(); A:RefreshOptions() end); controls[#controls+1]=c; return c
end
local function Edit(p,t,x,y,w,get,set)
 Label(p,t,x,y); local e=CreateFrame("EditBox",nil,p,"InputBoxTemplate"); e:SetPoint("TOPLEFT",x,y-20); e:SetSize(w or 200,26); e:SetAutoFocus(false); e._get=get
 e:SetScript("OnEnterPressed",function(self) set(self:GetText() or ""); self:ClearFocus(); A:RequestBindingApply() end)
 e:SetScript("OnEditFocusLost",function(self) set(self:GetText() or ""); A:RequestBindingApply() end); controls[#controls+1]=e; return e
end
local function Dropdown(p,x,y,w,items,get,set)
 local d=CreateFrame("Frame",nil,p,"UIDropDownMenuTemplate"); d:SetPoint("TOPLEFT",x,y); UIDropDownMenu_SetWidth(d,w or 220)
 UIDropDownMenu_Initialize(d,function(_,level) local cur=get(); for _,it in ipairs(items()) do local info=UIDropDownMenu_CreateInfo(); info.text=it.text; info.value=it.value; info.checked=it.value==cur; info.func=function() set(it.value); CloseDropDownMenus(); A:RefreshOptions() end; UIDropDownMenu_AddButton(info,level) end end)
 d._refreshDropdown=function() local cur=get(); local txt=tostring(cur or ""); for _,it in ipairs(items()) do if it.value==cur then txt=it.text break end end; UIDropDownMenu_SetText(d,txt) end; controls[#controls+1]=d; return d
end
local current=1
local function Tab(i) current=i; for n,p in ipairs(A.pages or {}) do p:SetShown(n==i) end; for n,b in ipairs(A.tabs or {}) do b:SetEnabled(n~=i); b:SetButtonState(n==i and "PUSHED" or "NORMAL",n==i) end end

function A:RefreshOptions()
 if not self.optionsFrame or not self.db then return end
 for _,c in ipairs(controls) do
   if c._refreshDropdown then c._refreshDropdown()
   elseif c._get then local v=c._get(); local t=c:GetObjectType(); if t=="CheckButton" then c:SetChecked(v and true or false) elseif t=="EditBox" and not c:HasFocus() then c:SetText(tostring(v or "")) end end
 end
end

function A:ShowOptions() if not self.optionsFrame then self:InitializeOptions() end self.optionsFrame:Show(); self.optionsFrame:Raise(); self:RefreshOptions() end

function A:RegisterBlizzardSettingsCategory()
    if self.settingsCategory then return end
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end

    local canvas=CreateFrame("Frame")
    local isDE=type(GetLocale)=="function" and GetLocale()=="deDE"

    local title=canvas:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",16,-16)
    title:SetText("ComfyHeal")

    local desc=canvas:CreateFontString(nil,"ARTWORK","GameFontHighlight")
    desc:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-12)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText(isDE and "Öffnet das vollständige ComfyHeal-Einstellungsfenster der Comfy Suite." or "Opens the full ComfyHeal settings window for the Comfy Suite.")

    Button(canvas,isDE and "Einstellungen öffnen" or "Open settings",16,-90,220,function()
        A:ShowOptions()
    end)

    local category=Settings.RegisterCanvasLayoutCategory(canvas,"ComfyHeal")
    Settings.RegisterAddOnCategory(category)
    self.settingsCategory=category
end

function A:InitializeOptions()
 if self.optionsFrame then return end
 local f=CreateFrame("Frame","ComfyHealOptions",UIParent,"BasicFrameTemplateWithInset"); f:SetSize(920,670); f:SetPoint("CENTER",0,20); f:SetFrameStrata("HIGH"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f.TitleText:SetText("ComfyHeal")
 f:SetScript("OnDragStart",function(self) if not A.db.ui.windowLocked then self:StartMoving() end end); f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end); table.insert(UISpecialFrames,f:GetName())
 A.optionsFrame=f; A.tabs={}; A.pages={}
 local names={A:T("GENERAL"),A:T("BINDINGS"),A:T("DISPEL"),A:T("PROFILES"),A:T("INFO")}
 for i,n in ipairs(names) do A.tabs[i]=Button(f,n,18+(i-1)*165,-35,155,function() Tab(i) end); local p=CreateFrame("Frame",nil,f); p:SetPoint("TOPLEFT",12,-70); p:SetPoint("BOTTOMRIGHT",-12,12); A.pages[i]=p end

 local p=A.pages[1]
 Check(p,A:T("ENABLE"),20,-20,function() return A.db.enabled end,function(v) A.db.enabled=v end)
 Check(p,A:T("CLICKCAST"),20,-55,function() return A.db.clickCasting end,function(v) A.db.clickCasting=v end)
 Check(p,A:T("APPLY_PLAYER"),20,-105,function() return A.db.scopes.player end,function(v) A.db.scopes.player=v end)
 Check(p,A:T("APPLY_SINGLE"),20,-140,function() return A.db.scopes.single end,function(v) A.db.scopes.single=v end)
 Check(p,A:T("APPLY_PARTY"),20,-175,function() return A.db.scopes.party end,function(v) A.db.scopes.party=v end)
 Check(p,A:T("APPLY_RAID"),20,-210,function() return A.db.scopes.raid end,function(v) A.db.scopes.raid=v end)
 Label(p,A:T("NO_COMFYFRAMES"),20,-275,"GameFontHighlight",720)

 p=A.pages[2]
 Label(p,A:T("BIND_HINT"),20,-20,"GameFontHighlight",760)
 local defs={{"left","LEFT"},{"right","RIGHT"},{"middle","MIDDLE"},{"button4","BUTTON4"},{"button5","BUTTON5"},{"shiftLeft","SHIFT_LEFT"},{"shiftRight","SHIFT_RIGHT"},{"ctrlLeft","CTRL_LEFT"},{"ctrlRight","CTRL_RIGHT"},{"altLeft","ALT_LEFT"},{"altRight","ALT_RIGHT"}}
 for i,d in ipairs(defs) do
   local bindingKey=d[1]
   local labelKey=d[2]
   local col=(i-1)%3; local row=math.floor((i-1)/3); local x=20+col*280; local y=-75-row*85
   Edit(p,A:T(labelKey),x,y,230,function() return A.db.bindings[bindingKey] end,function(v) A.db.bindings[bindingKey]=v end)
 end

 p=A.pages[3]
 Label(p,A:T("DISPEL_HINT"),20,-20,"GameFontHighlight",780)
 Check(p,A:T("HIGHLIGHT_FRAMES"),20,-75,function() return A.db.dispel.highlightFrames end,function(v) A.db.dispel.highlightFrames=v end)
 Check(p,A:T("DISPEL_CENTER"),20,-110,function() return A.db.dispel.center end,function(v) A.db.dispel.center=v end)
 Check(p,A:T("MAGIC"),20,-165,function() return A.db.dispel.types.Magic end,function(v) A.db.dispel.types.Magic=v end)
 Check(p,A:T("CURSE"),190,-165,function() return A.db.dispel.types.Curse end,function(v) A.db.dispel.types.Curse=v end)
 Check(p,A:T("DISEASE"),360,-165,function() return A.db.dispel.types.Disease end,function(v) A.db.dispel.types.Disease=v end)
 Check(p,A:T("POISON"),530,-165,function() return A.db.dispel.types.Poison end,function(v) A.db.dispel.types.Poison=v end)
 Check(p,A:T("TEST"),20,-220,function() return A.db.dispel.test end,function(v) A.db.dispel.test=v end)
 Button(p,A:T("CENTER_UNLOCK"),20,-275,190,function() A:SetDispelCenterLocked(false) end); Button(p,A:T("CENTER_LOCK"),220,-275,190,function() A:SetDispelCenterLocked(true) end)

 p=A.pages[4]
 Label(p,A:T("PROFILES_HINT"),20,-20,"GameFontHighlight",760)
 Dropdown(p,5,-75,270,function() return A:GetProfileEntries() end,function() return A:GetActiveProfileKey() end,function(v) A:SetActiveProfile(v); A:RefreshFeature() end)
 local e=Edit(p,A:T("CUSTOM_PROFILE"),20,-135,220,function() return "" end,function() end)
 Button(p,A:T("CREATE"),250,-157,120,function() if A:CreateCustomProfile(e:GetText()) then e:SetText(""); A:RefreshFeature() end end)
 Button(p,A:T("DELETE"),380,-157,140,function() A:DeleteActiveCustomProfile(); A:RefreshFeature() end)
 Button(p,A:T("RESET_PROFILE"),530,-157,160,function() A:ResetActiveProfile(); A:RefreshFeature() end)

 p=A.pages[5]
 Label(p,"ComfyHeal "..A.version.." "..A.status,20,-20,"GameFontNormalLarge")
 local info=Label(p,"",20,-65,"GameFontHighlight",800); local cv,cb,_,ci=A:GetClientBuildInfo()
 info:SetText("Build-Datum: "..A.buildDate.."\nAutor: "..A.author.."\nDiscord: "..A.discord.."\nGitHub: "..A.github.."\n\nClient: "..cv.." / Build "..cb.." / Interface "..tostring(ci or "?").."\nTarget: "..A.gameVersion.." / Interface "..A.interface.."\n\n"..A:T("INFO_COMMANDS").."\n\n"..A:T("INFO_NOTICE"))
 Tab(1); A:RefreshOptions()
end
