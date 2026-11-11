-- ForeverGruppe.lua
-- Unser Gruppen-Addon fuer World of Warcraft: Forever.
-- Version 0.1.x kann genau eines: die Namen fremder Spieler blass machen oder
-- ausblenden, damit der Bildschirm ruhiger wird. Das betrifft ihre
-- Namensplaketten und die freien Namen ohne Plakette, die das Spiel von weitem
-- zeichnet (samt Namen von Begleitern, Dienern und Totems). Die eigene Gruppe
-- bleibt immer gut sichtbar. Alles nur Anzeige, keine Spielaktion.
--
-- Befehle: /gruppe namen an | nah | aus,  /gruppe nah <Meter>,  /gruppe bericht

local ADDON_NAME = ...
local VERSION = "0.1.1"
local P = "|cff33ff99Gruppe|r "

local STANDARD = {
  namen = "nah",   -- an = wie Blizzard, nah = blass und nur in der Naehe, aus = unsichtbar
  nah = 20,        -- Meter, ab denen fremde Plaketten ausgeblendet werden (Modus "nah")
}
local BLASS = 0.35  -- Deckkraft fremder Plaketten im Modus "nah"

-- Blizzard-Einstellungen (CVars), die der Modus "nah" bzw. "aus" setzt.
-- Die Originalwerte werden beim ersten Mal gesichert und bei "an" zurueckgesetzt.
local function gewuenschteCVars(db)
  local t = { nameplateShowFriendlyPlayers = "1" }
  if db.namen ~= "an" then
    -- freie Namen ueber Spielern ohne Plakette (von weitem) und ueber ihren Begleitern
    t.UnitNameFriendlyPlayerName = "0"
    t.UnitNameFriendlyPetName = "0"
    t.UnitNameFriendlyGuardianName = "0"
    t.UnitNameFriendlyMinionName = "0"
    t.UnitNameFriendlyTotemName = "0"
  end
  if db.namen == "nah" then
    t.nameplateMinAlpha = "0"
    t.nameplateMaxAlpha = "1"
    t.nameplateMaxAlphaDistance = tostring(db.nah)
  end
  return t
end
local VERWALTETE_CVARS = { "nameplateShowFriendlyPlayers", "nameplateMinAlpha", "nameplateMaxAlpha", "nameplateMaxAlphaDistance",
  "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName", "UnitNameFriendlyGuardianName", "UnitNameFriendlyMinionName",
  "UnitNameFriendlyTotemName" }

local db
local Rahmen = CreateFrame("Frame")
local geplant = {}           -- Plaketten-Einheiten, die wir gerade gestalten
local cvarsAusstehend = false

-- Protokoll fuer Georg (liegt in den SavedVariables) ------------------------

local function protokoll(text)
  if not db then return end
  db.protokoll = db.protokoll or {}
  table.insert(db.protokoll, date("%Y-%m-%d %H:%M:%S") .. "  " .. text)
  while #db.protokoll > 200 do table.remove(db.protokoll, 1) end
end

local function sicher(fn, ...)
  local ok, a, b = pcall(fn, ...)
  if ok then return a, b end
  protokoll("FEHLER: " .. tostring(a))
  return nil
end

-- Wer ist wer? --------------------------------------------------------------

local function wahr(fn, ...)
  local ok, v = pcall(fn, ...)
  if not ok then return false end
  local ok2, ja = pcall(function() if v then return true end return false end)
  return ok2 and ja
end

-- "gruppe", "fremd" (fremder freundlicher Spieler) oder "sonst" (NPCs, Gegner)
local function einordnen(unit)
  if wahr(UnitIsUnit, unit, "player") or wahr(UnitInParty, unit) or wahr(UnitInRaid, unit) then
    return "gruppe"
  end
  if wahr(UnitIsPlayer, unit) and not wahr(UnitIsEnemy, "player", unit) then
    return "fremd"
  end
  return "sonst"
end

local function hervorgehoben(unit)
  return wahr(UnitIsUnit, unit, "target") or wahr(UnitIsUnit, unit, "mouseover")
end

-- Plaketten gestalten -------------------------------------------------------

local function plaketteZu(unit)
  local np = sicher(C_NamePlate.GetNamePlateForUnit, unit)
  if not np then return nil end
  if np.IsForbidden and np:IsForbidden() then return nil end
  return np.UnitFrame
end

local function setzeAlpha(uf, ignoriereEltern, alpha)
  sicher(function()
    if uf.SetIgnoreParentAlpha then uf:SetIgnoreParentAlpha(ignoriereEltern) end
    uf:SetAlpha(alpha)
  end)
end

local function gestalte(unit)
  local uf = plaketteZu(unit)
  if not uf then return end
  local art = einordnen(unit)
  if db.namen == "an" or art == "sonst" then
    setzeAlpha(uf, false, 1)
  elseif art == "gruppe" then
    setzeAlpha(uf, true, 1)          -- Gruppe immer voll sichtbar, auch auf Entfernung
  elseif hervorgehoben(unit) then
    setzeAlpha(uf, true, 1)          -- Ziel oder Maus drueber: voll sichtbar
  else
    setzeAlpha(uf, false, db.namen == "aus" and 0 or BLASS)
  end
end

local function allesGestalten()
  for unit in pairs(geplant) do gestalte(unit) end
end

local function zuruecksetzen(unit)
  local uf = plaketteZu(unit)
  if uf then setzeAlpha(uf, false, 1) end
end

-- Blizzard-Einstellungen ----------------------------------------------------

local function setzeCVars()
  if InCombatLockdown() then
    cvarsAusstehend = true
    protokoll("Einstellungen warten auf Kampfende")
    return
  end
  cvarsAusstehend = false
  db.original = db.original or {}
  local wunsch = gewuenschteCVars(db)
  for _, name in ipairs(VERWALTETE_CVARS) do
    local jetzt = C_CVar.GetCVar(name)
    if db.original[name] == nil and jetzt ~= nil then db.original[name] = jetzt end
    local ziel = wunsch[name]
    if db.namen == "an" or ziel == nil then ziel = db.original[name] end
    if ziel ~= nil and jetzt ~= ziel then
      local ok = sicher(C_CVar.SetCVar, name, ziel)
      protokoll(string.format("CVar %s: %s -> %s (%s)", name, tostring(jetzt), ziel, ok and "ok" or "abgelehnt"))
    end
  end
end

local function anwenden()
  setzeCVars()
  allesGestalten()
end

-- Bericht fuer Gerald -------------------------------------------------------

local function bericht()
  local z = {}
  z[#z + 1] = "ForeverGruppe " .. VERSION .. ", Bericht vom " .. date("%Y-%m-%d %H:%M:%S")
  z[#z + 1] = "Modus namen=" .. db.namen .. ", nah=" .. db.nah .. " m, Kampf=" .. tostring(InCombatLockdown())
  for _, name in ipairs(VERWALTETE_CVARS) do
    z[#z + 1] = string.format("  CVar %s = %s (Original %s)", name, tostring(C_CVar.GetCVar(name)), tostring(db.original and db.original[name]))
  end
  local zahl = { gruppe = 0, fremd = 0, sonst = 0 }
  for unit in pairs(geplant) do
    local art = einordnen(unit)
    zahl[art] = zahl[art] + 1
    local uf = plaketteZu(unit)
    local np = sicher(C_NamePlate.GetNamePlateForUnit, unit)
    local name = sicher(function() return (UnitName(unit)) end)
    local entf = sicher(function()
      local d, gueltig = UnitDistanceSquared(unit)
      if issecretvalue and issecretvalue(d) then return "geheim" end
      if gueltig and d then return string.format("%.0f m", math.sqrt(d)) end
      return "unbekannt"
    end)
    z[#z + 1] = string.format("  %s %-7s %-24s Plakette=%s Rahmen=%s wirksam=%s Entfernung=%s", unit, art, tostring(name),
      tostring(np and sicher(np.GetAlpha, np)), tostring(uf and sicher(uf.GetAlpha, uf)),
      tostring(uf and sicher(uf.GetEffectiveAlpha, uf)), tostring(entf))
  end
  z[#z + 1] = string.format("Plaketten: %d Gruppe, %d fremd, %d sonst", zahl.gruppe, zahl.fremd, zahl.sonst)
  z[#z + 1] = "Letzte Protokollzeilen:"
  local p = db.protokoll or {}
  for i = math.max(1, #p - 9), #p do z[#z + 1] = "  " .. p[i] end
  local text = table.concat(z, "\n")
  db.bericht = text
  print(P .. string.format("Bericht gespeichert: %d Gruppe, %d fremd, %d sonst. Nach /reload in WTF\\...\\SavedVariables\\ForeverGruppe.lua.",
    zahl.gruppe, zahl.fremd, zahl.sonst))
end

-- Ereignisse ----------------------------------------------------------------

Rahmen:RegisterEvent("ADDON_LOADED")
Rahmen:RegisterEvent("PLAYER_ENTERING_WORLD")
Rahmen:RegisterEvent("NAME_PLATE_UNIT_ADDED")
Rahmen:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
Rahmen:RegisterEvent("GROUP_ROSTER_UPDATE")
Rahmen:RegisterEvent("PLAYER_TARGET_CHANGED")
Rahmen:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
Rahmen:RegisterEvent("PLAYER_REGEN_ENABLED")

Rahmen:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON_NAME then return end
    ForeverGruppeDB = ForeverGruppeDB or {}
    db = ForeverGruppeDB
    for k, v in pairs(STANDARD) do if db[k] == nil then db[k] = v end end
    db.version = VERSION
    protokoll("geladen, Modus namen=" .. db.namen)
  elseif not db then
    return
  elseif event == "PLAYER_ENTERING_WORLD" then
    anwenden()
    if not self.begruesst then
      self.begruesst = true
      print(P .. VERSION .. " geladen. Fremde Namen: " .. db.namen .. ". Hilfe: /gruppe")
    end
  elseif event == "NAME_PLATE_UNIT_ADDED" then
    geplant[arg1] = true
    gestalte(arg1)
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    zuruecksetzen(arg1)
    geplant[arg1] = nil
  elseif event == "PLAYER_REGEN_ENABLED" then
    if cvarsAusstehend then setzeCVars() end
  else
    allesGestalten()   -- Gruppe, Ziel oder Maus haben sich geaendert
  end
end)

-- Die Maus verlaesst eine Figur ohne eigenes Ereignis; darum alle 0,25 s nachsehen.
local verstrichen = 0
Rahmen:SetScript("OnUpdate", function(self, dt)
  verstrichen = verstrichen + dt
  if verstrichen < 0.25 or not db or db.namen == "an" then return end
  verstrichen = 0
  allesGestalten()
end)

-- Befehle -------------------------------------------------------------------

local function hilfe()
  print(P .. VERSION .. "  Fremde Namen: " .. db.namen .. (db.namen == "nah" and (" (" .. db.nah .. " m)") or ""))
  print("  /gruppe namen an    alle Namen wie bei Blizzard")
  print("  /gruppe namen nah   fremde Spieler blass, nur in der Naehe")
  print("  /gruppe namen aus   fremde Spieler unsichtbar (Ziel und Maus drueber zeigen sie)")
  print("  /gruppe nah 15      Entfernung fuer 'nah' in Metern (5 bis 40)")
  print("  /gruppe bericht     Bericht fuer Gerald speichern")
end

SLASH_FOREVERGRUPPE1 = "/gruppe"
SlashCmdList["FOREVERGRUPPE"] = function(eingabe)
  if not db then return end
  local befehl, wert = string.match(string.lower(strtrim(eingabe or "")), "^(%S*)%s*(.-)$")
  if befehl == "namen" and (wert == "an" or wert == "nah" or wert == "aus") then
    db.namen = wert
    protokoll("Modus namen=" .. wert)
    anwenden()
    print(P .. "Fremde Namen: " .. wert .. (InCombatLockdown() and " (Einstellungen folgen nach dem Kampf)" or ""))
  elseif befehl == "nah" and tonumber(wert) then
    db.nah = math.max(5, math.min(40, math.floor(tonumber(wert))))
    protokoll("nah=" .. db.nah)
    anwenden()
    print(P .. "Entfernung fuer 'nah': " .. db.nah .. " m")
  elseif befehl == "bericht" then
    bericht()
  else
    hilfe()
  end
end
