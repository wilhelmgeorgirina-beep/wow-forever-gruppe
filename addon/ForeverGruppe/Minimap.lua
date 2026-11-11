-- Minimap.lua
-- Holzring um die Minimap (Georgs Wahl, Entwurf 13 Ring C): dasselbe angekohlte
-- Holz wie am Charakterfenster, mit schmalem Goldrand innen. Blizzards eigener
-- Kompassring wird nur unsichtbar gemacht, die Karte, ihre Knoepfe und das
-- Zoomen bleiben wie sie sind. Der Ring faengt keine Mausklicks ab.
-- Wie die Minimap in Forever genau aufgebaut ist, wissen wir noch nicht sicher.
-- Darum sucht die Datei Blizzards Rahmenteile nur nach bekannten Namen und
-- schreibt in den Bericht, was sie gefunden hat.

local ADDON_NAME, ns = ...
local BILDER = "Interface\\AddOns\\" .. ADDON_NAME .. "\\bilder\\"

local LOCH = 400 / 472          -- Anteil des Lochs an der Bildkante (aus minimap_ring.py)
local UEBERLAPP = 0.985         -- das Loch liegt knapp innerhalb der Kartenkante, damit kein Spalt bleibt

-- Blizzards Rahmenteile um die Karte, die unser Ring ersetzt (je nach Spielfassung
-- heissen sie anders; was es nicht gibt, wird uebersprungen)
local BLIZZARD_TEILE = {
  { "MinimapCompassTexture", function() return MinimapCompassTexture end },
  { "MinimapBorder", function() return MinimapBorder end },
  { "MinimapBackdrop.Border", function() return MinimapBackdrop and MinimapBackdrop.Border end },
  { "MinimapContainer.Border", function() return MinimapCluster and MinimapCluster.MinimapContainer and MinimapCluster.MinimapContainer.Border end },
}

local rahmen
local zustand = "nicht gebaut"
local gefunden = {}

local function versteckeBlizzardTeile()
  for _, eintrag in ipairs(BLIZZARD_TEILE) do
    local name, hol = eintrag[1], eintrag[2]
    local ok, teil = pcall(hol)
    if ok and teil then
      local okA = pcall(teil.SetAlpha, teil, 0)
      gefunden[#gefunden + 1] = name .. (okA and "" or " (nicht versteckbar)")
    end
  end
end

local function groesseAnpassen()
  if not rahmen or not Minimap then return end
  local ok, breite = pcall(Minimap.GetWidth, Minimap)
  if not ok or not breite or breite <= 0 then return end
  local kante = breite * UEBERLAPP / LOCH
  rahmen:SetSize(kante, kante)
end

local function baue()
  if not Minimap then
    zustand = "Minimap nicht gefunden"
    ns.protokoll("Minimap-Ring: " .. zustand)
    return
  end
  -- gleiche Ebene wie die Karte: dann liegt der Ring ueber der Karte, aber unter
  -- Blizzards Knoepfen am Rand (Zoom, Spur, Kalender)
  rahmen = CreateFrame("Frame", "ForeverGruppeMinimapRing", Minimap)
  rahmen:SetFrameStrata(Minimap:GetFrameStrata())
  rahmen:SetFrameLevel(Minimap:GetFrameLevel())
  rahmen:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
  rahmen:EnableMouse(false)

  local ring = rahmen:CreateTexture(nil, "OVERLAY")
  ring:SetTexture(BILDER .. "minimap_ring")
  ring:SetAllPoints(rahmen)

  groesseAnpassen()
  pcall(Minimap.HookScript, Minimap, "OnSizeChanged", groesseAnpassen)
  versteckeBlizzardTeile()

  zustand = "gebaut"
  ns.protokoll("Minimap-Ring: gebaut, Blizzard-Teile versteckt: " .. (#gefunden > 0 and table.concat(gefunden, ", ") or "keine gefunden"))
end

-- Schnittstelle fuer den Bericht ---------------------------------------------

function ns.minimapLage()
  if not rahmen then return zustand end
  local ok, text = pcall(function()
    local eltern = Minimap:GetParent()
    local maske = Minimap.GetMaskTexture and select(2, pcall(Minimap.GetMaskTexture, Minimap))
    return string.format("%s, Karte %.0f x %.0f (Eltern %s, Ebene %d, Maske %s), Ring %.0f, versteckt: %s",
      zustand, Minimap:GetWidth(), Minimap:GetHeight(), tostring(eltern and eltern:GetName() or "?"),
      Minimap:GetFrameLevel(), tostring(maske), rahmen:GetWidth(),
      #gefunden > 0 and table.concat(gefunden, ", ") or "keine Blizzard-Teile gefunden")
  end)
  return ok and text or (zustand .. " (Bericht nicht moeglich: " .. tostring(text) .. ")")
end

-- Ereignisse -----------------------------------------------------------------

local E = CreateFrame("Frame")
E:RegisterEvent("PLAYER_LOGIN")
E:SetScript("OnEvent", function(self)
  self:UnregisterAllEvents()
  local ok, err = pcall(baue)
  if not ok then
    zustand = "FEHLER beim Bau: " .. tostring(err)
    ns.protokoll("Minimap-Ring: " .. zustand)
    print(ns.P .. "Holzring um die Minimap konnte nicht gebaut werden: " .. tostring(err))
  end
end)
