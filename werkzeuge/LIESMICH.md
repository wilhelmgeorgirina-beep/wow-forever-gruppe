# Werkzeuge

## Addons-holen.cmd (fuer Georg zum Testen)

Holt die neueste Fassung aus diesem Repo (Zweig `main`) und kopiert alle
Addons aus `addon/` in den AddOns-Ordner des Spiels. Vorher wird jede alte
Fassung nach `%APPDATA%\wow-forever-gruppe\Sicherung` gesichert. Den
AddOns-Ordner fragt das Werkzeug beim ersten Start ab und merkt ihn sich in
`%APPDATA%\wow-forever-gruppe\addons-ordner.txt`. Zum Zuruecksetzen diese
Datei loeschen.

Fuer die Mitspieler ist das Werkzeug nicht gedacht: Sie bekommen nur
getestete Releases ueber den Updater.
