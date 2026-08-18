@echo off
REM Copies autostart-voiceover.vbs into your Startup folder, so the Voiceover
REM Studio and its public link come back on their own every time this PC is
REM switched on. Run this once. No administrator rights are needed.
REM
REM To undo it later, delete autostart-voiceover.vbs from:
REM   %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

echo.
echo   Setting the Voiceover Studio to start automatically...
echo.

copy /Y "%~dp0autostart-voiceover.vbs" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\autostart-voiceover.vbs" >nul

if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\autostart-voiceover.vbs" (
  echo   Done. It will start by itself from now on.
) else (
  echo   FAILED. Nothing was copied.
)
echo.
pause
