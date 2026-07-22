-------------------------------------------------------------------------------
-- MSBT Cumulative DoT Tracker - Darksolis Premium Edition v5.4.88
-- Persistent cumulative periodic damage rendered at an MSBT scroll area.
-------------------------------------------------------------------------------
local addonName = "MikScrollingBattleText"
local tracker = CreateFrame("Frame", "MSBTCumulativeDotsFrame", UIParent)

local defaults = {
 enabled=true, mode="death", displayMode="targets", allPeriodic=true,
 includePet=false, whitelist={}, scrollArea="Outgoing",
 inheritFont=true, fontName=nil, fontSize=26, outline="THICKOUTLINE",
 alignment="CENTER", spacing=6, maxTargets=8, maxSpellLabels=4,
 showTargetName=false, spellLabelMode="none", showSpellIcons=false,
 stackIconEnabled=false, stackIconSource="Interface\\Icons\\Ability_Rogue_Hemorrhage",
 stackIconPosition="left", stackIconSize=30, pulseOnTick=true,
 activeSpellsOnly=false, compactNumbers=true, showDamageLabel=false,
 colorR=255, colorG=190, colorB=35, xOffset=0, yOffset=0,
 sortMode="recent", applicationFade=1.25, deathTimeout=15,
 pulseOnCrit=true, pulseScale=1.16, pulseDuration=0.18,
 clearOnCombatEnd=false,
}
local db, playerGUID, petGUID
local targets, displays = {}, {}
local refreshElapsed, cleanupElapsed = 0, 0
local lower, floor, format = string.lower, math.floor, string.format

local function DeepCopy(src)
 local out={}
 for k,v in pairs(src) do out[k]=type(v)=="table" and DeepCopy(v) or v end
 return out
end
local function CopyDefaults(dst, src)
 for k,v in pairs(src) do
  if dst[k] == nil then dst[k]=type(v)=="table" and DeepCopy(v) or v
  elseif type(v)=="table" and type(dst[k])=="table" then CopyDefaults(dst[k],v) end
 end
end
local function Chat(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffMSBT DoT:|r "..tostring(msg)) end
local function FormatNumber(v)
 v=tonumber(v) or 0
 if not db or not db.compactNumbers then return BreakUpLargeNumbers and BreakUpLargeNumbers(floor(v+0.5)) or tostring(floor(v+0.5)) end
 if v>=1000000000 then return format("%.2fb",v/1000000000) end
 if v>=1000000 then return format("%.2fm",v/1000000) end
 if v>=1000 then return format("%.1fk",v/1000) end
 return tostring(floor(v+0.5))
end
local function Allowed(id,name)
 if db.allPeriodic then return true end
 return (id and db.whitelist[id]) or (name and db.whitelist[lower(name)])
end
local function Mine(guid) return guid==playerGUID or (db.includePet and petGUID and guid==petGUID) end

local function ResolveSpellTexture(id,name)
 local texture
 if GetSpellTexture then
  if id then texture=GetSpellTexture(id) end
  if not texture and name then texture=GetSpellTexture(name) end
 end
 if not texture and GetSpellInfo then
  if id then texture=select(3,GetSpellInfo(id)) end
  if not texture and name then texture=select(3,GetSpellInfo(name)) end
 end
 return texture
end
local function ResolveStackIcon()
 local source=db and db.stackIconSource
 if not source or source=="" then return "Interface\\Icons\\Ability_Rogue_Hemorrhage" end
 local id=tonumber(source)
 local texture=ResolveSpellTexture(id,id and nil or source)
 if texture then return texture end
 if source:find("\\") or source:find("/") then return source end
 return "Interface\\Icons\\"..source
end

local function ScrollSettings()
 local areas = MikSBT and MikSBT.Animations and MikSBT.Animations.scrollAreas
 local area = areas and (areas[db.scrollArea] or areas.Outgoing)
 local profile = MikSBT and MikSBT.Profiles and MikSBT.Profiles.currentProfile
 return area, profile
end
local function FontPath()
 local area, profile = ScrollSettings()
 local media = MikSBT and MikSBT.Media
 local fonts = media and media.fonts
 if not db.inheritFont and db.fontName and fonts and fonts[db.fontName] then return fonts[db.fontName] end
 local name = area and area.normalFontName or profile and profile.normalFontName
 return fonts and fonts[name] or "Fonts\\FRIZQT__.TTF"
end
local function AnchorPoint(index)
 local area = ScrollSettings()
 local x = (area and area.offsetX or 100) + (db.xOffset or 0)
 local y = (area and area.offsetY or -160) + (db.yOffset or 0)
 return x, y - ((index-1) * ((db.fontSize or 26)+(db.spacing or 6)))
end
local function EnsureDisplay(i)
 if displays[i] then return displays[i] end
 local f=CreateFrame("Frame","MSBTCumulativeDotSticky"..i,UIParent)
 f:SetFrameStrata("HIGH"); f:SetWidth(700); f:SetHeight(55)
 local t=f:CreateFontString(nil,"OVERLAY")
 t:SetAllPoints(f); t:SetJustifyV("MIDDLE"); t:SetWordWrap(false)
 f.text=t; f.pulseUntil=0; f:Hide(); displays[i]=f; return f
end
local function HideAll() for _,f in ipairs(displays) do f:Hide(); f:SetScale(1) end end
local function Sorted()
 local list={}
 for guid,r in pairs(targets) do if r.total>0 then r.guid=guid; list[#list+1]=r end end
 table.sort(list,function(a,b)
  if db.sortMode=="damage" then
   if a.total==b.total then return (a.name or "")<(b.name or "") end
   return a.total>b.total
  elseif db.sortMode=="name" then return (a.name or "")<(b.name or "")
  else
   if a.lastDamage==b.lastDamage then return a.total>b.total end
   return a.lastDamage>b.lastDamage
  end
 end)
 return list
end
local function SpellParts(r)
 -- Icons are independent flair: they may be shown even when the text mode is
 -- "Damage only".  Only return nothing when both labels and icons are disabled.
 if db.spellLabelMode=="none" and not db.showSpellIcons then return nil end
 local list={}
 for id,s in pairs(r.spells) do
  if s.total>0 and (not db.activeSpellsOnly or r.active[id]) then list[#list+1]={id=id,name=s.name,total=s.total,icon=s.icon} end
 end
 table.sort(list,function(a,b) return a.total>b.total end)
 local parts={}
 local iconSize=math.max(12,(db.fontSize or 26)-5)
 for i=1,math.min(#list,db.maxSpellLabels or 4) do
  local s=list[i]; local text=""
  if db.showSpellIcons and s.icon then text=text.."|T"..s.icon..":"..iconSize..":"..iconSize.."|t" end
  if db.spellLabelMode~="none" then
   if text~="" then text=text.." " end
   text=text..(s.name or tostring(s.id))
   if db.spellLabelMode=="breakdown" then text=text.." "..FormatNumber(s.total) end
  end
  if text~="" then parts[#parts+1]=text end
 end
 if #list>(db.maxSpellLabels or 4) and db.spellLabelMode~="none" then parts[#parts+1]="+"..(#list-(db.maxSpellLabels or 4)) end
 -- Icons sit cleanly beside each other; labeled spells retain the separator.
 local separator=db.spellLabelMode=="none" and " " or " |cffaaaaaa•|r "
 return #parts>0 and table.concat(parts,separator) or nil
end

local function CombinedSpellRecord(list)
 local combined={spells={},active={}}
 for _,r in ipairs(list) do
  for id,s in pairs(r.spells) do
   local c=combined.spells[id]
   if not c then c={name=s.name,total=0,icon=s.icon}; combined.spells[id]=c end
   c.total=c.total+(s.total or 0)
   if r.active[id] then combined.active[id]=true end
  end
 end
 return combined
end
local function MainText(r,total,targetCount)
 local parts={}
 if db.showTargetName then
  if r then parts[#parts+1]=(r.name or "Unknown")
  elseif targetCount and targetCount>1 then parts[#parts+1]=targetCount.." targets" end
 end
 if r then
  local spells=SpellParts(r); if spells then parts[#parts+1]=spells end
 end
 local dmg=FormatNumber(total)
 if db.showDamageLabel then dmg=dmg.." damage" end
 local body=table.concat(parts,"  ")
 if body~="" then body=body.."  " end
 body=body..dmg
 if db.stackIconEnabled then
  local size=tonumber(db.stackIconSize) or math.max(18,(db.fontSize or 26))
  local icon="|T"..ResolveStackIcon()..":"..size..":"..size.."|t"
  if db.stackIconPosition=="right" then body=body.."  "..icon else body=icon.."  "..body end
 end
 return body
end
local function ApplyStyle(f,index)
 local x,y=AnchorPoint(index)
 f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"CENTER",x,y)
 f.text:SetFont(FontPath(),db.fontSize or 26,db.outline or "THICKOUTLINE")
 f.text:SetTextColor((db.colorR or 255)/255,(db.colorG or 190)/255,(db.colorB or 35)/255,1)
 f.text:SetJustifyH(db.alignment or "CENTER")
end
local function Pulse(f)
 if not db.pulseOnCrit then return end
 f.pulseUntil=GetTime()+(db.pulseDuration or .18)
end
function tracker:RefreshDisplay()
 if not db or not db.enabled then HideAll(); return end
 local list=Sorted(); HideAll()
 if db.displayMode=="combined" then
  local total,count,crit=0,0,false
  for _,r in ipairs(list) do total=total+r.total; count=count+1; if r.lastCrit and GetTime()-r.lastCrit<.3 then crit=true end end
  if total>0 then
   local f=EnsureDisplay(1); ApplyStyle(f,1); local combined=CombinedSpellRecord(list)
   f.text:SetText(MainText(combined,total,count)); if crit then Pulse(f) end; f:Show()
  end
 else
  for i=1,math.min(#list,db.maxTargets or 8) do
   local r=list[i]; local f=EnsureDisplay(i); ApplyStyle(f,i)
   f.text:SetText(MainText(r,r.total)); if r.lastCrit and GetTime()-r.lastCrit<.3 then Pulse(f); r.lastCrit=nil end; f:Show()
  end
 end
end
local function Record(guid,name)
 if not guid then return nil end
 local r=targets[guid]
 if not r then r={name=name or "Unknown",total=0,spells={},active={},lastDamage=GetTime()}; targets[guid]=r
 elseif name and name~="" then r.name=name end
 return r
end
local function ResetSpell(r,id)
 local s=r.spells[id]
 if s then r.total=math.max(0,r.total-s.total) end
 r.spells[id]=nil; r.active[id]=true; r.removeAt=nil
end
local function Aura(ev,src,dst,dstName,id,name)
 if not Mine(src) or not Allowed(id,name) then return end
 local r=Record(dst,dstName); if not r then return end
 if ev=="SPELL_AURA_APPLIED" or ev=="SPELL_AURA_REFRESH" then
  if db.mode=="application" then ResetSpell(r,id) else r.active[id]=true end
 elseif ev=="SPELL_AURA_REMOVED" then
  r.active[id]=nil
  if db.mode=="application" then
   local s=r.spells[id]; if s then r.total=math.max(0,r.total-s.total); r.spells[id]=nil end
   local any=false for _ in pairs(r.active) do any=true break end
   if not any then r.removeAt=GetTime()+(db.applicationFade or 1.25) end
  end
 end
 tracker:RefreshDisplay()
end
local function Damage(src,dst,dstName,id,name,amount,critical)
 if not Mine(src) or not Allowed(id,name) then return end
 amount=tonumber(amount); if not amount or amount<=0 then return end
 local r=Record(dst,dstName); if not r then return end
 local s=r.spells[id]
 if not s then s={name=name or tostring(id),total=0,icon=ResolveSpellTexture(id,name)}; r.spells[id]=s end
 s.name=name or s.name; s.icon=s.icon or ResolveSpellTexture(id,name); s.total=s.total+amount
 r.total=r.total+amount; r.lastDamage=GetTime(); r.removeAt=nil
 if critical or db.pulseOnTick then r.lastCrit=GetTime() end
 tracker:RefreshDisplay()
end
local function Remove(guid) if targets[guid] then targets[guid]=nil; tracker:RefreshDisplay() end end
local function ResetAll() for k in pairs(targets) do targets[k]=nil end tracker:RefreshDisplay() end
local function CombatLogEvent(...)
 local _,ev,src,_,_,dst,dstName=...
 if ev=="UNIT_DIED" or ev=="UNIT_DESTROYED" or ev=="PARTY_KILL" then Remove(dst); return end
 if ev=="SPELL_PERIODIC_DAMAGE" then
  local id,name,_,amount,_,_,_,_,_,critical=select(9,...); Damage(src,dst,dstName,id,name,amount,critical)
 elseif ev=="SPELL_AURA_APPLIED" or ev=="SPELL_AURA_REFRESH" or ev=="SPELL_AURA_REMOVED" then
  local id,name=select(9,...); Aura(ev,src,dst,dstName,id,name)
 end
end
local function ResetDefaults()
 local enabled=db.enabled
 for k in pairs(db) do db[k]=nil end
 CopyDefaults(db,defaults); db.enabled=enabled
 ResetAll()
end
local function Test()
 targets.TEST1={name="Training Dummy",total=128450,lastDamage=GetTime(),lastCrit=GetTime(),spells={
  [172]={name="Corruption",total=73450,icon="Interface\\Icons\\Spell_Shadow_AbominationExplosion"},
  [348]={name="Immolate",total=55000,icon="Interface\\Icons\\Spell_Fire_Immolation"}},active={[172]=true,[348]=true}}
 targets.TEST2={name="Second Target",total=74280,lastDamage=GetTime()-1,spells={
  [980]={name="Curse of Agony",total=74280,icon="Interface\\Icons\\Spell_Shadow_CurseOfSargeras"}},active={[980]=true}}
 tracker:RefreshDisplay()
end
local function OpenOptions()
 if not IsAddOnLoaded("MSBTOptions") then local loaded,reason=LoadAddOn("MSBTOptions"); if not loaded then Chat("Unable to load MSBTOptions: "..tostring(reason)); return end end
 if MSBTOptions and MSBTOptions.Main and MSBTOptions.Main.ShowMainFrame then MSBTOptions.Main.ShowMainFrame() else Chat("MSBTOptions loaded, but the main options frame is unavailable.") end
end
local function Slash(msg)
 local cmd,rest=(msg or ""):match("^(%S*)%s*(.-)$"); cmd=lower(cmd or "")
 if cmd=="" or cmd=="options" then OpenOptions()
 elseif cmd=="reset" then ResetAll(); Chat("Totals reset")
 elseif cmd=="mode" and (rest=="death" or rest=="application") then db.mode=rest; Chat("Mode: "..rest)
 elseif cmd=="display" and (rest=="targets" or rest=="combined") then db.displayMode=rest; tracker:RefreshDisplay()
 elseif cmd=="add" then local id=tonumber(rest); db.whitelist[id or lower(rest)]=true; Chat("Added "..rest)
 elseif cmd=="remove" then local id=tonumber(rest); db.whitelist[id or lower(rest)]=nil; Chat("Removed "..rest)
 else Chat("/msbt opens all settings. /msbtdot reset, mode death|application, display targets|combined, add <spell>, remove <spell>") end
end

MikSBT = MikSBT or {}
MikSBT.CumulativeDots = {
 GetDB=function() return db end, GetDefaults=function() return defaults end, GetFontPath=function() return FontPath() end,
 GetStackIconTexture=function() return ResolveStackIcon() end,
 Refresh=function() tracker:RefreshDisplay() end, Reset=ResetAll, Test=Test, ResetDefaults=ResetDefaults,
 AddWhitelist=function(value) if db and value and value~="" then local id=tonumber(value); db.whitelist[id or lower(value)]=true end end,
 RemoveWhitelist=function(value) if db and value and value~="" then local id=tonumber(value); db.whitelist[id or lower(value)]=nil end end,
 ClearWhitelist=function() if db then db.whitelist={} end end,
 GetFonts=function() local t={} if MikSBT.Media and MikSBT.Media.fonts then for name in pairs(MikSBT.Media.fonts) do t[#t+1]=name end end table.sort(t); return t end,
}

tracker:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if (...)~=addonName then return end
  MSBTCumulativeDotsDB=MSBTCumulativeDotsDB or {}; db=MSBTCumulativeDotsDB; CopyDefaults(db,defaults)
  playerGUID=UnitGUID("player"); petGUID=UnitGUID("pet")
  SLASH_MSBTCUMULATIVEDOTS1="/msbtdot"; SLASH_MSBTCUMULATIVEDOTS2="/dotcounter"; SlashCmdList.MSBTCUMULATIVEDOTS=Slash
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED"); self:RegisterEvent("PLAYER_ENTERING_WORLD"); self:RegisterEvent("UNIT_PET"); self:RegisterEvent("PLAYER_REGEN_ENABLED"); self:UnregisterEvent("ADDON_LOADED")
 elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then CombatLogEvent(...)
 elseif event=="PLAYER_ENTERING_WORLD" then playerGUID=UnitGUID("player"); petGUID=UnitGUID("pet"); ResetAll()
 elseif event=="UNIT_PET" and (...)=="player" then petGUID=UnitGUID("pet")
 elseif event=="PLAYER_REGEN_ENABLED" and db and db.clearOnCombatEnd then ResetAll() end
end)
tracker:SetScript("OnUpdate",function(_,elapsed)
 if not db then return end
 local now=GetTime()
 for _,f in ipairs(displays) do
  if f:IsShown() and f.pulseUntil and f.pulseUntil>now then
   local p=(f.pulseUntil-now)/(db.pulseDuration or .18); f:SetScale(1+((db.pulseScale or 1.16)-1)*p)
  elseif f:GetScale()~=1 then f:SetScale(1) end
 end
 refreshElapsed=refreshElapsed+elapsed; cleanupElapsed=cleanupElapsed+elapsed
 if refreshElapsed>=.2 then refreshElapsed=0; tracker:RefreshDisplay() end
 if cleanupElapsed>=1 then
  cleanupElapsed=0; local changed
  for guid,r in pairs(targets) do
   if db.mode=="application" and r.removeAt and now>=r.removeAt then targets[guid]=nil; changed=true
   elseif db.mode=="death" and not UnitAffectingCombat("player") and now-r.lastDamage>(db.deathTimeout or 15) then targets[guid]=nil; changed=true end
  end
  if changed then tracker:RefreshDisplay() end
 end
end)
tracker:RegisterEvent("ADDON_LOADED")
