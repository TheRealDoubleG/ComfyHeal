ComfyHeal=ComfyHeal or {}
local A=ComfyHeal

local COLORS={
 Magic={0.25,0.60,1.00,1}, Curse={0.70,0.30,0.95,1},
 Disease={0.75,0.55,0.20,1}, Poison={0.20,0.85,0.25,1},
}

local function AuraByIndex(unit,index)
 if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex)=="function" then
   local ok,a=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,"HARMFUL")
   if ok and a then
     return {
       name=a.name, icon=a.icon, dispelName=a.dispelName or a.debuffType,
       spellId=a.spellId, applications=a.applications,
     }
   end
 end
 if type(UnitDebuff)=="function" then
   local ok,name,icon,count,debuffType,_,_,_,_,spellId=pcall(UnitDebuff,unit,index)
   if ok and name then return {name=name,icon=icon,dispelName=debuffType,spellId=spellId,applications=count} end
 end
 return nil
end

function A:GetSelectedDebuff(unit)
 if not self.db or not self.db.dispel then return nil end
 for i=1,40 do
   local a=AuraByIndex(unit,i)
   if not a then break end
   local t=a.dispelName
   if t and self.db.dispel.types[t] then return a end
 end
 return nil
end

function A:UpdateDispelForFrame(frame)
 if not frame or not self.db then return end
 local aura=self.db.dispel.test and {name="Test Debuff",dispelName="Magic",icon="Interface\\Icons\\Spell_Holy_DispelMagic"} or self:GetSelectedDebuff(frame.unit)
 local cf=_G.ComfyFrames
 if self.db.dispel.highlightFrames and aura and COLORS[aura.dispelName] then
   if cf and type(cf.SetExternalHighlight)=="function" then cf:SetExternalHighlight(frame,"ComfyHealDispel",COLORS[aura.dispelName])
   elseif frame.SetBackdropBorderColor then local c=COLORS[aura.dispelName]; frame:SetBackdropBorderColor(c[1],c[2],c[3],c[4]) end
 else
   if cf and type(cf.SetExternalHighlight)=="function" then cf:SetExternalHighlight(frame,"ComfyHealDispel",nil) end
 end
end

function A:GetGroupUnits()
 local out={}
 if self.db.dispel.test then
   for i=1,math.min(self.db.dispel.maxEntries or 8,8) do out[#out+1]="party"..math.min(i,4) end
   return out
 end
 local inRaid=type(IsInRaid)=="function" and IsInRaid()
 if inRaid then
   local n=type(GetNumGroupMembers)=="function" and GetNumGroupMembers() or 0
   for i=1,math.min(40,n) do out[#out+1]="raid"..i end
 else
   out[#out+1]="player"
   local n=type(GetNumSubgroupMembers)=="function" and GetNumSubgroupMembers() or 0
   for i=1,math.min(4,n) do out[#out+1]="party"..i end
 end
 return out
end

function A:RefreshDispelCenter()
 local center=self.dispelCenter
 if not center or not self.db then return end
 center:SetShown(self.db.enabled and self.db.dispel.center)
 if not center:IsShown() then return end
 local matches={}
 if self.db.dispel.test then
   local types={"Magic","Curse","Disease","Poison"}
   for i=1,math.min(#center.rows,self.db.dispel.maxEntries or 8) do
     matches[#matches+1]={unit="party"..math.min(i,4),aura={name="Test "..types[((i-1)%4)+1],dispelName=types[((i-1)%4)+1],icon="Interface\\Icons\\Spell_Holy_DispelMagic"},name="Test "..i}
   end
 else
   for _,unit in ipairs(self:GetGroupUnits()) do
     local aura=self:GetSelectedDebuff(unit)
     if aura then
       local ok,name=pcall(UnitName,unit)
       matches[#matches+1]={unit=unit,aura=aura,name=ok and name or unit}
       if #matches>=(self.db.dispel.maxEntries or 8) then break end
     end
   end
 end

 for i,row in ipairs(center.rows) do
   local item=matches[i]
   if item then
     row:Show(); row.icon:SetTexture(item.aura.icon)
     row.name:SetText(item.name or item.unit); row.debuff:SetText(tostring(item.aura.name or item.aura.dispelName or ""))
     local c=COLORS[item.aura.dispelName] or {1,1,1,1}; row.type:SetText(item.aura.dispelName or ""); row.type:SetTextColor(c[1],c[2],c[3])
   else row:Hide() end
 end
end

function A:RefreshDispel()
 for frame in pairs(self.registeredFrames or {}) do self:UpdateDispelForFrame(frame) end
 self:RefreshDispelCenter()
end

function A:SetDispelCenterLocked(locked)
 self.db.dispel.locked=locked and true or false
 if self.dispelCenter then self.dispelCenter:EnableMouse(not self.db.dispel.locked) end
end

function A:CreateDispelCenter()
 local f=CreateFrame("Frame","ComfyHealDispelCenter",UIParent,"BackdropTemplate")
 f:SetSize(330,230); f:SetPoint("CENTER",UIParent,"CENTER",self.db.dispel.x,self.db.dispel.y)
 f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10})
 f:SetBackdropColor(0.03,0.03,0.03,0.88); f:SetBackdropBorderColor(1,0.82,0,0.75)
 f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal"); f.title:SetPoint("TOPLEFT",10,-8); f.title:SetText("ComfyHeal – Dispel Center")
 f:SetScript("OnDragStart",function(self) if not A.db.dispel.locked and not InCombatLockdown() then self:StartMoving() end end)
 f:SetScript("OnDragStop",function(self)
   self:StopMovingOrSizing(); local x,y=self:GetCenter(); local ux,uy=UIParent:GetCenter()
   if x and y and ux and uy then A.db.dispel.x=math.floor(x-ux+0.5); A.db.dispel.y=math.floor(y-uy+0.5) end
 end)
 f.rows={}
 for i=1,8 do
   local row=CreateFrame("Frame",nil,f); row:SetSize(310,22); row:SetPoint("TOPLEFT",10,-30-(i-1)*24)
   row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetPoint("LEFT"); row.icon:SetSize(20,20)
   row.name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); row.name:SetPoint("LEFT",row.icon,"RIGHT",6,0); row.name:SetWidth(90); row.name:SetJustifyH("LEFT")
   row.debuff=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.debuff:SetPoint("LEFT",row.name,"RIGHT",4,0); row.debuff:SetWidth(125); row.debuff:SetJustifyH("LEFT")
   row.type=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.type:SetPoint("RIGHT",-2,0); row.type:SetWidth(60); row.type:SetJustifyH("RIGHT")
   f.rows[i]=row
 end
 self.dispelCenter=f
 self:SetDispelCenterLocked(self.db.dispel.locked)
 self:RefreshDispelCenter()
end

function A:RegisterDispelCenterWithComfyHub()
 local hub=_G.ComfyHub
 if not hub or type(hub.RegisterLayoutTarget)~="function" or not self.dispelCenter then return end
 hub:RegisterLayoutTarget("ComfyHeal","dispelCenter",self.dispelCenter,{
   setEditMode=function(on) A:SetDispelCenterLocked(not on) end,
 })
end

function A:InitializeDispel()
 self:CreateDispelCenter()
 self:RegisterDispelCenterWithComfyHub()
 local f=CreateFrame("Frame")
 f:RegisterEvent("UNIT_AURA"); f:RegisterEvent("GROUP_ROSTER_UPDATE"); f:RegisterEvent("PLAYER_ENTERING_WORLD"); f:RegisterEvent("PLAYER_TARGET_CHANGED"); f:RegisterEvent("PLAYER_FOCUS_CHANGED")
 f:SetScript("OnEvent",function(_,event,unit)
   if event=="UNIT_AURA" and unit then
     for frame in pairs(A.registeredFrames or {}) do if frame.unit==unit then A:UpdateDispelForFrame(frame) end end
   else
     A:RefreshDispel()
   end
   A:RefreshDispelCenter()
 end)
 self.dispelEventFrame=f
end
