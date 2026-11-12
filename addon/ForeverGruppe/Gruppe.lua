-- Gruppe.lua
-- Die Mitspieler als Wolfsfenster unter dem eigenen (Georgs Wahl, Entwurf 16 B):
-- derselbe Holzrahmen wie beim eigenen Charakter, etwas kleiner und leicht nach
-- rechts versetzt, untereinander. Je Mitspieler: Bild, Mana-Ring, Vorname mit
-- dem Leben als gruene Flaeche dahinter, Stufe im Medaillon.
-- Die Goldbeschlaege am Wolfskopf schimmern in der Farbe der Rolle (auch am
-- eigenen Fenster). Der Gruppenfuehrer traegt oben links ein goldenes Medaillon.
-- Warnung: Unter einem Drittel Leben blinkt der Ring rot (auch der eigene).
-- Leben ist fuer Addons geheim. Wie im Charakterfenster entscheidet darum das Spiel
-- selbst ueber Stufenkurven, was zu sehen ist. Das Addon sieht die Werte nie.
-- Rollen kennt das Spiel nicht: Jeder waehlt seine Rolle selbst in der Legende
-- (Knopf "Rollen"), das Addon sagt sie den Addons der Mitspieler weiter.
-- Klick auf ein Fenster waehlt den Mitspieler als Ziel, Rechtsklick oeffnet sein Menue.
-- Blizzards eigene Gruppenfenster werden nur unsichtbar und nicht klickbar gemacht.
-- Alles nur Anzeige, keine Spielaktion.

local ADDON_NAME, ns = ...
local BILDER = "Interface\\AddOns\\" .. ADDON_NAME .. "\\bilder\\"
local PRAEFIX = "FGRUPPE"

local MAX = 6                                  -- Siebenergruppe: sechs Mitspieler
local MASSSTAB = 0.78                          -- Mitspieler-Fenster im Verhaeltnis zum eigenen
local START_X, START_Y = 26, 114               -- erstes Fenster, ab linker oberer Ecke des eigenen
local ABSTAND = 82                             -- von Fenster zu Fenster nach unten
local N = 40                                   -- Stuecke des Mana-Rings und Streifen der Lebensflaeche
local BLASS = 0.15
local LEBEN_DECKKRAFT = 0.55                   -- Lebensflaeche: das Holz scheint durch
-- Goldbeschlaege am Wolfskopf: Lage und Kante des Bildes wolf_beschlag (aus charakterbilder.py)
local WOLF_X, WOLF_Y, WOLF_KANTE = 74.04, 0, 63.18
local DRITTEL = 1 / 3

local ROLLEN = {
  { name = "Tank",      farbe = { 0.78, 0.22, 0.17 } },
  { name = "Heiler",    farbe = { 0.25, 0.75, 0.31 } },
  { name = "Nahkampf",  farbe = { 0.89, 0.71, 0.18 } },
  { name = "Fernkampf", farbe = { 0.24, 0.55, 1.00 } },
}
local GRAU = { 0.60, 0.60, 0.60 }
local GOLD = { 0.79, 0.64, 0.29 }
local FARBE_VON = {}
for _, r in ipairs(ROLLEN) do FARBE_VON[r.name] = r.farbe end

local haupt                                    -- das Wolfsfenster
local ringe = {}
local eigen = {}                               -- Warnung und Medaillon am eigenen Ring
local blinker = {}                             -- Rahmen, die gemeinsam blinken
local kurven = { leben = {}, mana = {} }
local kurvenOk = false
local manaOk = true                            -- Mana der Mitspieler ueber Kurven lesbar?
local manaFehler
local blizzardStand = {}                       -- was aus Blizzards Gruppenfenstern wurde (fuer den Bericht)
local zustand = "nicht gebaut"
local M                                        -- Masse des Charakterfensters (von Charakter.lua)
local ausstehend = false                       -- Verteilung nach dem Kampf nachholen
local rollenVon = {}                           -- Vorname -> Rolle (von den Addons der Mitspieler gemeldet)
local zaehler = { gesendet = 0, empfangen = 0, absender = "-" }
local rollenKnopf, legende
local zeilen = {}

local function geheim(v) return issecretvalue and issecretvalue(v) end

-- Kurven ---------------------------------------------------------------------

local function stufe(punkte)
  local c = C_CurveUtil.CreateCurve()
  if c.SetType and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then c:SetType(Enum.LuaCurveType.Step) end
  for _, p in ipairs(punkte) do c:AddPoint(p[1], p[2]) end
  return c
end

local function baueKurven()
  if not (C_CurveUtil and C_CurveUtil.CreateCurve) then return false, "C_CurveUtil fehlt" end
  return pcall(function()
    for k = 1, N do
      local s = (k - 0.5) / N
      kurven.mana[k] = stufe({ { 0, BLASS }, { s - 0.0001, BLASS }, { s, 1 }, { 1, 1 } })
      kurven.leben[k] = stufe({ { 0, 0 }, { s - 0.0001, 0 }, { s, LEBEN_DECKKRAFT }, { 1, LEBEN_DECKKRAFT } })
    end
    -- Warnung: an zwischen "fast nichts" und einem Drittel. Bei 0 (tot) aus.
    local function warn(a)
      return stufe({ { 0, 0 }, { 0.001, 0 }, { 0.002, a }, { DRITTEL, a }, { DRITTEL + 0.001, 0 }, { 1, 0 } })
    end
    kurven.leuchten = warn(1)
    kurven.schleier = warn(0.45)
  end)
end

-- Leben und Warnung ----------------------------------------------------------

local function ohneKurven(r)
  for _, t in ipairs(r.stuecke or {}) do t:SetAlpha(LEBEN_DECKKRAFT) end
  r.leuchten:SetAlpha(0); r.schleier:SetAlpha(0)
end

local function lebenZeigen(r, unit)
  if not unit then return end
  if not kurvenOk then ohneKurven(r); return end
  local ok, err = pcall(function()
    for k, t in ipairs(r.stuecke or {}) do t:SetAlpha(UnitHealthPercent(unit, true, kurven.leben[k])) end
    r.leuchten:SetAlpha(UnitHealthPercent(unit, true, kurven.leuchten))
    r.schleier:SetAlpha(UnitHealthPercent(unit, true, kurven.schleier))
  end)
  if not ok then
    kurvenOk = false
    zustand = "Kurven abgelehnt: " .. tostring(err)
    ns.protokoll("FEHLER Gruppenfenster: " .. tostring(err))
    for _, x in ipairs(ringe) do ohneKurven(x) end
    if eigen.leuchten then ohneKurven(eigen) end
  end
end

-- Mana (oder Wut, Energie) der Mitspieler: gleiche Stufenkurven wie beim Leben
local function manaZeigen(r, unit)
  if not unit or not r.manaStuecke then return end
  if not (kurvenOk and manaOk) then
    for _, t in ipairs(r.manaStuecke) do t:SetAlpha(manaOk and 1 or 0) end
    return
  end
  local ok, err = pcall(function()
    local typ = UnitPowerType(unit)
    for k, t in ipairs(r.manaStuecke) do t:SetAlpha(UnitPowerPercent(unit, typ, false, kurven.mana[k])) end
  end)
  if not ok then
    manaOk = false
    manaFehler = tostring(err)
    ns.protokoll("FEHLER Mana der Mitspieler: " .. manaFehler)
    for _, x in ipairs(ringe) do
      for _, t in ipairs(x.manaStuecke or {}) do t:SetAlpha(0) end
    end
  end
end

local function manaFaerben(r, unit)
  if not r.manaStuecke then return end
  local rot, gruen, blau = 0.24, 0.55, 1
  pcall(function()
    local typ, token = UnitPowerType(unit)
    local f = PowerBarColor and (PowerBarColor[token] or PowerBarColor[typ])
    if f and f.r and not (f.r == 0 and f.g == 0 and f.b == 1) then rot, gruen, blau = f.r, f.g, f.b end
  end)
  for _, t in ipairs(r.manaStuecke) do t:SetVertexColor(rot, gruen, blau) end
end

-- Blizzards Gruppenfenster ------------------------------------------------------

-- Wie beim Charakterfenster: nichts wird entfernt, nur unsichtbar und (ausserhalb
-- des Kampfes) nicht klickbar gemacht, damit unter den Wolfsfenstern nichts stoert.
local BLIZZARD_FENSTER = { "PartyFrame", "CompactPartyFrame", "CompactRaidFrameContainer" }

local function mausAus(f, tiefe)
  pcall(f.EnableMouse, f, false)
  if tiefe <= 0 then return end
  local ok, kinder = pcall(function() return { f:GetChildren() } end)
  if not ok then return end
  for _, k in ipairs(kinder) do mausAus(k, tiefe - 1) end
end

local function blizzardGruppeVerbergen()
  for _, name in ipairs(BLIZZARD_FENSTER) do
    local f = _G[name]
    if f then
      local ok = pcall(f.SetAlpha, f, 0)
      blizzardStand[name] = ok and "unsichtbar" or "nicht aenderbar"
      if ok and not InCombatLockdown() then mausAus(f, 3) end
    else
      blizzardStand[name] = "fehlt"
    end
  end
end

-- Tot, Geist oder nicht verbunden: keine Warnung
local function warnungErlaubt(r, unit)
  local ok, aus = pcall(function()
    if UnitIsDeadOrGhost(unit) then return true end
    if UnitIsConnected and not UnitIsConnected(unit) then return true end
    return false
  end)
  local zeigen = not (ok and aus)
  r.warnRahmen:SetShown(zeigen); r.schleierRahmen:SetShown(zeigen)
end

-- Rollen ---------------------------------------------------------------------

local function rolleVon(unit)
  local ok, rolle = pcall(function()
    local vor, nach = UnitName(unit)
    if not vor or geheim(vor) then return nil end
    return rollenVon[vor] or (nach and not geheim(nach) and rollenVon[vor .. " " .. nach]) or nil
  end)
  return ok and rolle or nil
end

local sendenGeplant = false
local function sende()
  local db = ns.db()
  if not db or not IsInGroup() then return end
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
  local ok = pcall(C_ChatInfo.SendAddonMessage, PRAEFIX, "R:" .. (db.rolle or "-"), IsInRaid() and "RAID" or "PARTY")
  if ok then zaehler.gesendet = zaehler.gesendet + 1 end
end

local function sendeBald()
  if sendenGeplant then return end
  sendenGeplant = true
  C_Timer.After(2, function() sendenGeplant = false; sende() end)
end

-- Inhalt eines Fensters ------------------------------------------------------

-- Beschlaege am Wolfskopf in der Rollenfarbe; ohne Rolle bleibt das Gold des Rahmens
local function wolfFaerben(wolf, rolle)
  local f = FARBE_VON[rolle or ""]
  for _, t in ipairs(wolf or {}) do
    if f then t:SetVertexColor(f[1], f[2], f[3]) end
    t:SetShown(f ~= nil)
  end
end

local function ringAuffrischen(r)
  local unit = r.unit
  if not unit or not UnitExists(unit) then return end
  pcall(SetPortraitTexture, r.bild, unit)
  local ok, name = pcall(UnitName, unit)
  if ok and name then pcall(r.name.SetText, r.name, name) end
  -- die Stufe kann geheim sein: dann reicht das Spiel sie selbst an die Schrift durch
  if not pcall(function() r.stufe:SetText(UnitLevel(unit)) end) then r.stufe:SetText("") end
  wolfFaerben(r.wolf, rolleVon(unit))
  local okF, fuehrt = pcall(function() return UnitIsGroupLeader(unit) and true or false end)
  r.medaillon:SetShown(okF and fuehrt)
  warnungErlaubt(r, unit)
  lebenZeigen(r, unit)
  manaFaerben(r, unit)
  manaZeigen(r, unit)
end

local function eigenAuffrischen()
  if not eigen.leuchten then return end
  local ok, fuehrt = pcall(function() return (IsInGroup() and UnitIsGroupLeader("player")) and true or false end)
  eigen.medaillon:SetShown(ok and fuehrt)
  local db = ns.db()
  wolfFaerben(eigen.wolf, db and db.rolle)
  warnungErlaubt(eigen, "player")
  lebenZeigen(eigen, "player")
end

local function legendeAuffrischen()
  if not rollenKnopf then return end
  local inGruppe = IsInGroup() and true or false
  rollenKnopf:SetShown(inGruppe)
  if not inGruppe then legende:Hide() end
  local db = ns.db()
  for _, z in ipairs(zeilen) do
    z.marke:SetShown(db ~= nil and db.rolle == z.rolle)
  end
end

local function allesAuffrischen()
  for _, r in ipairs(ringe) do ringAuffrischen(r) end
  eigenAuffrischen()
  legendeAuffrischen()
end

-- Mitspieler auf die Ringe verteilen (nur ausserhalb des Kampfes moeglich) -----

local function mitspieler()
  local liste = {}
  if IsInRaid() then
    for i = 1, (GetNumGroupMembers() or 0) do
      local unit = "raid" .. i
      local ok, ich = pcall(function() return UnitIsUnit(unit, "player") and true or false end)
      if not (ok and ich) and #liste < MAX then liste[#liste + 1] = unit end
    end
  elseif IsInGroup() then
    for i = 1, 4 do liste[i] = "party" .. i end
  end
  return liste
end

local EREIGNISSE = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_PORTRAIT_UPDATE", "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_LEVEL",
  "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }

local function verteile()
  if not haupt then return end
  if InCombatLockdown() then ausstehend = true; blizzardGruppeVerbergen(); allesAuffrischen(); return end
  ausstehend = false
  blizzardGruppeVerbergen()                    -- neue Mitspieler bringen neue Blizzard-Fenster mit
  local liste = mitspieler()
  for i, r in ipairs(ringe) do
    local unit = liste[i]
    if r.unit ~= unit then
      UnregisterUnitWatch(r.knopf)
      r.knopf:SetAttribute("unit", unit)
      r.unit = unit
      r.lauscher:UnregisterAllEvents()
      if unit then
        RegisterUnitWatch(r.knopf)             -- das Spiel blendet das Fenster ein, sobald es den Mitspieler gibt
        for _, e in ipairs(EREIGNISSE) do pcall(r.lauscher.RegisterUnitEvent, r.lauscher, e, unit) end
      else
        r.knopf:Hide()
      end
    end
  end
  allesAuffrischen()
end

-- Bau ------------------------------------------------------------------------

local function warnTeile(r, eltern, ebene, mx, my, lr, leuchtGroesse)
  -- rotes Leuchten hinter dem Ring
  r.warnRahmen = CreateFrame("Frame", nil, eltern)
  r.warnRahmen:SetAllPoints(eltern)
  r.warnRahmen:SetFrameLevel(ebene)
  r.leuchten = r.warnRahmen:CreateTexture(nil, "BACKGROUND")
  r.leuchten:SetTexture(BILDER .. "glut")
  r.leuchten:SetVertexColor(1, 0.08, 0.04)
  r.leuchten:SetSize(leuchtGroesse, leuchtGroesse)
  r.leuchten:SetPoint("CENTER", eltern, "TOPLEFT", mx, -my)
  r.leuchten:SetAlpha(0)
  blinker[#blinker + 1] = r.warnRahmen
end

local function schleierTeile(r, eltern, ebene, mx, my, lr, groesse)
  -- roter Schleier ueber dem Bild
  r.schleierRahmen = CreateFrame("Frame", nil, eltern)
  r.schleierRahmen:SetAllPoints(eltern)
  r.schleierRahmen:SetFrameLevel(ebene)
  r.schleier = r.schleierRahmen:CreateTexture(nil, "ARTWORK")
  r.schleier:SetTexture(BILDER .. "maske")
  r.schleier:SetVertexColor(1, 0.05, 0.03)
  r.schleier:SetSize(groesse or lr * 1.44, groesse or lr * 1.44)
  r.schleier:SetPoint("CENTER", eltern, "TOPLEFT", mx, -my)
  r.schleier:SetAlpha(0)
  blinker[#blinker + 1] = r.schleierRahmen
end

local function medaillonTeil(rahmen, bezug, mx, my, lr, abstand, radius)
  local m = rahmen:CreateTexture(nil, "OVERLAY")
  m:SetDrawLayer("OVERLAY", 7)
  m:SetTexture(BILDER .. "medaillon")
  m:SetSize(lr * radius * 3, lr * radius * 3)   -- das Bild hat ringsum Luft fuer den Schatten
  local weg = lr * abstand * 0.7071             -- schraeg nach oben links
  m:SetPoint("CENTER", bezug, "TOPLEFT", mx - weg, -(my - weg))
  m:Hide()
  return m
end

-- Zwei Lagen desselben Bildes: eine deckend in der Rollenfarbe, eine leuchtend darueber
local function wolfTeil(rahmen, bezug)
  local wolf = {}
  for i, modus in ipairs({ "BLEND", "ADD" }) do
    local t = rahmen:CreateTexture(nil, "ARTWORK")
    t:SetDrawLayer("ARTWORK", i)
    t:SetTexture(BILDER .. "wolf_beschlag")
    t:SetSize(WOLF_KANTE, WOLF_KANTE)
    t:SetPoint("TOPLEFT", bezug, "TOPLEFT", WOLF_X, -WOLF_Y)
    pcall(t.SetBlendMode, t, modus)
    t:SetAlpha(i == 1 and 0.92 or 0.35)
    t:Hide()
    wolf[i] = t
  end
  return wolf
end

-- Ein Mitspieler-Fenster: gebaut in den Massen des eigenen Fensters und als Ganzes
-- verkleinert (SetScale). Alle Lagen darin benutzen darum dieselben Zahlen wie Charakter.lua.
local function baueRing(i, ebene)
  local r = { stuecke = {}, manaStuecke = {} }
  local MX, MY, LR = M.mx, M.my, M.lr
  local b = CreateFrame("Button", "ForeverGruppeRing" .. i, haupt, "SecureUnitButtonTemplate")
  b:SetSize(M.breite, M.hoehe)
  b:SetScale(MASSSTAB)
  b:SetPoint("TOPLEFT", haupt, "TOPLEFT", START_X / MASSSTAB, -(START_Y + (i - 1) * ABSTAND) / MASSSTAB)
  b:SetFrameLevel(ebene)
  pcall(b.SetHitRectInsets, b, 4, 4, 18, 4)    -- die Fenster ueberlappen sich: oben nicht klickbar
  b:SetAttribute("*type1", "target")
  b:SetAttribute("*type2", "togglemenu")
  b:RegisterForClicks("AnyUp")
  b:Hide()
  r.knopf = b

  warnTeile(r, b, ebene + 1, MX, MY, LR, LR * 4.6)

  local inhalt = CreateFrame("Frame", nil, b)
  inhalt:SetAllPoints(b)
  inhalt:SetFrameLevel(ebene + 2)
  local scheibe = inhalt:CreateTexture(nil, "BACKGROUND")
  scheibe:SetTexture(BILDER .. "scheibe")
  scheibe:SetSize(LR * 2.08, LR * 2.08)
  scheibe:SetPoint("CENTER", b, "TOPLEFT", MX, -MY)
  for k = 1, N do
    local t = inhalt:CreateTexture(nil, "BORDER")
    t:SetTexture(BILDER .. "ring_mana")
    t:SetSize(LR * 2 * 1.06, LR * 2 * 1.06)
    t:SetPoint("CENTER", b, "TOPLEFT", MX, -MY)
    t:SetRotation(-(k - 1) * 2 * math.pi / N)
    t:SetVertexColor(0.24, 0.55, 1)
    r.manaStuecke[k] = t
  end
  r.bild = inhalt:CreateTexture(nil, "ARTWORK")
  r.bild:SetSize(M.bild, M.bild)
  r.bild:SetPoint("CENTER", b, "TOPLEFT", MX, -MY)
  pcall(function()
    local maske = inhalt:CreateMaskTexture()
    maske:SetTexture(BILDER .. "maske", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    maske:SetAllPoints(r.bild)
    r.bild:AddMaskTexture(maske)
  end)

  schleierTeile(r, b, ebene + 3, MX, MY, LR, M.bild)

  local deckel = CreateFrame("Frame", nil, b)
  deckel:SetAllPoints(b)
  deckel:SetFrameLevel(ebene + 4)
  local holz = deckel:CreateTexture(nil, "ARTWORK")
  holz:SetTexture(BILDER .. "charakter_rahmen")
  holz:SetTexCoord(0, 1013 / 1024, 0, 1)
  holz:SetAllPoints(b)
  r.wolf = wolfTeil(deckel, b)

  -- Leben: Streifen auf dem Namensbrett, der rechte verschwindet zuerst (wie im eigenen Fenster)
  local schritt = M.brettB / N
  for k = 1, N do
    local t = deckel:CreateTexture(nil, "OVERLAY")
    t:SetDrawLayer("OVERLAY", 2)
    t:SetTexture(BILDER .. "brett_leben")
    t:SetTexCoord((k - 1) / N, k / N, 0, 1)
    t:SetPoint("TOPLEFT", b, "TOPLEFT", M.brettX + (k - 1) * schritt, -M.brettY)
    t:SetPoint("BOTTOMRIGHT", b, "TOPLEFT", M.brettX + k * schritt, -(M.brettY + M.brettH))
    t:SetVertexColor(0.28, 0.83, 0.35)
    pcall(function() t:SetSnapToPixelGrid(false); t:SetTexelSnappingBias(0) end)
    r.stuecke[k] = t
  end

  r.name = deckel:CreateFontString(nil, "OVERLAY")
  r.name:SetDrawLayer("OVERLAY", 7)
  if not pcall(r.name.SetFont, r.name, "Fonts\\MORPHEUS.TTF", 12.5, "OUTLINE") then r.name:SetFontObject(GameFontNormal) end
  r.name:SetTextColor(1, 0.85, 0.45)
  r.name:SetWidth(M.nameB)
  r.name:SetWordWrap(false)
  r.name:SetPoint("CENTER", b, "TOPLEFT", M.nameX, -M.nameY)

  r.stufe = deckel:CreateFontString(nil, "OVERLAY")
  r.stufe:SetDrawLayer("OVERLAY", 7)
  if not pcall(r.stufe.SetFont, r.stufe, "Fonts\\FRIZQT__.TTF", 13, "OUTLINE") then r.stufe:SetFontObject(GameFontHighlight) end
  r.stufe:SetPoint("CENTER", b, "TOPLEFT", M.stufeX, -M.stufeY)

  r.medaillon = medaillonTeil(deckel, b, MX, MY, LR, 1.1, 0.24)

  -- Lauscher fuer Leben, Bild und Namen dieses Mitspielers
  r.lauscher = inhalt
  inhalt:SetScript("OnEvent", function(_, event)
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      warnungErlaubt(r, r.unit); lebenZeigen(r, r.unit)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
      manaZeigen(r, r.unit)
    else
      ringAuffrischen(r)
    end
  end)
  b:HookScript("OnShow", function() ringAuffrischen(r) end)
  b:HookScript("OnEnter", function(self)
    if not r.unit then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    pcall(GameTooltip.SetUnit, GameTooltip, r.unit)
    GameTooltip:AddLine("Rolle: " .. (rolleVon(r.unit) or "keine gemeldet"), GOLD[1], GOLD[2], GOLD[3])
    GameTooltip:Show()
  end)
  b:HookScript("OnLeave", function() GameTooltip:Hide() end)
  return r
end

-- Legende ("Rollen") -----------------------------------------------------------

local function umrande(f, rgb)
  for _, seite in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local t = f:CreateTexture(nil, "BORDER")
    t:SetColorTexture(rgb[1], rgb[2], rgb[3], 1)
    if seite == "TOP" or seite == "BOTTOM" then
      t:SetPoint(seite .. "LEFT"); t:SetPoint(seite .. "RIGHT"); t:SetHeight(1)
    else
      t:SetPoint("TOP" .. seite); t:SetPoint("BOTTOM" .. seite); t:SetWidth(1)
    end
  end
end

local function text(f, gross)
  local fs = f:CreateFontString(nil, "OVERLAY")
  if not pcall(fs.SetFontObject, fs, gross and GameFontNormalSmall or GameFontHighlightSmall) then fs:SetFontObject(ChatFontNormal) end
  return fs
end

local function waehleRolle(rolle)
  local db = ns.db()
  if not db then return end
  db.rolle = rolle
  ns.protokoll("Eigene Rolle: " .. (rolle or "keine"))
  sende()
  legendeAuffrischen()
  wolfFaerben(eigen.wolf, rolle)
end

local function baueLegende()
  rollenKnopf = CreateFrame("Button", "ForeverGruppeRollenKnopf", UIParent)
  rollenKnopf:SetSize(54, 18)
  rollenKnopf:SetFrameStrata("MEDIUM")
  rollenKnopf:SetPoint("TOPLEFT", haupt, "TOPLEFT", 232, -122)
  local hg = rollenKnopf:CreateTexture(nil, "BACKGROUND")
  hg:SetAllPoints(); hg:SetColorTexture(0.17, 0.11, 0.07, 0.95)
  umrande(rollenKnopf, GOLD)
  local hell = rollenKnopf:CreateTexture(nil, "HIGHLIGHT")
  hell:SetAllPoints(); hell:SetColorTexture(1, 1, 1, 0.12)
  local t = text(rollenKnopf, true)
  t:SetPoint("CENTER"); t:SetText("Rollen")

  legende = CreateFrame("Frame", "ForeverGruppeLegende", UIParent)
  legende:SetFrameStrata("MEDIUM")
  legende:SetSize(124, 12 + 5 * 17)
  legende:SetPoint("TOPLEFT", rollenKnopf, "BOTTOMLEFT", 0, -3)
  legende:EnableMouse(true)
  local lhg = legende:CreateTexture(nil, "BACKGROUND")
  lhg:SetAllPoints(); lhg:SetColorTexture(0.11, 0.07, 0.05, 0.93)
  umrande(legende, GOLD)
  legende:Hide()

  local liste = {}
  for _, r in ipairs(ROLLEN) do liste[#liste + 1] = { rolle = r.name, text = r.name, farbe = r.farbe } end
  liste[#liste + 1] = { rolle = nil, text = "keine Rolle", farbe = GRAU }
  for i, e in ipairs(liste) do
    local z = CreateFrame("Button", nil, legende)
    z:SetSize(116, 16)
    z:SetPoint("TOPLEFT", 4, -6 - (i - 1) * 17)
    z.rolle = e.rolle
    local feld = z:CreateTexture(nil, "ARTWORK")
    feld:SetSize(14, 10); feld:SetPoint("LEFT", 4, 0)
    feld:SetColorTexture(e.farbe[1], e.farbe[2], e.farbe[3], 1)
    local name = text(z, false)
    name:SetPoint("LEFT", 25, 0); name:SetText(e.text)
    z.marke = text(z, false)
    z.marke:SetPoint("RIGHT", -3, 0); z.marke:SetText("du"); z.marke:SetTextColor(1, 0.85, 0.45)
    z.marke:Hide()
    local zh = z:CreateTexture(nil, "HIGHLIGHT")
    zh:SetAllPoints(); zh:SetColorTexture(1, 1, 1, 0.12)
    z:SetScript("OnClick", function() waehleRolle(e.rolle) end)
    z:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Klick: Das ist meine Rolle")
      GameTooltip:Show()
    end)
    z:SetScript("OnLeave", function() GameTooltip:Hide() end)
    zeilen[#zeilen + 1] = z
  end

  rollenKnopf:SetScript("OnClick", function()
    if legende:IsShown() then legende:Hide() else legendeAuffrischen(); legende:Show() end
  end)
  rollenKnopf:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Rollen")
    GameTooltip:AddLine("Klick: Farben der Wolfskoepfe erklaeren", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("In der Liste waehlst du deine eigene Rolle.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  rollenKnopf:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rollenKnopf:Hide()
end

-- Schnittstelle --------------------------------------------------------------

local E = CreateFrame("Frame")

-- Wird vom Charakterfenster gerufen, sobald es steht (immer ausserhalb des Kampfes)
function ns.gruppeBauen(fenster, mx, my, lr, bildGroesse)
  if haupt then return end
  M = ns.charakterMasse
  if not M then error("Masse des Charakterfensters fehlen") end
  haupt = fenster
  local ok, err = baueKurven()
  kurvenOk = ok and true or false
  zustand = kurvenOk and "Kurven bereit" or ("Kurven fehlen: " .. tostring(err))

  local ebene = fenster:GetFrameLevel() + 1
  for i = 1, MAX do ringe[i] = baueRing(i, ebene + (i - 1) * 6) end   -- untere Fenster liegen ueber den oberen

  -- Warnung und Medaillon am eigenen grossen Ring
  warnTeile(eigen, fenster, math.max(0, fenster:GetFrameLevel() - 1), mx, my, lr, lr * 4.6)
  schleierTeile(eigen, fenster, fenster:GetFrameLevel() + 1, mx, my, lr, bildGroesse)
  local schild = CreateFrame("Frame", nil, fenster)   -- eigener Rahmen, damit das Medaillon nicht mitblinkt
  schild:SetAllPoints(fenster)
  schild:SetFrameLevel(fenster:GetFrameLevel() + 2)
  eigen.medaillon = medaillonTeil(schild, fenster, mx, my, lr, 1.1, 0.24)
  eigen.wolf = wolfTeil(schild, fenster)

  baueLegende()

  -- gemeinsames Blinken: Das Spiel bestimmt, ob etwas leuchtet, das Addon nur den Takt
  local zeit = 0
  E:SetScript("OnUpdate", function(_, dt)
    zeit = zeit + dt
    local a = 0.3 + 0.7 * math.abs(math.sin(zeit * 3.5))
    for _, f in ipairs(blinker) do f:SetAlpha(a) end
  end)

  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PRAEFIX) end
  E:RegisterEvent("GROUP_ROSTER_UPDATE")
  E:RegisterEvent("PARTY_LEADER_CHANGED")
  E:RegisterEvent("PLAYER_ENTERING_WORLD")
  E:RegisterEvent("PLAYER_REGEN_ENABLED")
  E:RegisterEvent("CHAT_MSG_ADDON")
  E:RegisterEvent("PLAYER_DEAD")
  E:RegisterEvent("PLAYER_ALIVE")
  E:RegisterEvent("PLAYER_UNGHOST")
  E:RegisterUnitEvent("UNIT_HEALTH", "player")
  E:RegisterUnitEvent("UNIT_MAXHEALTH", "player")

  ns.protokoll("Gruppenfenster: " .. zustand)
  verteile()
  sendeBald()
end

function ns.gruppeLage()
  if not haupt then return zustand end
  local ok, t = pcall(function()
    local db = ns.db()
    local z = { string.format("%s, eigene Rolle=%s, Rollen gesendet=%d empfangen=%d (zuletzt von %s)",
      zustand, tostring(db and db.rolle or "keine"), zaehler.gesendet, zaehler.empfangen, zaehler.absender) }
    z[#z + 1] = "  Mana der Mitspieler: " .. (manaOk and "ueber Kurven" or ("abgelehnt: " .. tostring(manaFehler)))
    local bl = {}
    for _, name in ipairs(BLIZZARD_FENSTER) do bl[#bl + 1] = name .. "=" .. tostring(blizzardStand[name] or "?") end
    z[#z + 1] = "  Blizzard-Gruppenfenster: " .. table.concat(bl, ", ")
    for i, r in ipairs(ringe) do
      if r.unit and UnitExists(r.unit) then
        local name = UnitName(r.unit)
        z[#z + 1] = string.format("  Ring %d: %s %s Rolle=%s sichtbar=%s", i, r.unit,
          geheim(name) and "(Name geheim)" or tostring(name), tostring(rolleVon(r.unit) or "-"), tostring(r.knopf:IsVisible()))
      end
    end
    return table.concat(z, "\n")
  end)
  return ok and t or (zustand .. " (Bericht nicht moeglich: " .. tostring(t) .. ")")
end

E:SetScript("OnEvent", function(_, event, a1, a2, _, a4)
  if not haupt then return end
  if event == "CHAT_MSG_ADDON" then
    if a1 ~= PRAEFIX then return end
    pcall(function()
      local rolle = a2:match("^R:(.+)$")
      local wer = a4 and a4:match("^[^-]+")
      if not rolle or not wer then return end
      zaehler.empfangen = zaehler.empfangen + 1
      zaehler.absender = a4
      rollenVon[wer] = FARBE_VON[rolle] and rolle or nil
      for _, r in ipairs(ringe) do ringAuffrischen(r) end
    end)
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    lebenZeigen(eigen, "player")
  elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    eigenAuffrischen()
  elseif event == "PLAYER_REGEN_ENABLED" then
    if ausstehend then verteile() end
  elseif event == "PARTY_LEADER_CHANGED" then
    allesAuffrischen()
  else                                         -- GROUP_ROSTER_UPDATE, PLAYER_ENTERING_WORLD
    verteile()
    sendeBald()
  end
end)
