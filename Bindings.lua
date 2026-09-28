ComfyHeal=ComfyHeal or {}
local A=ComfyHeal

A.registeredFrames=A.registeredFrames or {}

local SPECS={
 {key="left",button=1,modifier=""}, {key="right",button=2,modifier=""}, {key="middle",button=3,modifier=""},
 {key="button4",button=4,modifier=""}, {key="button5",button=5,modifier=""},
 {key="shiftLeft",button=1,modifier="shift-"}, {key="shiftRight",button=2,modifier="shift-"},
 {key="ctrlLeft",button=1,modifier="ctrl-"}, {key="ctrlRight",button=2,modifier="ctrl-"},
 {key="altLeft",button=1,modifier="alt-"}, {key="altRight",button=2,modifier="alt-"},
}

local function Trim(v) return tostring(v or ""):match("^%s*(.-)%s*$") or "" end

function A:IsFrameInScope(frame)
 if not frame then return false end
 if frame.groupKind=="party" then return self.db.scopes.party end
 if frame.groupKind=="raid" then return self.db.scopes.raid end
 if frame.unit=="player" then return self.db.scopes.player end
 return self.db.scopes.single
end

function A:RegisterHealFrame(frame)
 if not frame then return end
 self.registeredFrames[frame]=true
 if not InCombatLockdown() then self:ApplyBindingsToFrame(frame) else self.pendingBindingApply=true end
 if self.UpdateDispelForFrame then self:UpdateDispelForFrame(frame) end
end

function A:RegisterComfyFrames()
 local cf=_G.ComfyFrames
 if not cf or type(cf.RegisterUnitButtonListener)~="function" then return false end
 if not self._listenerInstalled then
   self._listenerInstalled=true
   cf:RegisterUnitButtonListener(function(frame) A:RegisterHealFrame(frame) end)
 else
   for _,frame in pairs(cf.unitFrames or {}) do self:RegisterHealFrame(frame) end
   for _,frame in ipairs(cf.partyFrames or {}) do self:RegisterHealFrame(frame) end
   for _,frame in ipairs(cf.raidFrames or {}) do self:RegisterHealFrame(frame) end
 end
 return true
end

local function ClearSpec(frame,spec)
 pcall(frame.SetAttribute,frame,spec.modifier.."type"..spec.button,nil)
 pcall(frame.SetAttribute,frame,spec.modifier.."spell"..spec.button,nil)
end

function A:ApplyBindingsToFrame(frame)
 if not frame or InCombatLockdown() then self.pendingBindingApply=true; return false end
 if not self.db.enabled or not self.db.clickCasting or not self:IsFrameInScope(frame) then
   for _,spec in ipairs(SPECS) do ClearSpec(frame,spec) end
   if frame.unit then pcall(frame.SetAttribute,frame,"type1","target") end
   return true
 end

 for _,spec in ipairs(SPECS) do
   local spell=Trim(self.db.bindings[spec.key])
   if spell~="" then
     pcall(frame.SetAttribute,frame,spec.modifier.."type"..spec.button,"spell")
     pcall(frame.SetAttribute,frame,spec.modifier.."spell"..spec.button,spell)
   else
     ClearSpec(frame,spec)
   end
 end

 -- Preserve ordinary targeting when left click itself has no healing binding.
 if Trim(self.db.bindings.left)=="" then pcall(frame.SetAttribute,frame,"type1","target") end
 return true
end

function A:ApplyBindings()
 if InCombatLockdown() then self.pendingBindingApply=true; self:Print(self:T("PENDING")); return false end
 self.pendingBindingApply=nil
 for frame in pairs(self.registeredFrames) do self:ApplyBindingsToFrame(frame) end
 self:Print(self:T("APPLIED"))
 return true
end

function A:RequestBindingApply()
 if InCombatLockdown() then
   self.pendingBindingApply=true
   self:Print(self:T("PENDING"))
   return false
 end
 return self:ApplyBindings()
end

function A:InitializeBindings()
 self:RegisterComfyFrames()
end
