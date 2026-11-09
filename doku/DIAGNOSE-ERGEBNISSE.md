# Ergebnisse der Diagnose

Aus dem GruppeDiag-Bericht vom 09.11.2026 (Georg, allein in Durotar, kein Kampf).
Offen sind noch der Gruppen- und der Kampftest.

## Spiel

- Version 1.60.1, Build 70862 vom 06.11.2026, **Interface 16001**, deDE.
- WOW_PROJECT_ID = 18 (WOW_PROJECT_CAMELOT). Forever ist also ein eigener
  Projekttyp, kein Mainline und kein Classic.
- `issecretvalue` und `canaccessvalue` sind da: geheime Werte gibt es.

## Lebenswerte (wichtig fuer die Gesundheitswarnung)

- **Ausserhalb des Kampfes ist das aktuelle Leben geheim**, sogar das eigene:
  `UnitHealth("player")` liefert einen geheimen Wert, ebenso
  `UnitHealthPercent` und `UnitHealthMissing`. `UnitHealthMax` ist lesbar (219).
- Ob das im Kampf anders ist, zeigt erst die Kampfprobe. Davon haengt ab, ob
  das Addon "unter 50 %" selbst erkennen darf oder nur Blizzards Anzeige
  nutzen kann.

## Namensplaketten

- `C_NamePlate.GetNamePlates` und `GetNamePlateForUnit` sind da, Ereignisse
  NAME_PLATE_UNIT_ADDED/REMOVED feuern.
- Die Groessen-Funktionen (`GetNamePlateFriendlySize` usw.) fehlen. Groesse
  einer Plakette: 142,5 x 53,2; Lebensbalken 124 x 10.
- Jede Plakette hat einen `UnitFrame` mit `healthBar`, `name` (FontString,
  Schrift FRIZQT 11,2 mit Umriss), `RaidTargetFrame` (22 x 22, Textur
  `RaidTargetIcon`), `selectionHighlight`, `aggroHighlight`,
  `ClassificationFrame`, `LevelFrame`, `WidgetContainer`, `SoftTargetFrame`.
  Kein `castBar`, kein `BuffFrame`.
- Freundliche Spieler bekommen den blauen Balken (0,38 / 0,38 / 1), NPCs gruen.
- Zielmarkierungen: `GetRaidTargetIndex` und `SetRaidTargetIconTexture` da.

## CVars

- Keine der gefundenen CVars ist gesperrt oder nur lesbar. Viele sind
  "sicher": die darf ein Addon nur ausserhalb des Kampfes aendern.
- Vorhanden und nutzbar: `nameplateShowFriendlyPlayers`,
  `nameplateShowFriendlyNPCs`, `nameplateShowEnemies` (bei Georg 0!),
  `nameplateShowEnemyMinions/Minus/Pets/Guardians/Totems`,
  `nameplateShowOnlyNameForFriendlyPlayerUnits`, `nameplateMaxDistance` (45),
  `nameplatePlayerMaxDistance` (40), `nameplateMinScale/MaxScale/SelectedScale`,
  `nameplateMinAlpha/MaxAlpha/OccludedAlphaMult`, `nameplateSize`,
  alle `UnitName...`-CVars (Namen ueber Koepfen ohne Plakette).
- Fehlen: `nameplateShowFriends`, `nameplateShowOnlyNames`,
  `nameplateGlobalScale`, `NamePlateHorizontalScale/VerticalScale`,
  `nameplateMotion`, `ShowClassColorInNameplate`,
  `ShowClassColorInFriendlyNameplate`, `useCompactPartyFrames`.

## Gruppe und Rollen

- `UnitGroupRolesAssigned`, `UnitGroupRolesAssignedEnum`, `UnitSetRole`,
  `GetRaidRosterInfo` sind da. `GetSpecialization` fehlt: keine
  Spezialisierungen, Rollen kommen nicht automatisch. Georg allein: Rolle NONE.
- Folgerung: Die Rolle (Heiler, Nahkampf, Fernkampf) waehlt jeder im Addon
  selbst oder der Anfuehrer verteilt sie per Addon-Nachricht.

## Ton und Nachrichten

- `PlaySound`, `PlaySoundFile`, `StopSound` da. Tontest steht noch aus.
- Addon-Nachrichten: Prefix-Anmeldung erfolgreich (0 = Success).

## Gruppenrahmen

- `CompactPartyFrame`, `PartyFrame`, `CompactRaidFrameContainer`,
  `CompactUnitFrame_UpdateHealth` usw. vorhanden; `hooksecurefunc` da.
- `raidFramesDisplayClassColor` ist bei Georg auf 1.
