@echo off
rem Addons-holen.cmd
rem Holt die neueste Testfassung unserer Addons von GitHub und kopiert sie in den
rem AddOns-Ordner von World of Warcraft: Forever. Werkzeug fuer Georg zum Testen.
rem Angefasst werden nur die Ordner, die im Paket unter addon\ liegen
rem (ForeverGruppe, GruppeDiag). Die alten Fassungen werden vorher gesichert.
rem Keine Adminrechte, nichts wird installiert, nur Windows-Bordmittel (curl, tar).
setlocal EnableExtensions DisableDelayedExpansion
title Addons holen - wow-forever-gruppe
set "PAKET_URL=https://github.com/wilhelmgeorgirina-beep/wow-forever-gruppe/archive/refs/heads/main.zip"
set "PAKET_ORDNER=wow-forever-gruppe-main"
set "DATEN=%APPDATA%\wow-forever-gruppe"
set "MERKER=%DATEN%\addons-ordner.txt"
set "SICHERUNG=%DATEN%\Sicherung"
set "ARBEIT=%TEMP%\wow-forever-gruppe-holen"
set "FEHLER="

echo.
echo  ===================================================
echo    Addons holen  (wow-forever-gruppe, Testfassung)
echo  ===================================================
echo.

where curl.exe >nul 2>nul || goto kein_werkzeug
where tar.exe >nul 2>nul || goto kein_werkzeug
if not exist "%DATEN%\" mkdir "%DATEN%"

rem --- 1. AddOns-Ordner: gemerkt oder erfragen ---------------------------------
set "ADDONS="
if exist "%MERKER%" set /p ADDONS=<"%MERKER%"
if not defined ADDONS goto fragen
if exist "%ADDONS%\" goto ordner_ok

:fragen
echo  Bitte den AddOns-Ordner des Spiels angeben. So geht es:
echo    1. Im Explorer den Ordner  World of Warcraft\_forever_\Interface\AddOns  oeffnen.
echo    2. Oben in die Adresszeile klicken und Strg+C druecken.
echo    3. Hier mit Rechtsklick einfuegen und Enter druecken.
echo.
set "ADDONS="
set /p "ADDONS=  AddOns-Ordner: "
if not defined ADDONS goto fragen
set "ADDONS=%ADDONS:"=%"
if "%ADDONS:~-1%"=="\" set "ADDONS=%ADDONS:~0,-1%"
if not exist "%ADDONS%\" goto ordner_fehlt
for %%I in ("%ADDONS%") do set "NAME=%%~nxI"
for %%I in ("%ADDONS%\..") do set "ELTERN=%%~nxI"
if /i not "%NAME%"=="AddOns" goto falscher_ordner
if /i not "%ELTERN%"=="Interface" goto falscher_ordner
>"%MERKER%" echo %ADDONS%
echo.
echo  Gemerkt. Beim naechsten Mal wird nicht mehr gefragt.
goto ordner_ok

:ordner_fehlt
echo.
echo  Diesen Ordner gibt es nicht. Bitte noch einmal.
echo.
goto fragen

:falscher_ordner
echo.
echo  Das ist nicht der Ordner ...\Interface\AddOns. Bitte noch einmal.
echo.
goto fragen

:ordner_ok
echo  AddOns-Ordner: %ADDONS%
echo.

rem --- 2. Neuestes Paket laden und entpacken ------------------------------------
if exist "%ARBEIT%\" rmdir /s /q "%ARBEIT%"
mkdir "%ARBEIT%"
echo  Lade das neueste Paket von GitHub ...
curl.exe -L --fail --silent --show-error -o "%ARBEIT%\paket.zip" "%PAKET_URL%"
if errorlevel 1 goto fehler_laden
echo  Entpacke ...
tar.exe -xf "%ARBEIT%\paket.zip" -C "%ARBEIT%"
if errorlevel 1 goto fehler_entpacken
set "QUELLE=%ARBEIT%\%PAKET_ORDNER%\addon"
if not exist "%QUELLE%\" goto fehler_entpacken

rem --- 3. Jedes Addon sichern und neu einspielen --------------------------------
if not exist "%SICHERUNG%\" mkdir "%SICHERUNG%"
echo.
for /d %%A in ("%QUELLE%\*") do call :einspielen "%%~fA" "%%~nxA"
rmdir /s /q "%ARBEIT%"

echo.
if defined FEHLER goto ende_mit_fehler
echo  Fertig. Die alten Fassungen liegen in:
echo    %SICHERUNG%
echo.
echo  Laeuft das Spiel gerade: im Chat /reload eingeben.
echo  Kam ein neues Addon dazu: Spiel ganz neu starten.
echo.
pause
exit /b 0

:ende_mit_fehler
echo  Es gab Fehler, siehe oben. Bitte ein Foto davon an Gerald.
echo.
pause
exit /b 1

rem --- Unterprogramm: ein Addon-Ordner -------------------------------------------
:einspielen
set "QUELL=%~1"
set "ZIELNAME=%~2"
if "%ZIELNAME%"=="" goto :eof
set "ZIEL=%ADDONS%\%ZIELNAME%"
set "VER= ?"
for /f "tokens=2 delims=:" %%V in ('findstr /b /c:"## Version" "%QUELL%\%ZIELNAME%.toc"') do set "VER=%%V"
if not exist "%ZIEL%\" goto einspielen_kopieren
if exist "%SICHERUNG%\%ZIELNAME%\" rmdir /s /q "%SICHERUNG%\%ZIELNAME%"
xcopy "%ZIEL%" "%SICHERUNG%\%ZIELNAME%\" /e /i /q /y >nul
if errorlevel 1 goto einspielen_fehler
rmdir /s /q "%ZIEL%"
:einspielen_kopieren
xcopy "%QUELL%" "%ZIEL%\" /e /i /q /y >nul
if errorlevel 1 goto einspielen_fehler
echo    %ZIELNAME% Version%VER%  eingespielt
goto :eof
:einspielen_fehler
echo    %ZIELNAME%: FEHLER beim Kopieren
set "FEHLER=1"
goto :eof

rem --- Fehler vor dem Kopieren: Spielordner bleibt unveraendert -------------------
:kein_werkzeug
echo  FEHLER: curl oder tar fehlt. Das gibt es ab Windows 10 (Version 1803).
goto ende_unveraendert
:fehler_laden
echo  FEHLER: Das Paket konnte nicht geladen werden. Ist das Internet da?
goto ende_unveraendert
:fehler_entpacken
echo  FEHLER: Das Paket liess sich nicht entpacken.
:ende_unveraendert
echo  Am Spielordner wurde nichts veraendert.
echo.
pause
exit /b 1
