# Plan

Stand 09.11.2026. Kleine Schritte, jede Version testbar, Releases nur nach
Georgs Freigabe.

## Schritt 1: Diagnose-Addon GruppeDiag (in Arbeit)

Prueft im Spiel, welche Schnittstellen Forever Addons anbietet: Spielversion
und Interface-Nummer, Funktionen fuer Namensplaketten, Zielmarkierungen,
Gruppe und Rollen, Lebenswerte (sind sie im Kampf "geheim"?), CVars und ob
Addons sie setzen duerfen, Ton aus eigener Datei, Addon-Nachrichten. Der
Bericht laesst sich im Spiel kopieren und steht in den SavedVariables.

## Schritt 2: Gruppen-Addon, erste Version

- Namensplaketten der Gruppenmitglieder nach Rolle faerben (Heiler gruen,
  Nahkampf rot, Fernkampf blau), Zielmarkierung klein in der Plakette.
- Rolle waehlt jeder selbst per `/gruppe` (Georgs Entscheidung 09.11.2026),
  das Spiel liefert keine brauchbaren Rollen.
- Einstellungen per `/gruppe`, Debug-Ausgaben in SavedVariables.
- Danach: Gesundheitswarnung in den Gruppenrahmen. Lebenswerte sind in
  Forever immer geheim; Blinken geht nur ueber Blizzard-Kurven (wird mit
  GruppeDiag 0.1.1 geprueft), ein wertabhaengiger Warnton geht nicht.
- Weniger fremde Namen auf dem Bildschirm: begonnen mit ForeverGruppe 0.1.0
  (fremde Spieler blass oder aus, umschaltbar mit /gruppe). Die Entfernung
  zu fremden Spielern darf ein Addon nicht messen; "nur in der Naehe" laeuft
  ueber Blizzards Ausblenden nach Kameraabstand (nameplateMaxAlphaDistance),
  dessen genaue Wirkung noch im Spiel zu pruefen ist.
- Wunsch Georg 10.11.2026: Lebenskreis aus 12 Kuchenstuecken statt Balken,
  Marke in der Mitte (Entwurf 4). Haengt an den Kurven (C_CurveUtil).
- Wunsch Georg: eigene Symbole statt Blizzard-Marken. Moeglich nur, wenn
  Blizzard die Marke als Ausschnitt einer Bilddatei zeichnet; dann bekommt
  das Addon eine eigene Datei im gleichen Raster (GruppeDiag 0.1.2 prueft).
- Spaeter: Anfuehrer-Ansagen per Addon-Nachricht, Rollenverteilung, Warnungen.

## Schritt 3: Updater fuer Windows

Technik: **C# mit .NET 8 und Avalonia UI**, als eine einzelne Exe fuer
win-x64 (self-contained, Single-File), gebaut auf dem Mac mit
`dotnet publish -r win-x64`.

Warum so:
- Baut ohne Windows-Rechner direkt auf dem Mac.
- Die Oberflaeche laeuft auch auf dem Mac, Gerald kann sie also selbst
  starten und Georg Bilder zeigen, bevor etwas nach Windows geht.
- Mitspieler brauchen nichts zu installieren (Laufzeit steckt in der Exe),
  keine Adminrechte.
- Nachteil: Die Exe wird etwa 40 bis 60 MB gross. Fuer einen Download alle
  paar Wochen ist das vertretbar.

Verworfen: WinForms oder WPF (laesst sich auf dem Mac zwar bauen, aber nicht
starten und ansehen), Python mit PyInstaller (braucht Windows zum Bauen).

Was die Exe tut:
1. Beim ersten Start den WoW-Ordner per Ordnerauswahl erfragen und in einer
   kleinen Datei neben der Exe merken (`%APPDATA%\wow-forever-gruppe\`).
   Es wird geprueft, dass `_forever_\Interface\AddOns` darin liegt.
2. Installierte Version aus der .toc des Addons lesen, neueste Version aus
   den GitHub-Releases (eine Abfrage je Start), Aenderungstext anzeigen.
3. Knopf "Update installieren": Zip laden, alten Addon-Ordner als Sicherung
   umbenennen, neuen Ordner entpacken. Nur der eigene Addon-Ordner wird
   angefasst.
4. Gibt es eine neuere Exe im Release, wird das gemeldet; der Tausch der Exe
   selbst laeuft ueber eine kleine Hilfsdatei nach dem Beenden.
5. Keine Telemetrie, kein Internet ausser GitHub.

Windows zeigt bei unsignierten Exes die SmartScreen-Warnung. Die Anleitung
fuer Mitspieler erklaert "Weitere Informationen" und "Trotzdem ausfuehren".
Optional spaeter: Bau ueber GitHub Actions, damit jedes Release reproduzierbar
entsteht.
