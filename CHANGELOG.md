# Aenderungen

Alle Versionen in einfachem Deutsch, neueste oben.

## Unveroeffentlicht

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
