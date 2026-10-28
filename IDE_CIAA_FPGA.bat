@echo off
setlocal
chcp 65001 >nul
set "ROOT=%~dp0"
cd /d "%ROOT%"

if not exist "%ROOT%scripts\windows\bootstrap.ps1" (
    echo ERROR: la carpeta esta incompleta. Falta scripts\windows\bootstrap.ps1
    pause
    exit /b 1
)

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\windows\bootstrap.ps1" %*
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo ERROR: el proceso termino con codigo %RC%.
pause
exit /b %RC%
