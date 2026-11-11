-- Schalter.lua
-- Der Auge-Knopf rechts neben dem Charakterfenster (Georgs Wahl, Entwurf 5 C).
-- Ein Klick klappt eine kleine Leiste auf: Spieler und NPCs je an / nah / aus.
-- Noch ein Klick (oder Esc) klappt sie zu. Shift + Ziehen verschiebt den Knopf.

local ADDON_NAME, ns = ...
local BILDER = "Interface\\AddOns\\" .. ADDON_NAME .. "\\bilder\\"
local STANDARD_LAGE = { x = 18, y = 8 }      -- Mitte des Knopfs, ab rechter Kante des Charakterfensters

local FARBE = {
  an  = { 0.18, 0.48, 0.21 },
  nah = { 0.54, 0.43, 0.08 },
  aus = { 0.54, 0.13, 0.13 },
  leer = { 0.13, 0.11, 0.09 },
  gold = { 0.79, 0.64, 0.29 },
  rand = { 0.42, 0.35, 0.19 },
}
local ZEILEN = { { schluessel = "namen", text = "Spieler" }, { schluessel = "npc", text = "NPCs" } }
local STUFEN = { "an", "nah", "aus" }

local knopf, leiste
local segmente = {}          -- segmente[schluessel][stufe] = Button

local function farbe(tex, f, a) tex:SetColorTexture(f[1], f[2], f[3], a or 1) end

local function schrift(fs, gross)
  local ok = pcall(fs.SetFontObject, fs, gross and GameFontNormal or GameFontHighlightSmall)
  if not ok then fs:SetFontObject(ChatFontNormal) end
end

-- Rahmen aus vier duennen Linien um eine Flaeche
local function umrande(f, rgb, dicke)
  for _, seite in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local t = f:CreateTexture(nil, "BORDER")
    farbe(t, rgb)
    if seite == "TOP" or seite == "BOTTOM" then
      t:SetPoint(seite .. "LEFT"); t:SetPoint(seite .. "RIGHT"); t:SetHeight(dicke)
    else
      t:SetPoint("TOP" .. seite); t:SetPoint("BOTTOM" .. seite); t:SetWidth(dicke)
    end
  end
end

-- Anzeige der Leiste an die Einstellungen anpassen
local function auffrischen()
  local db = ns.db()
  if not db then return end
  for _, z in ipairs(ZEILEN) do
    for _, stufe in ipairs(STUFEN) do
      local s = segmente[z.schluessel][stufe]
      local aktiv = db[z.schluessel] == stufe
      farbe(s.flaeche, aktiv and FARBE[stufe] or FARBE.leer)
      s.text:SetTextColor(aktiv and 1 or 0.72, aktiv and 1 or 0.72, aktiv and 1 or 0.72)
    end
  end
end

local function tooltipZeigen(self)
  local db = ns.db()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:AddLine("Namen ein- und ausblenden")
  if db then
    GameTooltip:AddLine("Fremde Spieler: " .. db.namen .. ",  NPCs: " .. db.npc, 1, 1, 1)
  end
  GameTooltip:AddLine("Klick: Schalter auf- und zuklappen", 0.7, 0.7, 0.7)
  GameTooltip:AddLine("Shift + Ziehen: Knopf verschieben", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

local function baueLeiste()
  leiste = CreateFrame("Frame", "ForeverGruppeSchalterLeiste", UIParent)
  leiste:SetFrameStrata("MEDIUM")
  leiste:SetSize(150, 50)
  leiste:SetPoint("LEFT", knopf, "RIGHT", 6, 0)
  local hg = leiste:CreateTexture(nil, "BACKGROUND")
  hg:SetAllPoints()
  hg:SetColorTexture(0.05, 0.04, 0.04, 0.9)
  umrande(leiste, FARBE.gold, 1)
  leiste:EnableMouse(true)
  leiste:Hide()
  table.insert(UISpecialFrames, "ForeverGruppeSchalterLeiste")   -- Esc klappt zu

  for zi, z in ipairs(ZEILEN) do
    local y = -6 - (zi - 1) * 20
    local name = leiste:CreateFontString(nil, "OVERLAY")
    schrift(name, false)
    name:SetTextColor(1, 0.82, 0)
    name:SetPoint("TOPLEFT", 8, y - 3)
    name:SetText(z.text)
    segmente[z.schluessel] = {}
    for si, stufe in ipairs(STUFEN) do
      local s = CreateFrame("Button", nil, leiste)
      s:SetSize(28, 16)
      s:SetPoint("TOPLEFT", 54 + (si - 1) * 29, y)
      s.flaeche = s:CreateTexture(nil, "BACKGROUND")
      s.flaeche:SetAllPoints()
      umrande(s, FARBE.rand, 1)
      s.text = s:CreateFontString(nil, "OVERLAY")
      schrift(s.text, false)
      s.text:SetPoint("CENTER", 0, 0)
      s.text:SetText(stufe)
      local hell = s:CreateTexture(nil, "HIGHLIGHT")
      hell:SetAllPoints()
      hell:SetColorTexture(1, 1, 1, 0.15)
      s:SetScript("OnClick", function()
        local kampf = ns.setzeModus(z.schluessel, stufe)
        if kampf then
          print(ns.P .. (z.schluessel == "npc" and "NPCs: " or "Fremde Spieler: ") .. stufe .. " (Einstellungen folgen nach dem Kampf)")
        end
      end)
      segmente[z.schluessel][stufe] = s
    end
  end
  leiste:SetScript("OnShow", auffrischen)
end

-- Lage des Knopfs relativ zum Charakterfenster
local function anker()
  local db = ns.db()
  local lage = (db and db.knopf) or STANDARD_LAGE
  knopf:ClearAllPoints()
  if PlayerFrame then
    knopf:SetPoint("CENTER", PlayerFrame, "RIGHT", lage.x, lage.y)
  else
    knopf:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 280, -40)
  end
end

function ns.knopfZuruecksetzen()
  local db = ns.db()
  if db then db.knopf = nil end
  if knopf then anker() end
end

function ns.knopfLage()
  if not knopf then return "nicht gebaut" end
  local ok, text = pcall(function()
    local x, y = knopf:GetCenter()
    local db = ns.db()
    local l = (db and db.knopf) or STANDARD_LAGE
    return string.format("Mitte %.0f/%.0f, Versatz %.0f/%.0f, sichtbar=%s, Charakterfenster rechts=%s",
      x or -1, y or -1, l.x, l.y, tostring(knopf:IsVisible()), tostring(PlayerFrame and PlayerFrame:GetRight()))
  end)
  return ok and text or ("FEHLER " .. tostring(text))
end

local function baueKnopf()
  knopf = CreateFrame("Button", "ForeverGruppeAugeKnopf", UIParent)
  knopf:SetSize(28, 28)
  knopf:SetFrameStrata("MEDIUM")
  knopf:SetClampedToScreen(true)
  knopf:SetNormalTexture(BILDER .. "auge")
  knopf:SetHighlightTexture(BILDER .. "auge_hell", "ADD")
  knopf:SetMovable(true)
  knopf:RegisterForDrag("LeftButton")
  knopf:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then self.zieht = true; self:StartMoving() end
  end)
  knopf:SetScript("OnDragStop", function(self)
    if not self.zieht then return end
    self.zieht = false
    self:StopMovingOrSizing()
    if self.SetUserPlaced then self:SetUserPlaced(false) end   -- Lage merkt sich das Addon, nicht das Spiel
    local db = ns.db()
    if db and PlayerFrame then
      local ks, ps = self:GetEffectiveScale(), PlayerFrame:GetEffectiveScale()
      local kx, ky = self:GetCenter()
      local _, py = PlayerFrame:GetCenter()
      db.knopf = { x = kx - PlayerFrame:GetRight() * ps / ks, y = ky - py * ps / ks }
      ns.protokoll(string.format("Knopf verschoben: %.0f/%.0f", db.knopf.x, db.knopf.y))
    end
    anker()
  end)
  knopf:SetScript("OnClick", function()
    if leiste:IsShown() then leiste:Hide() else leiste:Show() end
  end)
  knopf:SetScript("OnEnter", tooltipZeigen)
  knopf:SetScript("OnLeave", function() GameTooltip:Hide() end)
  anker()
end

local Bau = CreateFrame("Frame")
Bau:RegisterEvent("PLAYER_LOGIN")
Bau:SetScript("OnEvent", function()
  local ok, fehler = pcall(function()
    baueKnopf()
    baueLeiste()
  end)
  if not ok then
    print(ns.P .. "Auge-Knopf konnte nicht gebaut werden: " .. tostring(fehler))
    ns.protokoll("FEHLER Knopf: " .. tostring(fehler))
    return
  end
  table.insert(ns.beobachter, auffrischen)
  auffrischen()
end)
