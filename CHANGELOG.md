# Aenderungen

Alle Versionen in einfachem Deutsch, neueste oben.

## Unveroeffentlicht

- ForeverGruppe 0.4.1 (Georgs Wunsch 14.11.2026): Die Namen in den
  Wolfsfenstern sind groesser, heller und in klarer Schrift mit Schatten,
  beim eigenen Fenster wie bei den Mitspielern. Noch nicht im Spiel getestet.
- GruppeDiag 0.1.4: Die Startdatei (GruppeDiag.toc) war seit 0.1.3 leer,
  das Diagnose-Addon wurde deshalb gar nicht geladen. Behoben. Neu: Probe
  fuer den NPC-Finder (/gruppediag wegpunkt setzt einen Probe-Wegpunkt,
  /gruppediag wegpunkt weg nimmt ihn zurueck; geoeffnete Haendler- und
  Lehrerfenster werden mit Standort gemerkt) und ein Abschnitt zur
  Schadensmessung des Spiels (welche Zahlen ein Addon lesen darf, auch
  im Kampf). Grundlage fuer Georgs Wuensche: NPCs finden und Schaden je
  Mitspieler am Wolfsfenster zeigen.
- ForeverGruppe 0.4.0 (Georgs Wahl, Entwurf 16 B): Die Mitspieler stehen
  jetzt als Wolfsfenster unter dem eigenen, leicht nach rechts versetzt und
  etwas kleiner (78 %). Jedes zeigt Bild, Mana-Ring, Vorname mit dem Leben
  als gruene Flaeche dahinter und die Stufe. Die Goldbeschlaege am Wolfskopf
  schimmern in der Rollenfarbe, auch am eigenen Fenster: Tank rot, Heiler
  gruen, Nahkampf gelb, Fernkampf blau, ohne Rolle bleibt das Gold. Die
  kleinen Holzringe und die Banner entfallen. Der Knopf "Rollen" mit der
  Legende bleibt. Noch nicht im Spiel getestet.
- ForeverGruppe 0.3.5: Die Stufe im Medaillon stimmt jetzt auch direkt nach
  einem Aufstieg. Bisher blieb die alte Zahl stehen (Georg war 11, gezeigt
  wurde 10), weil das Spiel im Moment des Aufstiegs noch die alte Stufe
  nennt. Noch nicht im Spiel getestet.
- ForeverGruppe 0.3.4: Die gruene Lebensflaeche fuellt das Namensbrett jetzt
  ganz aus, oben und unten bis an den Holzrahmen. Die Goldverzierungen
  liegen sichtbar davor. Georg gefiel 0.3.3 nach dem Vorschaubild, nur die
  Raender sollten gefuellt sein. Noch nicht im Spiel getestet.
- ForeverGruppe 0.3.3 (Georgs Wunsch nach dem Test vom 11.11.2026): Auf dem
  Namensbrett steht nur noch der Vorname. Der gruene Lebensring ums eigene
  Bild ist weg; dafuer ist der blaue Mana-Ring doppelt so breit und das Bild
  etwas groesser. Das Leben liegt jetzt als halb durchsichtige gruene Flaeche
  hinter dem Namen auf dem Holzbrett und schwindet von rechts nach links.
  Der Klick auf den Wolfskopf (Nachname ein/aus) entfaellt. Noch nicht im
  Spiel getestet.
- ForeverGruppe 0.3.2: Blizzards alte Gruppenfenster verschwinden, sobald
  die Holzringe stehen (nur unsichtbar und nicht klickbar, nichts wird
  entfernt). Die Ringe der Mitspieler zeigen jetzt aussen duenn das Mana
  (oder Wut, Energie), innen das Leben, wie am eigenen grossen Ring.
  Georgs Test vom 11.11.2026: Ringe, Banner und senkrechte Namen stehen.
- GruppeDiag 0.1.3: sammelt fuer jeden NPC in Sichtweite, unter der Maus
  oder als Ziel, was sein Tooltip verraet (Titel wie "Ruestungshaendler"),
  und ob das lesbar oder geheim ist. Dazu der Aufbau der Minimap und die
  Liste der Spur-Symbole. Grundlage fuer Georgs Wunsch, Haendler und Lehrer
  gross ueber den Koepfen zu zeigen.
- ForeverGruppe 0.3.1: Holzring um die Minimap (Georgs Wahl, Entwurf 13
  Ring C): dasselbe angekohlte Holz wie am Charakterfenster, innen mit
  schmalem Goldrand. Blizzards Kompassring wird unsichtbar, Karte, Knoepfe
  und Zoomen bleiben. Noch nicht im Spiel getestet.
- ForeverGruppe 0.3.0: Die Mitspieler als kleine Holzringe unter dem
  Wolfsfenster (Georgs Wahl, Entwurf 12), versetzt auf und ab. Im Ring das
  Bild und ein Lebensring, darunter mittig ein zerrissener Banner mit dem
  Vornamen. Die Bannerfarbe zeigt die Rolle: Tank rot, Heiler gruen,
  Nahkampf gelb, Fernkampf blau, grau ohne Rolle. Der Knopf "Rollen" klappt
  die Legende auf; dort waehlt jeder seine eigene Rolle, das Addon sagt sie
  den Addons der Mitspieler weiter. Der Gruppenfuehrer traegt oben links ein
  goldenes Medaillon mit Krone. Warnung: Unter einem Drittel Leben blinkt
  der Ring rot, auch der eigene grosse Ring. Klick auf einen Ring waehlt den
  Mitspieler als Ziel, Rechtsklick oeffnet sein Menue. Noch nicht im Spiel
  getestet.
- ForeverGruppe 0.2.2: Vorname gross, Nachname kleiner darunter. Ein Klick
  auf den Wolfskopf blendet den Nachnamen aus und wieder ein; das Addon
  merkt sich die Wahl.
- ForeverGruppe 0.2.1: Auf dem Namensbrett steht jetzt auch der Nachname
  (zum Beispiel "Gosha Analphabet" statt nur "Gosha"). Charakterfenster von
  Georg am 11.11.2026 im Spiel gesehen: Rahmen, Bild, Stufe und Auge-Knopf
  sitzen richtig, die Kurven fuer die Ringe laufen ohne Fehler.
- ForeverGruppe 0.2.0: Eigenes Charakterfenster im Holzrahmen mit Wolf
  (Georgs Wahl, Entwurf 7 Rahmen 1). Im Ring aussen das Mana, innen das
  Leben, in der Mitte das Charakterbild, Name auf dem Brett, Stufe im
  Medaillon. Klick waehlt dich als Ziel, Rechtsklick oeffnet das Menue,
  Shift + Ziehen verschiebt, `/gruppe fenster` stellt es zurueck. Blizzards
  Fenster wird unsichtbar. Die Ringe fuellen sich ueber Blizzards Kurven,
  ohne dass das Addon Leben oder Mana kennt. Der Auge-Knopf sitzt jetzt an
  der Spitze des Namensbretts.
- ForeverGruppe 0.1.3: Auge-Knopf rechts neben dem Charakterfenster. Ein
  Klick klappt eine kleine Leiste auf, darin Spieler und NPCs je an / nah /
  aus. Noch ein Klick oder Esc klappt sie zu. Shift + Ziehen verschiebt den
  Knopf, `/gruppe knopf` stellt ihn zurueck. Die Chat-Befehle bleiben als
  Reserve.
  Von Georg am 11.11.2026 im Spiel getestet: Knopf, Leiste und Ausblenden
  funktionieren.
- ForeverGruppe 0.1.2: Freundliche NPCs (gruene Namen) werden ebenfalls blass
  oder ausgeblendet, mit eigenem Schalter `/gruppe npc an|nah|aus`. Neutrale
  und feindliche Wesen bleiben unveraendert, Begleiter der Gruppe zaehlen zur
  Gruppe.
- ForeverGruppe 0.1.1: Auch die freien Namen, die das Spiel von weitem ueber
  fremden Spielern und ihren Begleitern zeigt, verschwinden jetzt bei
  `/gruppe namen nah` und `aus` (Georgs Test vom 11.11.2026).
- Neues Addon ForeverGruppe 0.1.0: Namensplaketten fremder Spieler werden
  blass (`/gruppe namen nah`) oder unsichtbar (`/gruppe namen aus`). Die
  eigene Gruppe bleibt immer voll sichtbar, das Ziel und Spieler unter der
  Maus auch. `/gruppe namen an` stellt alles wie bei Blizzard zurueck.
  Das Addon setzt die noetigen Spieleinstellungen selbst, im Kampf erst nach
  Kampfende. `/gruppe bericht` speichert einen Bericht fuer die Fehlersuche.
- GruppeDiag 0.1.2: zeigt zusaetzlich, welche Bilddatei Blizzard fuer die
  Zielmarkierung benutzt.
- GruppeDiag 0.1.1: probiert aus, was mit geheimen Lebenswerten noch geht
  (Vergleiche, Kurven, Durchreichen an Balken und Farben), zeigt zuerst die
  Plaketten der eigenen Gruppe, Kampfprobe mit Einzelheiten, Namenssuche
  nach Forever-eigenen Funktionen. Markentest: ob geheime Marken auf eigene
  Bilder gezeichnet werden duerfen, Lage des Markenrahmens auf der Plakette.

- Diagnose-Addon GruppeDiag angelegt: prueft Spielversion, Schnittstellen,
  Namensplaketten-Einstellungen und Gruppendaten und schreibt einen Bericht.
