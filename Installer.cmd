@echo off
setlocal
set "OCTO_GAME_PATH="
set /p "OCTO_GAME_PATH=Mappe med WoW.exe [W:\Games\Octowow]: "
if not defined OCTO_GAME_PATH set "OCTO_GAME_PATH=W:\Games\Octowow"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Install.ps1" -GamePath "%OCTO_GAME_PATH%"
if errorlevel 1 (
  echo Installering feilet. Se meldingen over.
  pause
  exit /b 1
)
echo Installering ferdig. Start WoW og skriv /oa status.
pause
