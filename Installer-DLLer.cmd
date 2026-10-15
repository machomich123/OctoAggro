@echo off
setlocal
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0tools\Install-Dependencies.ps1"
if errorlevel 1 (
  echo Installering feilet. Se meldingen over.
  pause
  exit /b 1
)
echo Ferdig. Start WoW med VanillaFixes og skriv /oa status.
pause
