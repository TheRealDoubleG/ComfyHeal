local ADDON_NAME=...

ComfyHeal=ComfyHeal or {}
local A=ComfyHeal

A.name=ADDON_NAME or "ComfyHeal"
A.version="0.2"
A.buildDate="28.09.2026"
A.status="Beta"
A.gameVersion="WoW Forever 1.60.1"
A.interface=16001
A.targetBuild="70009"
A.author="TheRealDoubleG"
A.discord="the.real.double.g"
A.github="https://github.com/TheRealDoubleG/ComfyHeal"

local defaults={
 enabled=true,
 clickCasting=true,
 scopes={player=true,single=false,party=true,raid=true},
 bindings={
   left="", right="", middle="", button4="", button5="",
   shiftLeft="",shiftRight="",ctrlLeft="",ctrlRight="",altLeft="",altRight="",
 },
 dispel={
   highlightFrames=true, center=true, test=false,
   types={Magic=true,Curse=true,Disease=true,Poison=true},
   x=0,y=285,locked=true,maxEntries=8,
 },
 optionsWindow={point="CENTER",relativePoint="CENTER",x=0,y=20},
 ui={windowLocked=false,windowOpacity=100,showWindowBorder=true,backgroundAlpha=92},
}
A.defaults=defaults

local function Copy(src)
 if type(src)~="table" then return src end
 local out={}; for k,v in pairs(src) do out[k]=Copy(v) end; return out
end

function A:Print(msg)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyHeal:|r "..tostring(msg)) end
end

function A:GetClientBuildInfo()
 if not GetBuildInfo then return "?","?","?",nil end
 local a,b,c,d=GetBuildInfo(); return tostring(a or "?"),tostring(b or "?"),tostring(c or "?"),tonumber(d)
end

function A:InitializeDB()
 if self.InitializeProfileStorage then self:InitializeProfileStorage(defaults,"ComfyHealDB")
 else ComfyHealDB=type(ComfyHealDB)=="table" and ComfyHealDB or Copy(defaults); self.db=ComfyHealDB end
end

function A:RefreshFeature()
 if self.RegisterComfyFrames then self:RegisterComfyFrames() end
 if self.RequestBindingApply then self:RequestBindingApply() end
 if self.RefreshDispel then self:RefreshDispel() end
 if self.RefreshOptions then self:RefreshOptions() end
end

SLASH_COMFYHEAL1="/comfyheal"
SLASH_COMFYHEAL2="/cheal"
SlashCmdList.COMFYHEAL=function(msg)
 msg=tostring(msg or ""):lower():match("^%s*(.-)%s*$")
 if msg=="test" then
   A.db.dispel.test=not A.db.dispel.test
   if A.RefreshDispel then A:RefreshDispel() end
 else
   if A.ShowOptions then A:ShowOptions() end
 end
end

local f=CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent",function(_,ev,arg1)
 if ev=="ADDON_LOADED" and arg1==A.name then
   A:InitializeDB()
   if A.InitializeBindings then A:InitializeBindings() end
   if A.InitializeDispel then A:InitializeDispel() end
   if A.InitializeOptions then A:InitializeOptions() end
   A:Print(A:T("LOADED").." v"..A.version)
 elseif ev=="ADDON_LOADED" and arg1=="ComfyFrames" then
   if A.RegisterComfyFrames then A:RegisterComfyFrames() end
 elseif ev=="ADDON_LOADED" and arg1=="ComfyHub" then
   if A.RegisterDispelCenterWithComfyHub then A:RegisterDispelCenterWithComfyHub() end
 elseif ev=="PLAYER_LOGIN" then
   if A.RegisterComfyFrames then A:RegisterComfyFrames() end
   if A.RequestBindingApply then A:RequestBindingApply() end
 elseif ev=="PLAYER_REGEN_ENABLED" then
   if A.pendingBindingApply and A.ApplyBindings then A.pendingBindingApply=nil; A:ApplyBindings() end
 end
end)
