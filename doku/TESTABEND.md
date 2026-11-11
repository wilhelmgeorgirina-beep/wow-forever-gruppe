# Testabend 11.11.2026: Was Georg im Spiel prueft

Stand nach ForeverGruppe 0.3.1 und GruppeDiag 0.1.3. Reihenfolge so, dass
die Berichte am Ende alles enthalten. Dauer etwa 30 Minuten.

## 0. Vorbereitung

1. `Addons-holen.cmd` doppelklicken (holt beide Addons in der neuesten Fassung).
2. WoW ganz schliessen und neu starten. Ein `/reload` reicht diesmal nicht,
   weil neue Dateien dazugekommen sind (Minimap.lua).
3. Im Chat muss stehen: "Gruppe 0.3.1 geladen" und "GruppeDiag 0.1.3 geladen".

## 1. Charakterfenster und Gruppenringe (ForeverGruppe 0.3.0)

Braucht mindestens einen Mitspieler in der Gruppe.

- Sitzen unter dem Wolfsfenster kleine Holzringe, versetzt auf und ab, einer
  je Mitspieler, mit Bild in der Mitte?
- Haengt unter jedem Ring mittig ein zerrissener Banner mit dem Vornamen,
  senkrecht geschrieben? (Steht der Name waagerecht oder fehlt er: so melden.)
- Fuellt sich der Lebensring sichtbar, wenn jemand Leben verliert und
  zurueckbekommt?
- Knopf "Rollen": klappt die Legende nach unten auf? Laesst sich dort die
  eigene Rolle waehlen, und faerbt sich der eigene Banner danach?
- Sieht der Mitspieler nach seiner Wahl bei dir die richtige Farbe (sein
  Addon muss dafuer auch 0.3.0 haben)?
- Traegt der Gruppenfuehrer oben links am Ring das goldene Medaillon?
- Klick auf einen Ring waehlt den Mitspieler als Ziel, Rechtsklick oeffnet
  sein Menue?

## 2. Holzring um die Minimap (ForeverGruppe 0.3.1)

- Liegt der Holzring sauber um die runde Karte, ohne Spalt zwischen Holz
  und Karte?
- Ist Blizzards eigener Kompassring darunter verschwunden, oder schaut er
  noch heraus?
- Gehen Zoomen (Mausrad ueber der Karte) und die Knoepfe am Rand noch
  (Spur, Kalender, Uhr, Zonenname)?
- Verdeckt der Ring etwas, das du brauchst?

## 3. Spur-Menue der Minimap (Blizzard, kein Addon)

- Auf den Spur-Knopf an der Minimap klicken (Lupe oder Pfeil).
- Haken setzen bei Haendler, Lehrer, Gastwirt, Reparatur, Flugmeister,
  Bank, Auktionator, soweit angeboten.
- Reicht dir das in der Stadt schon, oder bleiben die Symbole zu klein?

## 4. NPC-Titel sammeln (GruppeDiag 0.1.3) - in einer Stadt

- Mit der Maus nacheinander ueber einen Haendler, einen Lehrer, einen
  Gastwirt, einen Bankier und einen Flugmeister fahren. Jeder braucht nur
  eine Sekunde unter der Maus.
- Im Chat erscheint je NPC einmal eine Zeile "GruppeDiag NPC Name: Titel".
  Steht dort der Titel ("Ruestungshaendler"), ist der Weg frei. Steht dort
  "<GEHEIM>" oder "?", wissen wir Bescheid.

## 5. Kampf

- Einen kurzen Kampf fuehren, Mitspieler lassen sich etwas verletzen.
- Blinkt ein Ring rot, wenn jemand unter einem Drittel Leben ist? Hoert es
  auf, wenn er wieder geheilt ist?
- Blinkt dein eigener grosser Ring ebenso?
- GruppeDiag zeichnet 2 Sekunden nach Kampfbeginn von selbst eine Probe auf.

## 6. Ton (10 Sekunden)

- `/gruppediag ton` eingeben: Hoerst du zwei Toene (Blizzard-Klang und
  unsere eigene Datei)?

## 7. Berichte und Bilder fuer Gerald

1. `/gruppe bericht` eingeben.
2. `/gruppediag` eingeben (Fenster geht auf, kann gleich geschlossen werden).
3. `/reload` eingeben, damit beides auf die Platte geschrieben wird.
4. Diese beiden Dateien schicken:
   `World of Warcraft\_forever_\WTF\Account\<Kontoname>\SavedVariables\ForeverGruppe.lua`
   `World of Warcraft\_forever_\WTF\Account\<Kontoname>\SavedVariables\GruppeDiag.lua`
5. Drei Screenshots: Charakterfenster mit den Gruppenringen, die Minimap mit
   Ring, ein Haendler mit seinem Tooltip unter der Maus.
6. Fehlertexte (rote Lua-Fehler) abschreiben oder abfotografieren.

## 8. Fuer die Heil-Makros notieren

- Vornamen aller sechs Mitspieler.
- Namen deiner Heilzauber: die schnelle kleine, die grosse, Gruppenheilung,
  Schild oder Heilung ueber Zeit, falls vorhanden.
- Welche Taste soll welchen Mitspieler heilen.

Damit schreibt Gerald die Makrotexte zum Kopieren.
