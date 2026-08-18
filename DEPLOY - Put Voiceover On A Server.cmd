@echo off
title Put Voiceover Studio on a server
powershell -NoProfile -ExecutionPolicy Bypass -WorkingDirectory "%~dp0" -File "deploy-to-server.ps1"
