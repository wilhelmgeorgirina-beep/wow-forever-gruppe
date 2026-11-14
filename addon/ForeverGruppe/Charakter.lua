-- Charakter.lua
-- Eigenes Charakterfenster im Holzrahmen mit Wolf (Georgs Wahl, Entwurf 7 Rahmen 1).
-- Im Ring: das Mana als breiter Ring ums Charakterbild. Auf dem Namensbrett:
-- nur der Vorname, dahinter das Leben als halb durchsichtige gruene Flaeche,
-- die von rechts nach links schwindet (Georgs Wunsch vom 11.11.2026).
-- Leben und Mana sind fuer Addons geheim. Jedes Ringstueck und jeder Streifen
-- der Lebensflaeche bekommt darum eine Stufenkurve von Blizzard (C_CurveUtil):
-- Das Spiel selbst entscheidet, ob ein Teil zu sehen ist. Das Addon sieht die
-- Werte nie.
-- Klick waehlt dich als Ziel, Rechtsklick oeffnet dein Menue (wie bei Blizzard).
-- Shift + Ziehen verschiebt das Fenster. Blizzards Fenster wird nur unsichtbar.

local ADDON_NAME, ns = ...
local BILDER = "Interface\\AddOns\\" .. ADDON_NAME .. "\\bilder\\"

-- Masse im Spiel (Bildpunkte bei 250 Breite), aus dem Rahmenbild vermessen
local BREITE, HOEHE = 250, 126.4
local MX, MY, LR = 55.4, 67.6, 31.8          -- Mitte und Radius des Lochs im Ring
local NAME_X, NAME_Y, NAME_B = 173, 69, 106  -- Namensbrett (Mitte, Breite)
-- Lebensflaeche auf dem Namensbrett: links, oben, Breite, Hoehe (aus charakterbilder.py).
-- Sie fuellt das Brett ringsum bis an den Holzrahmen; die Goldbeschlaege sind im Bild ausgespart.
local BRETT_X, BRETT_Y, BRETT_B, BRETT_H = 114.02, 45.66, 119.94, 41.71
local STUFE_X, STUFE_Y = 23.6, 108.5         -- Medaillon
local BILD = 1.62                             -- Durchmesser des Charakterbilds in Lochradien
local N_LEBEN, N_MANA = 40, 40                -- Streifen der Lebensflaeche, Stuecke des Mana-Rings
local BLASS = 0.15                            -- Deckkraft leerer Mana-Stuecke
local LEBEN_DECKKRAFT = 0.55                  -- Lebensflaeche: das Holz scheint durch

local fenster
local stuecke = { leben = {}, mana = {} }
local kurven = { leben = {}, mana = {} }
local kurvenOk = false
local zustand = "nicht gebaut"
local ausstehend = false                      -- im Kampf gebaut? dann nach dem Kampf fertigstellen
local stufeGemeldet                           -- neue Stufe aus PLAYER_LEVEL_UP (UnitLevel hinkt in dem Moment noch nach)

-- Kurven ---------------------------------------------------------------------

local function baueKurven()
  if not (C_CurveUtil and C_CurveUtil.CreateCurve) then return false, "C_CurveUtil fehlt" end
  return pcall(function()
    for art, n in pairs({ leben = N_LEBEN, mana = N_MANA }) do
      for k = 1, n do
        local c = C_CurveUtil.CreateCurve()
        if c.SetType and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step then
          c:SetType(Enum.LuaCurveType.Step)
        end
        local schwelle = (k - 0.5) / n        -- Teil k ist ab diesem Anteil zu sehen
        -- leere Mana-Stuecke bleiben blass sichtbar, leere Lebensstreifen zeigen das blanke Holz
        local leer = art == "leben" and 0 or BLASS
        local voll = art == "leben" and LEBEN_DECKKRAFT or 1
        c:AddPoint(0, leer)
        c:AddPoint(schwelle - 0.0001, leer)
        c:AddPoint(schwelle, voll)
        c:AddPoint(1, voll)
        kurven[art][k] = c
      end
    end
  end)
end

local function alleVoll(art)
  local a = art == "leben" and LEBEN_DECKKRAFT or 1
  for _, t in ipairs(stuecke[art]) do t:SetAlpha(a) end
end

local function fuelle(art)
  if not fenster then return end
  if not kurvenOk then alleVoll(art); return end
  local fehler
  for k, t in ipairs(stuecke[art]) do
    local ok, err = pcall(function()
      if art == "leben" then
        t:SetAlpha(UnitHealthPercent("player", true, kurven.leben[k]))
      else
        t:SetAlpha(UnitPowerPercent("player", UnitPowerType("player"), false, kurven.mana[k]))
      end
    end)
    if not ok then fehler = err; break end
  end
  if fehler then
    kurvenOk = false
    zustand = "Kurven abgelehnt: " .. tostring(fehler)
    ns.protokoll("FEHLER Fuellung von Leben oder Mana: " .. tostring(fehler))
    alleVoll("leben"); alleVoll("mana")
  end
end

local function manaFarbe()
  local ok, typ, token = pcall(UnitPowerType, "player")
  local f = ok and PowerBarColor and (PowerBarColor[token] or PowerBarColor[typ])
  if f and f.r then return f.r, f.g, f.b end
  return 0.24, 0.55, 1
end

local function faerbeMana()
  local r, g, b = manaFarbe()
  if r == 0 and g == 0 and b == 1 then r, g, b = 0.24, 0.55, 1 end   -- Blizzard-Blau etwas heller
  for _, t in ipairs(stuecke.mana) do t:SetVertexColor(r, g, b) end
end

-- Inhalt ---------------------------------------------------------------------

local function auffrischen()
  if not fenster then return end
  pcall(SetPortraitTexture, fenster.bild, "player")
  -- Forever liefert den Nachnamen als zweiten Wert ("Gosha", "Analphabet"); gezeigt wird nur der Vorname
  local vor = UnitName("player")
  fenster.name:SetText(vor or "")
  -- Beim Stufenaufstieg meldet das Spiel die neue Stufe im Ereignis, UnitLevel liefert
  -- dann noch die alte. Darum gilt die hoehere der beiden Zahlen.
  local stufe = UnitLevel("player")
  pcall(function()
    if stufeGemeldet and (not stufe or stufeGemeldet > stufe) then stufe = stufeGemeldet end
  end)
  fenster.stufe:SetText(tostring(stufe or ""))
  faerbeMana()
  fuelle("leben"); fuelle("mana")
end

-- Lage -----------------------------------------------------------------------

local function anker()
  local db = ns.db()
  local lage = db and db.charakter or { x = 0, y = 0 }
  fenster:ClearAllPoints()
  if PlayerFrame then
    fenster:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", lage.x, lage.y)
  else
    fenster:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
  end
end

local function blizzardVerbergen(verbergen)
  if not PlayerFrame then return end
  local ok, err = pcall(PlayerFrame.SetAlpha, PlayerFrame, verbergen and 0 or 1)
  if not ok then ns.protokoll("FEHLER Blizzard-Fenster: " .. tostring(err)) end
  if not InCombatLockdown() then
    local okM, errM = pcall(PlayerFrame.EnableMouse, PlayerFrame, not verbergen)   -- unsichtbar = nicht klickbar
    if not okM then ns.protokoll("Hinweis: Blizzard-Fenster bleibt klickbar: " .. tostring(errM)) end
  end
end

-- Bau ------------------------------------------------------------------------

local function manaRing()
  for k = 1, N_MANA do
    local t = fenster:CreateTexture(nil, "BORDER")
    t:SetTexture(BILDER .. "ring_mana")
    t:SetSize(LR * 2 * 1.06, LR * 2 * 1.06)
    t:SetPoint("CENTER", fenster, "TOPLEFT", MX, -MY)
    t:SetRotation(-(k - 1) * 2 * math.pi / N_MANA)   -- im Uhrzeigersinn ab oben
    stuecke.mana[k] = t
  end
end

-- Die Lebensflaeche liegt ueber dem Holz des Namensbretts und unter dem Namen.
-- Sie besteht aus schmalen senkrechten Streifen desselben Bildes; Streifen 1
-- ist ganz links und bleibt am laengsten, der rechte verschwindet zuerst.
local function lebensFlaeche()
  local schritt = BRETT_B / N_LEBEN
  for k = 1, N_LEBEN do
    local t = fenster:CreateTexture(nil, "OVERLAY")
    t:SetDrawLayer("OVERLAY", 2)
    t:SetTexture(BILDER .. "brett_leben")
    t:SetTexCoord((k - 1) / N_LEBEN, k / N_LEBEN, 0, 1)
    t:SetPoint("TOPLEFT", fenster, "TOPLEFT", BRETT_X + (k - 1) * schritt, -BRETT_Y)
    t:SetPoint("BOTTOMRIGHT", fenster, "TOPLEFT", BRETT_X + k * schritt, -(BRETT_Y + BRETT_H))
    t:SetVertexColor(0.28, 0.83, 0.35)
    -- nicht auf ganze Bildschirmpunkte runden, sonst gaebe es Fugen zwischen den Streifen
    pcall(function() t:SetSnapToPixelGrid(false); t:SetTexelSnappingBias(0) end)
    stuecke.leben[k] = t
  end
end

local function baue()
  fenster = CreateFrame("Button", "ForeverGruppeCharakter", UIParent, "SecureUnitButtonTemplate")
  fenster:SetSize(BREITE, HOEHE)
  fenster:SetFrameStrata("MEDIUM")
  fenster:SetFrameLevel(20)
  fenster:SetClampedToScreen(true)

  -- Klicks wie beim Blizzard-Fenster: links Ziel, rechts Menue
  fenster:SetAttribute("unit", "player")
  fenster:SetAttribute("*type1", "target")
  fenster:SetAttribute("*type2", "togglemenu")
  fenster:RegisterForClicks("AnyUp")

  local scheibe = fenster:CreateTexture(nil, "BACKGROUND")
  scheibe:SetTexture(BILDER .. "scheibe")
  scheibe:SetSize(LR * 2.08, LR * 2.08)
  scheibe:SetPoint("CENTER", fenster, "TOPLEFT", MX, -MY)

  manaRing()

  local bild = fenster:CreateTexture(nil, "ARTWORK")
  bild:SetSize(LR * BILD, LR * BILD)
  bild:SetPoint("CENTER", fenster, "TOPLEFT", MX, -MY)
  local okMaske = pcall(function()
    local maske = fenster:CreateMaskTexture()
    maske:SetTexture(BILDER .. "maske", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    maske:SetAllPoints(bild)
    bild:AddMaskTexture(maske)
  end)
  if not okMaske then ns.protokoll("Hinweis: runde Maske fuers Charakterbild nicht moeglich") end
  fenster.bild = bild

  local rahmen = fenster:CreateTexture(nil, "OVERLAY")
  rahmen:SetTexture(BILDER .. "charakter_rahmen")
  rahmen:SetTexCoord(0, 1013 / 1024, 0, 1)
  rahmen:SetAllPoints(fenster)

  lebensFlaeche()

  local name = fenster:CreateFontString(nil, "OVERLAY")
  name:SetDrawLayer("OVERLAY", 7)
  -- Klare Schrift, groesser und heller (Georg 14.11.2026: Namen schlecht lesbar)
  if not pcall(name.SetFont, name, "Fonts\\FRIZQT__.TTF", 16, "OUTLINE") then name:SetFontObject(GameFontNormalLarge) end
  name:SetTextColor(1, 0.93, 0.62)
  pcall(function() name:SetShadowColor(0, 0, 0, 1); name:SetShadowOffset(1.2, -1.2) end)
  name:SetWidth(NAME_B)
  name:SetWordWrap(false)
  name:SetPoint("CENTER", fenster, "TOPLEFT", NAME_X, -NAME_Y)
  fenster.name = name

  local stufe = fenster:CreateFontString(nil, "OVERLAY")
  stufe:SetDrawLayer("OVERLAY", 7)
  if not pcall(stufe.SetFont, stufe, "Fonts\\FRIZQT__.TTF", 13, "OUTLINE") then stufe:SetFontObject(GameFontHighlight) end
  stufe:SetPoint("CENTER", fenster, "TOPLEFT", STUFE_X, -STUFE_Y)
  fenster.stufe = stufe

  -- Shift + Ziehen verschiebt (nur ausserhalb des Kampfes moeglich)
  fenster:SetMovable(true)
  fenster:RegisterForDrag("LeftButton")
  fenster:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not InCombatLockdown() then self.zieht = true; self:StartMoving() end
  end)
  fenster:SetScript("OnDragStop", function(self)
    if not self.zieht then return end
    self.zieht = false
    self:StopMovingOrSizing()
    if self.SetUserPlaced then self:SetUserPlaced(false) end
    local db = ns.db()
    if db and PlayerFrame then
      local fs, ps = self:GetEffectiveScale(), PlayerFrame:GetEffectiveScale()
      db.charakter = { x = self:GetLeft() - PlayerFrame:GetLeft() * ps / fs, y = self:GetTop() - PlayerFrame:GetTop() * ps / fs }
      ns.protokoll(string.format("Charakterfenster verschoben: %.0f/%.0f", db.charakter.x, db.charakter.y))
    end
    anker()
  end)

  local ok, err = baueKurven()
  kurvenOk = ok and true or false
  zustand = kurvenOk and "Kurven bereit" or ("Kurven fehlen: " .. tostring(err))
  ns.protokoll("Charakterfenster: " .. zustand)

  anker()
  blizzardVerbergen(true)
  ns.charakterFenster = fenster
  if ns.knopfNeuAnkern then ns.knopfNeuAnkern() end
  auffrischen()
  -- Mitspieler-Fenster und Warnung (Gruppe.lua) haengen sich an dieses Fenster und
  -- bauen die Mitspieler in denselben Massen
  ns.charakterMasse = { breite = BREITE, hoehe = HOEHE, mx = MX, my = MY, lr = LR, bild = LR * BILD,
    nameX = NAME_X, nameY = NAME_Y, nameB = NAME_B, stufeX = STUFE_X, stufeY = STUFE_Y,
    brettX = BRETT_X, brettY = BRETT_Y, brettB = BRETT_B, brettH = BRETT_H }
  if ns.gruppeBauen then
    local okG, errG = pcall(ns.gruppeBauen, fenster, MX, MY, LR, LR * BILD)
    if not okG then
      ns.protokoll("FEHLER Gruppenfenster: " .. tostring(errG))
      print(ns.P .. "Mitspieler-Fenster konnten nicht gebaut werden: " .. tostring(errG))
    end
  end
end

-- Schnittstelle fuer Bericht und Befehle -------------------------------------

function ns.charakterLage()
  if not fenster then return zustand end
  local ok, text = pcall(function()
    return string.format("%s, links=%.0f oben=%.0f, Blizzard-Fenster Deckkraft=%s",
      zustand, fenster:GetLeft() or -1, fenster:GetTop() or -1, tostring(PlayerFrame and PlayerFrame:GetAlpha()))
  end)
  return ok and text or zustand
end

function ns.charakterZuruecksetzen()
  local db = ns.db()
  if db then db.charakter = nil end
  if fenster and not InCombatLockdown() then anker() end
end

-- Ereignisse -----------------------------------------------------------------

local E = CreateFrame("Frame")
E:RegisterEvent("PLAYER_LOGIN")
E:RegisterEvent("PLAYER_REGEN_ENABLED")
E:RegisterEvent("PLAYER_ENTERING_WORLD")
E:RegisterEvent("PLAYER_LEVEL_UP")
E:RegisterUnitEvent("UNIT_LEVEL", "player")
E:RegisterUnitEvent("UNIT_HEALTH", "player")
E:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
E:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
E:RegisterUnitEvent("UNIT_MAXPOWER", "player")
E:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
E:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
E:RegisterUnitEvent("UNIT_NAME_UPDATE", "player")

E:SetScript("OnEvent", function(self, event, arg1)
  if event == "PLAYER_LEVEL_UP" and type(arg1) == "number" then stufeGemeldet = arg1 end
  if event == "PLAYER_LOGIN" or (event == "PLAYER_REGEN_ENABLED" and ausstehend) then
    if fenster then return end
    if InCombatLockdown() then ausstehend = true; return end   -- sichere Knoepfe nur ausserhalb des Kampfes bauen
    ausstehend = false
    local ok, err = pcall(baue)
    if not ok then
      zustand = "FEHLER beim Bau: " .. tostring(err)
      ns.protokoll(zustand)
      print(ns.P .. "Charakterfenster konnte nicht gebaut werden, Blizzards Fenster bleibt: " .. tostring(err))
      blizzardVerbergen(false)
    end
  elseif not fenster then
    return
  elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
    fuelle("leben")
  elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
    fuelle("mana")
  else
    auffrischen()
  end
end)
