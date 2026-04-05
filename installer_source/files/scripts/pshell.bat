@echo off
set "script=%~dp0%1"
:: Remove the first argument (the script name) from the list
shift
:: Pass the remaining arguments (%1, %2, etc.) to PowerShell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%" %1 %2 %3 %4 %5 %6 %7 %8 %9
