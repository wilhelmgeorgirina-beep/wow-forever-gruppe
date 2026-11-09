-- GruppeDiag.lua
-- Diagnose-Addon fuer World of Warcraft: Forever.
-- Prueft, welche Schnittstellen das Spiel Addons anbietet (Namensplaketten,
-- Zielmarkierungen, Gruppendaten, CVars, Ton, Addon-Nachrichten), und schreibt
-- einen Bericht in ein Fenster zum Kopieren und in die SavedVariables.
-- Es veraendert nichts am Spiel und loest keine Spielaktionen aus.

local ADDON_NAME = ...
local VERSION = "0.1.0"

local G = _G
local pcall, type, tostring, select, ipairs = pcall, type, tostring, select, ipairs
local istGeheimFunktion = rawget(G, "issecretvalue")

local Diag = CreateFrame("Frame", "GruppeDiagFrame")
local zeilen = {}            -- Zeilen des gerade entstehenden Berichts
local zaehler = {}           -- Ereigniszaehler seit Login
local registerFehler = {}    -- Ereignisse, die sich nicht anmelden liessen
local kampfprobe = nil       -- automatische Messung im Kampf

-- Hilfsfunktionen -----------------------------------------------------------

local function pack(...)
  return { n = select("#", ...), ... }
end

local function istGeheim(v)
  if istGeheimFunktion then
    local ok, geheim = pcall(istGeheimFunktion, v)
    return ok and geheim == true
  end
  return false
end

-- Wandelt einen Wert gefahrlos in Text um, ohne geheime Werte anzufassen.
local function txt(v)
  if istGeheim(v) then return "<GEHEIM>" end
  local t = type(v)
  if t == "string" then return v end
  if t == "nil" then return "nil" end
  if t == "boolean" then return v and "ja" or "nein" end
  if t == "number" then return tostring(v) end
  if t == "table" then
    local ok, art = pcall(function() return v.GetObjectType and v:GetObjectType() end)
    if ok and art then
      local ok2, name = pcall(function() return v.GetName and v:GetName() end)
      return "<" .. tostring(art) .. ((ok2 and name) and (" " .. tostring(name)) or "") .. ">"
    end
    return "<Tabelle>"
  end
  return "<" .. t .. ">"
end

local function z(s) zeilen[#zeilen + 1] = s end
local function kopf(s) z(""); z("== " .. s .. " ==") end

local function fmt(muster, ...)
  local ok, s = pcall(string.format, muster, ...)
  return ok and s or ("FORMATFEHLER: " .. tostring(s))
end

-- Holt eine globale Funktion oder Tabelle ueber ihren Pfad, z. B. "C_NamePlate.GetNamePlates".
local function hole(pfad)
  local obj = G
  for teil in string.gmatch(pfad, "[^%.]+") do
    if type(obj) ~= "table" then return nil end
    local ok, v = pcall(function() return obj[teil] end)
    if not ok or v == nil then return nil end
    obj = v
  end
  return obj
end

-- Ruft die Funktion unter pfad gefahrlos auf und liefert alle Ergebnisse als Text.
local function ruf(pfad, ...)
  local f = hole(pfad)
  if type(f) ~= "function" then return "FEHLT" end
  local erg = pack(pcall(f, ...))
  if not erg[1] then return "FEHLER: " .. txt(erg[2]) end
  if erg.n < 2 then return "(nichts)" end
  local teile = {}
  for i = 2, erg.n do teile[#teile + 1] = txt(erg[i]) end
  return table.concat(teile, ", ")
end

-- Liest ein Feld aus einem Frame gefahrlos.
local function feld(obj, name)
  if type(obj) ~= "table" then return nil end
  local ok, v = pcall(function() return obj[name] end)
  if ok then return v end
  return nil
end

-- Fuehrt fn gefahrlos aus und liefert das Ergebnis als Text.
local function probe(fn)
  local ok, v = pcall(fn)
  if not ok then return "FEHLER: " .. txt(v) end
  return txt(v)
end

-- Was geprueft wird --------------------------------------------------------

local FUNKTIONEN = {
  { "Spiel und Addon", {
    "GetBuildInfo", "C_AddOns.GetAddOnMetadata", "GetAddOnMetadata",
    "C_CVar.GetCVar", "C_CVar.SetCVar", "C_CVar.GetCVarInfo", "GetCVar", "SetCVar", "GetCVarInfo",
    "hooksecurefunc", "issecretvalue", "canaccessvalue", "InCombatLockdown", "IsInInstance",
    "C_Timer.After", "C_Timer.NewTicker", "CreateFrame", "CreateColor", "Mixin" } },
  { "Namensplaketten", {
    "C_NamePlate.GetNamePlates", "C_NamePlate.GetNamePlateForUnit",
    "C_NamePlate.GetNamePlateFriendlySize", "C_NamePlate.GetNamePlateEnemySize", "C_NamePlate.GetNamePlateSelfSize",
    "C_NamePlate.SetNamePlateFriendlySize", "C_NamePlate.SetNamePlateEnemySize", "C_NamePlate.SetNamePlateSelfSize",
    "C_NamePlate.SetNamePlateFriendlyClickThrough", "C_NamePlate.SetNamePlateEnemyClickThrough",
    "C_NamePlate.SetTargetClampingInsets", "UnitNameplateShowsWidgetsOnly",
    "CompactUnitFrame_UpdateHealth", "CompactUnitFrame_UpdateName", "CompactUnitFrame_UpdateHealthColor",
    "CompactUnitFrame_SetUnit", "CompactUnitFrame_UpdateAll",
    "DefaultCompactNamePlateFrameSetup", "DefaultCompactNamePlateFriendlyFrameSetup",
    "DefaultCompactNamePlateEnemyFrameSetup", "DefaultCompactUnitFrameSetup" } },
  { "Zielmarkierungen", {
    "GetRaidTargetIndex", "SetRaidTargetIconTexture", "SetRaidTargetIconFrame", "SetRaidTarget" } },
  { "Gruppe und Rollen", {
    "IsInGroup", "IsInRaid", "GetNumGroupMembers", "GetNumSubgroupMembers", "UnitInParty", "UnitInRaid",
    "UnitIsGroupLeader", "UnitIsGroupAssistant", "UnitGroupRolesAssigned", "UnitGroupRolesAssignedEnum",
    "UnitSetRole", "GetSpecialization", "GetSpecializationRole", "GetRaidRosterInfo", "GetPartyAssignment" } },
  { "Einheiten", {
    "UnitExists", "UnitName", "GetUnitName", "UnitGUID", "UnitClass", "UnitClassBase", "UnitIsPlayer",
    "UnitIsFriend", "UnitIsEnemy", "UnitReaction", "UnitIsPVP", "UnitIsPVPFreeForAll", "UnitFactionGroup",
    "UnitPlayerControlled", "UnitIsUnit", "UnitIsConnected", "UnitIsDeadOrGhost", "UnitAffectingCombat",
    "UnitHealth", "UnitHealthMax", "UnitHealthPercent", "UnitHealthMissing", "UnitGetTotalAbsorbs",
    "UnitGetIncomingHeals", "UnitInRange", "UnitIsVisible", "UnitDistanceSquared" } },
  { "Ton", {
    "PlaySound", "PlaySoundFile", "StopSound", "C_Sound.PlaySound", "C_Sound.PlaySoundFile", "C_Sound.StopSound" } },
  { "Addon-Nachrichten", {
    "C_ChatInfo.RegisterAddonMessagePrefix", "C_ChatInfo.SendAddonMessage",
    "C_ChatInfo.IsAddonMessagePrefixRegistered", "C_ChatInfo.GetRegisteredAddonMessagePrefixes" } },
  { "Oberflaeche (Frames)", {
    "UIParent", "NamePlateDriverFrame", "CompactPartyFrame", "PartyFrame", "CompactRaidFrameContainer",
    "CompactRaidFrameManager", "PlayerFrame", "TargetFrame", "FocusFrame", "RaidWarningFrame",
    "UIErrorsFrame", "EditModeManagerFrame", "BackdropTemplateMixin", "ChatFontNormal", "SOUNDKIT" } },
}

local CVARS = {
  "nameplateShowAll", "nameplateShowSelf", "nameplateShowFriends", "nameplateShowFriendlyPlayers",
  "nameplateShowFriendlyNPCs", "nameplateShowFriendlyNpcs", "nameplateShowFriendlyMinions",
  "nameplateShowFriendlyPets", "nameplateShowFriendlyGuardians", "nameplateShowFriendlyTotems",
  "nameplateShowEnemies", "nameplateShowEnemyMinions", "nameplateShowEnemyMinus", "nameplateShowEnemyPets",
  "nameplateShowEnemyGuardians", "nameplateShowEnemyTotems",
  "nameplateShowOnlyNames", "nameplateShowOnlyNameForFriendlyPlayerUnits",
  "nameplateShowDebuffsOnFriendly", "nameplateShowFriendlyBuffs",
  "nameplateMaxDistance", "nameplatePlayerMaxDistance", "nameplateTargetBehindMaxDistance",
  "nameplateMinScale", "nameplateMaxScale", "nameplateGlobalScale", "nameplateSelectedScale",
  "nameplateLargerScale", "nameplateMinAlpha", "nameplateMaxAlpha", "nameplateMinAlphaDistance",
  "nameplateMaxAlphaDistance", "nameplateOccludedAlphaMult", "nameplateNotSelectedAlpha",
  "nameplateSelectedAlpha", "nameplateSize", "NamePlateHorizontalScale", "NamePlateVerticalScale",
  "NamePlateClassificationScale", "nameplateMotion", "nameplateMotionSpeed", "nameplateOverlapH",
  "nameplateOverlapV", "nameplateOtherTopInset", "nameplateOtherBottomInset", "nameplateLargeTopInset",
  "nameplateLargeBottomInset", "nameplateResourceOnTarget",
  "ShowClassColorInNameplate", "ShowClassColorInFriendlyNameplate", "ShowNamePlateLoseAggroFlash",
  "UnitNameOwn", "UnitNamePlayerGuild", "UnitNamePlayerPVPTitle", "UnitNameGuildTitle",
  "UnitNameFriendlyPlayerName", "UnitNameFriendlyPetName", "UnitNameFriendlyGuardianName",
  "UnitNameFriendlyTotemName", "UnitNameFriendlyMinionName", "UnitNameFriendlySpecialNPCName",
  "UnitNameEnemyPlayerName", "UnitNameEnemyPetName", "UnitNameEnemyGuardianName", "UnitNameEnemyTotemName",
  "UnitNameEnemyMinionName", "UnitNameNPC", "UnitNameHostleNPC", "UnitNameInteractiveNPC",
  "UnitNameNonCombatCreatureName", "UnitNameForceHideMinus",
  "raidFramesDisplayIncomingHeals", "raidFramesDisplayPowerBars", "raidFramesDisplayClassColor",
  "raidFramesHealthText", "useCompactPartyFrames",
}

local EREIGNISSE = {
  "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "GROUP_ROSTER_UPDATE",
  "RAID_TARGET_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "CHAT_MSG_ADDON",
}

-- Berichtsteile --------------------------------------------------------------

local function teilSpiel()
  kopf("Spiel")
  z("GruppeDiag " .. VERSION .. ", Bericht vom " .. date("%Y-%m-%d %H:%M:%S"))
  z("GetBuildInfo (Version, Build, Datum, Interface, ...): " .. ruf("GetBuildInfo"))
  z("WOW_PROJECT_ID: " .. txt(G.WOW_PROJECT_ID)
    .. "  (MAINLINE=" .. txt(G.WOW_PROJECT_MAINLINE) .. ", CLASSIC=" .. txt(G.WOW_PROJECT_CLASSIC)
    .. ", CAMELOT=" .. txt(G.WOW_PROJECT_CAMELOT) .. ")")
  z("Sprache: " .. ruf("GetLocale") .. "  Realm: " .. ruf("GetRealmName"))
  z("Spieler: " .. ruf("UnitName", "player") .. "  Klasse: " .. ruf("UnitClass", "player")
    .. "  Fraktion: " .. ruf("UnitFactionGroup", "player"))
  z("Instanz (IsInInstance): " .. ruf("IsInInstance"))
  z("Im Kampf: " .. ruf("UnitAffectingCombat", "player") .. "  Kampfsperre: " .. ruf("InCombatLockdown"))
  z("Geheime Werte moeglich (issecretvalue vorhanden): " .. txt(istGeheimFunktion ~= nil))
end

local function teilFunktionen()
  kopf("Funktionen und Frames")
  local fehlen, gesamt = 0, 0
  for _, gruppe in ipairs(FUNKTIONEN) do
    local titel, namen = gruppe[1], gruppe[2]
    local da, weg = {}, {}
    for _, name in ipairs(namen) do
      gesamt = gesamt + 1
      local v = hole(name)
      if v == nil then
        fehlen = fehlen + 1
        weg[#weg + 1] = name
      else
        da[#da + 1] = name .. (type(v) == "function" and "" or ("[" .. type(v) .. "]"))
      end
    end
    z("-- " .. titel)
    z("   vorhanden: " .. (#da > 0 and table.concat(da, ", ") or "-"))
    z("   FEHLT:     " .. (#weg > 0 and table.concat(weg, ", ") or "-"))
  end
  z(fmt("Zusammen: %d geprueft, %d fehlen.", gesamt, fehlen))
  return fehlen, gesamt
end

local function teilCVars()
  kopf("CVars (Wert | Standard | Hinweise)")
  local info = hole("C_CVar.GetCVarInfo") or hole("GetCVarInfo")
  if type(info) ~= "function" then
    z("GetCVarInfo FEHLT, nur Werte:")
    for _, name in ipairs(CVARS) do
      z(fmt("%-45s %s", name, ruf("C_CVar.GetCVar", name)))
    end
    return
  end
  for _, name in ipairs(CVARS) do
    local erg = pack(pcall(info, name))
    if not erg[1] then
      z(fmt("%-45s FEHLER: %s", name, txt(erg[2])))
    elseif erg[2] == nil then
      z(fmt("%-45s FEHLT", name))
    else
      -- Rueckgabe: Wert, Standard, Server-Konto, Server-Charakter, gesperrt, sicher, nur lesen
      local hinweise = {}
      if erg[6] then hinweise[#hinweise + 1] = "GESPERRT" end
      if erg[7] then hinweise[#hinweise + 1] = "sicher" end
      if erg[8] then hinweise[#hinweise + 1] = "NUR-LESEN" end
      if erg[4] then hinweise[#hinweise + 1] = "Konto" end
      if erg[5] then hinweise[#hinweise + 1] = "Charakter" end
      z(fmt("%-45s %-8s | %-8s | %s", name, txt(erg[2]), txt(erg[3]), table.concat(hinweise, " ")))
    end
  end
end

-- Prueft, ob Lebenswerte einer Einheit lesbar und vergleichbar sind.
local function lebenstest(u)
  local ok, erg = pcall(function()
    local h, m = UnitHealth(u), UnitHealthMax(u)
    if istGeheim(h) or istGeheim(m) then return "GEHEIM (Wert nicht lesbar)" end
    if h < m * 0.5 then return "vergleichbar, unter 50%" end
    return "vergleichbar, ueber 50%"
  end)
  if ok then return erg end
  return "FEHLER beim Vergleich: " .. txt(erg)
end

local function einheit(u)
  local ok, da = pcall(UnitExists, u)
  if not ok or not da then return false end
  z(fmt("%s: Name=%s | Klasse=%s | Rolle=%s | Marke=%s | Spieler=%s | PvP=%s | Verbunden=%s",
    u, ruf("UnitName", u), ruf("UnitClass", u), ruf("UnitGroupRolesAssigned", u),
    ruf("GetRaidTargetIndex", u), ruf("UnitIsPlayer", u), ruf("UnitIsPVP", u), ruf("UnitIsConnected", u)))
  z(fmt("   Leben=%s / %s | Prozent=%s | Fehlend=%s | Test: %s",
    ruf("UnitHealth", u), ruf("UnitHealthMax", u), ruf("UnitHealthPercent", u),
    ruf("UnitHealthMissing", u), lebenstest(u)))
  return true
end

local function teilGruppe()
  kopf("Gruppe")
  z("In Gruppe: " .. ruf("IsInGroup") .. " | Schlachtzug: " .. ruf("IsInRaid")
    .. " | Mitglieder: " .. ruf("GetNumGroupMembers") .. " | Anfuehrer: " .. ruf("UnitIsGroupLeader", "player"))
  einheit("player")
  local okRaid, raid = pcall(IsInRaid)
  if okRaid and raid then
    for i = 1, 10 do einheit("raid" .. i) end
  else
    for i = 1, 4 do einheit("party" .. i) end
  end
  if UnitExists("target") then
    z("Ziel:")
    einheit("target")
    z("   Reaktion=" .. ruf("UnitReaction", "target", "player") .. " | Feind=" .. ruf("UnitIsEnemy", "player", "target")
      .. " | Freund=" .. ruf("UnitIsFriend", "player", "target") .. " | Spielergesteuert=" .. ruf("UnitPlayerControlled", "target"))
  end
end

local UNITFRAME_TEILE = {
  "healthBar", "HealthBarsContainer", "name", "RaidTargetFrame", "castBar", "CastBar",
  "selectionHighlight", "aggroHighlight", "ClassificationFrame", "LevelFrame", "WidgetContainer",
  "BuffFrame", "SoftTargetFrame", "optionTable", "unit", "displayedUnit",
}

local function plakette(np, nr)
  z(fmt("Plakette %d: %s  Groesse=%s", nr, txt(np), probe(function() return table.concat({ np:GetSize() }, " x ") end)))
  local einheitToken = feld(np, "namePlateUnitToken")
  local uf = feld(np, "UnitFrame")
  if einheitToken == nil and uf then einheitToken = feld(uf, "unit") end
  z("   Einheit: " .. txt(einheitToken))
  if type(einheitToken) == "string" then
    z("   Name=" .. ruf("UnitName", einheitToken) .. " | Spieler=" .. ruf("UnitIsPlayer", einheitToken)
      .. " | Reaktion=" .. ruf("UnitReaction", einheitToken, "player") .. " | Gruppe=" .. ruf("UnitInParty", einheitToken)
      .. " | Marke=" .. ruf("GetRaidTargetIndex", einheitToken) .. " | Leben: " .. lebenstest(einheitToken))
  end
  local okK, kinder = pcall(function() return { np:GetChildren() } end)
  if okK then
    local namen = {}
    for _, k in ipairs(kinder) do namen[#namen + 1] = txt(k) end
    z("   Kinder: " .. (#namen > 0 and table.concat(namen, ", ") or "-"))
  end
  if uf then
    local da, weg = {}, {}
    for _, name in ipairs(UNITFRAME_TEILE) do
      local v = feld(uf, name)
      if v == nil then weg[#weg + 1] = name else da[#da + 1] = name .. "=" .. txt(v) end
    end
    z("   UnitFrame hat: " .. table.concat(da, ", "))
    z("   UnitFrame ohne: " .. (#weg > 0 and table.concat(weg, ", ") or "-"))
    local hb = feld(uf, "healthBar") or feld(feld(uf, "HealthBarsContainer"), "healthBar")
    if hb then
      z("   Lebensbalken: Farbe=" .. probe(function() return table.concat({ hb:GetStatusBarColor() }, " ") end)
        .. " | Groesse=" .. probe(function() return table.concat({ hb:GetSize() }, " x ") end))
    end
    local nm = feld(uf, "name")
    if nm then
      z("   Namenstext: '" .. probe(function() return nm:GetText() end)
        .. "' | Schrift=" .. probe(function() return table.concat({ nm:GetFont() }, " ") end))
    end
    local rt = feld(uf, "RaidTargetFrame")
    if rt then
      z("   Markierungsrahmen: sichtbar=" .. probe(function() return rt:IsShown() end)
        .. " | Groesse=" .. probe(function() return table.concat({ rt:GetSize() }, " x ") end)
        .. " | Icon=" .. txt(feld(rt, "RaidTargetIcon")))
    end
  end
end

local function teilPlaketten()
  kopf("Namensplaketten")
  z("Groesse freundlich: " .. ruf("C_NamePlate.GetNamePlateFriendlySize")
    .. " | feindlich: " .. ruf("C_NamePlate.GetNamePlateEnemySize") .. " | eigene: " .. ruf("C_NamePlate.GetNamePlateSelfSize"))
  z("Treiber-Frame: " .. txt(G.NamePlateDriverFrame))
  local f = hole("C_NamePlate.GetNamePlates")
  if type(f) ~= "function" then z("C_NamePlate.GetNamePlates FEHLT"); return end
  local ok, liste = pcall(f)
  if not ok or type(liste) ~= "table" then z("GetNamePlates FEHLER: " .. txt(liste)); return end
  z("Sichtbare Plaketten: " .. #liste)
  for i, np in ipairs(liste) do
    if i > 4 then z("   ... weitere ausgelassen"); break end
    local okP, err = pcall(plakette, np, i)
    if not okP then z("   Plakette " .. i .. " FEHLER: " .. txt(err)) end
  end
end

local function teilNachrichten()
  kopf("Addon-Nachrichten")
  z("Prefix anmelden (GruppeDiag): " .. ruf("C_ChatInfo.RegisterAddonMessagePrefix", "GruppeDiag"))
  z("Prefix angemeldet: " .. ruf("C_ChatInfo.IsAddonMessagePrefixRegistered", "GruppeDiag"))
  z("Es wurde keine Nachricht gesendet.")
end

local function teilEreignisse()
  kopf("Ereignisse seit Login")
  for _, e in ipairs(EREIGNISSE) do
    z(fmt("%-28s %s", e, registerFehler[e] and ("ANMELDUNG FEHLGESCHLAGEN: " .. registerFehler[e]) or tostring(zaehler[e] or 0)))
  end
  z("UNIT_HEALTH (player, party1): " .. (registerFehler.UNIT_HEALTH or tostring(zaehler.UNIT_HEALTH or 0)))
  z("Erste Plaketten-Einheit: " .. txt(zaehler.erstePlakettenEinheit))
  if kampfprobe then
    z("Kampfprobe (2 s nach Kampfbeginn " .. kampfprobe.zeit .. "): player: " .. kampfprobe.player
      .. " | party1: " .. kampfprobe.party1 .. " | target: " .. kampfprobe.target)
  else
    z("Kampfprobe: noch kein Kampf seit Login.")
  end
end

-- Bericht erstellen ----------------------------------------------------------

local fenster

local function zeigeFenster(text)
  if not fenster then
    local ok, f = pcall(CreateFrame, "Frame", "GruppeDiagFenster", UIParent, "BasicFrameTemplateWithInset")
    if not ok or not f then
      f = CreateFrame("Frame", "GruppeDiagFenster", UIParent)
      local bg = f:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      bg:SetColorTexture(0, 0, 0, 0.85)
      pcall(function()
        local schliessen = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        schliessen:SetPoint("TOPRIGHT", 0, 0)
      end)
    end
    f:SetSize(680, 440)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("GruppeDiag: Bericht (Strg+A, Strg+C zum Kopieren)") end
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local box = CreateFrame("EditBox", nil, scroll)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    box:SetWidth(620)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(box)
    f.box = box
    tinsert(UISpecialFrames, "GruppeDiagFenster")
    fenster = f
  end
  fenster.box:SetText(text)
  fenster:Show()
  fenster.box:SetFocus()
  fenster.box:HighlightText()
end

local function bericht()
  zeilen = {}
  local fehlen, gesamt = 0, 0
  local teile = { teilSpiel, function() fehlen, gesamt = teilFunktionen() end, teilCVars, teilGruppe,
    teilPlaketten, teilNachrichten, teilEreignisse }
  for _, teil in ipairs(teile) do
    local ok, err = pcall(teil)
    if not ok then z("!! Abschnitt abgebrochen: " .. txt(err)) end
  end
  local text = table.concat(zeilen, "\n")

  GruppeDiagDB = GruppeDiagDB or {}
  GruppeDiagDB.berichte = GruppeDiagDB.berichte or {}
  tinsert(GruppeDiagDB.berichte, { zeit = date("%Y-%m-%d %H:%M:%S"), text = text })
  while #GruppeDiagDB.berichte > 3 do tremove(GruppeDiagDB.berichte, 1) end

  print(fmt("|cff33ff99GruppeDiag|r: Bericht mit %d Zeilen erstellt. Interface=%s, %d von %d Funktionen fehlen.",
    #zeilen, txt(select(4, GetBuildInfo())), fehlen, gesamt))
  print("|cff33ff99GruppeDiag|r: Text im Fenster mit Strg+A, Strg+C kopieren. Nach /reload liegt er auch in WTF\\...\\SavedVariables\\GruppeDiag.lua.")
  local ok, err = pcall(zeigeFenster, text)
  if not ok then print("|cff33ff99GruppeDiag|r: Fenster FEHLER: " .. txt(err)) end
end

local function tontest()
  local kit = (G.SOUNDKIT and G.SOUNDKIT.RAID_WARNING) or 8959
  print("|cff33ff99GruppeDiag|r Ton 1 (Blizzard-Klang RAID_WARNING): " .. ruf("PlaySound", kit, "Master"))
  print("|cff33ff99GruppeDiag|r Ton 2 (eigene Datei ton.ogg): "
    .. ruf("PlaySoundFile", "Interface\\AddOns\\GruppeDiag\\ton.ogg", "Master"))
end

-- Ereignisse -----------------------------------------------------------------

Diag:RegisterEvent("ADDON_LOADED")
for _, e in ipairs(EREIGNISSE) do
  local ok, err = pcall(Diag.RegisterEvent, Diag, e)
  if not ok then registerFehler[e] = txt(err) end
end
do
  local ok, err = pcall(Diag.RegisterUnitEvent, Diag, "UNIT_HEALTH", "player", "party1")
  if not ok then registerFehler.UNIT_HEALTH = "ANMELDUNG FEHLGESCHLAGEN: " .. txt(err) end
end

Diag:SetScript("OnEvent", function(self, event, arg1)
  zaehler[event] = (zaehler[event] or 0) + 1
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    GruppeDiagDB = GruppeDiagDB or {}
    GruppeDiagDB.version = VERSION
    GruppeDiagDB.berichte = GruppeDiagDB.berichte or {}
  elseif event == "PLAYER_ENTERING_WORLD" and zaehler[event] == 1 then
    print("|cff33ff99GruppeDiag|r " .. VERSION .. " geladen. Bericht: /gruppediag  Hilfe: /gruppediag hilfe")
  elseif event == "NAME_PLATE_UNIT_ADDED" and not zaehler.erstePlakettenEinheit then
    zaehler.erstePlakettenEinheit = arg1
  elseif event == "PLAYER_REGEN_DISABLED" and not kampfprobe and C_Timer and C_Timer.After then
    C_Timer.After(2, function()
      if not UnitAffectingCombat("player") then return end
      kampfprobe = { zeit = date("%H:%M:%S"), player = lebenstest("player"),
        party1 = UnitExists("party1") and lebenstest("party1") or "keine party1",
        target = UnitExists("target") and lebenstest("target") or "kein Ziel" }
      GruppeDiagDB = GruppeDiagDB or {}
      GruppeDiagDB.kampfprobe = kampfprobe
      print("|cff33ff99GruppeDiag|r: Kampfprobe aufgezeichnet (steht im naechsten Bericht).")
    end)
  end
end)

-- Befehle --------------------------------------------------------------------

SLASH_GRUPPEDIAG1 = "/gruppediag"
SLASH_GRUPPEDIAG2 = "/gdiag"
SlashCmdList["GRUPPEDIAG"] = function(eingabe)
  eingabe = string.lower(strtrim(eingabe or ""))
  if eingabe == "fenster" then
    local b = GruppeDiagDB and GruppeDiagDB.berichte and GruppeDiagDB.berichte[#GruppeDiagDB.berichte]
    if b then zeigeFenster(b.text) else print("|cff33ff99GruppeDiag|r: Noch kein Bericht. Erst /gruppediag.") end
  elseif eingabe == "ton" then
    tontest()
  elseif eingabe == "loeschen" then
    GruppeDiagDB = { version = VERSION, berichte = {} }
    print("|cff33ff99GruppeDiag|r: Gespeicherte Berichte geloescht.")
  elseif eingabe == "hilfe" then
    print("|cff33ff99GruppeDiag|r Befehle:")
    print("  /gruppediag          Bericht erstellen und im Fenster zeigen")
    print("  /gruppediag fenster  letzten Bericht wieder zeigen")
    print("  /gruppediag ton      Tontest (Blizzard-Klang und eigene Datei)")
    print("  /gruppediag loeschen gespeicherte Berichte loeschen")
  else
    bericht()
  end
end
