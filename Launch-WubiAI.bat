@echo off
title WUBI-AI: Ubuntu & Omarchy AI Workstation Installer
cd /d "%~dp0"

:: Auto-Elevation Check: Automatically elevate to Administrator if not already elevated
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WUBI-AI] Auto-elevating to Administrator Mode...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run WUBI-AI Fluent GUI in -STA mode
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "src\gui\Launch-WubiAI-GUI.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WUBI-AI GUI encountered an issue or was closed.
    pause
)
