# Ergebnisse der Diagnose

Aus drei GruppeDiag-Berichten vom 09.11.2026 (allein, in der Vierergruppe,
in der Gruppe im Kampf gegen einen Eber in Durotar).

## Spiel

- Version 1.60.1, Build 70862 vom 06.11.2026, **Interface 16001**, deDE.
- WOW_PROJECT_ID = 18 (WOW_PROJECT_CAMELOT). Forever ist also ein eigener
  Projekttyp, kein Mainline und kein Classic.
- `issecretvalue` und `canaccessvalue` sind da: geheime Werte gibt es.

## Lebenswerte (wichtig fuer die Gesundheitswarnung)

- **Ausserhalb des Kampfes ist das aktuelle Leben geheim**, sogar das eigene:
  `UnitHealth("player")` liefert einen geheimen Wert, ebenso
  `UnitHealthPercent` und `UnitHealthMissing`. `UnitHealthMax` ist lesbar (219).
- **Im Kampf bleibt alles geheim:** eigenes Leben, Leben der Mitspieler
  (dort sogar der Hoechstwert) und des Ziels. Das Addon kann "unter 50 %"
  also nie selbst ausrechnen. UNIT_HEALTH-Ereignisse feuern trotzdem.
- Offen: ob Blizzard Kurven (C_CurveUtil) anbietet, die geheime Werte in
  Farbe oder Durchsichtigkeit uebersetzen. Das prueft GruppeDiag 0.1.1. Ein
  Warnton, der von einem geheimen Wert abhaengt, ist damit aber nicht
  moeglich; der Ton braucht eine andere Loesung oder entfaellt.

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
  Spezialisierungen. Allein: Rolle NONE; in der Gruppe bekommen alle, auch
  Schamane und Priester, die Standardrolle DAMAGER. Die Spielrolle taugt also
  nicht als Quelle.
- Entscheidung Georg (09.11.2026): **Jeder waehlt seine Rolle selbst im
  Addon** (Heiler, Nahkampf, Fernkampf).

## Gruppe im Spiel

- Plaketten der Gruppenmitglieder haben einen hellblauen Balken
  (0,67 / 0,67 / 1), andere freundliche Spieler den dunkleren (0,38 / 0,38 / 1).
- Zielmarkierungen waren in allen drei Berichten nil, obwohl
  RAID_TARGET_UPDATE dreimal feuerte. Noch offen, ob Georg als Nicht-Anfuehrer
  markieren konnte.
- Gruppenrahmen links zeigen Klassenfarbe (raidFramesDisplayClassColor = 1).

## Ton und Nachrichten

- `PlaySound`, `PlaySoundFile`, `StopSound` da. Tontest steht noch aus.
- Addon-Nachrichten: Prefix-Anmeldung erfolgreich (0 = Success).

## Gruppenrahmen

- `CompactPartyFrame`, `PartyFrame`, `CompactRaidFrameContainer`,
  `CompactUnitFrame_UpdateHealth` usw. vorhanden; `hooksecurefunc` da.
- `raidFramesDisplayClassColor` ist bei Georg auf 1.
