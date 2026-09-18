@echo off
:: Batch Entrypoint for WUBI-AI
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\src\gui\Launch-WubiAI-GUI.ps1"
exit /b
