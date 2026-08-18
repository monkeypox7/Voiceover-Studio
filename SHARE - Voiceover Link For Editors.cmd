@echo off
title Voiceover link for editors
powershell -NoProfile -ExecutionPolicy Bypass -WorkingDirectory "%~dp0" -File "start-tunnel.ps1"
