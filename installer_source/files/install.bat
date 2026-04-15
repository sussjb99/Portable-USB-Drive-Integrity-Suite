@echo off
setlocal DisableDelayedExpansion
title Portable Drive Baby Sitter - Installer
color 0F

echo ============================================================
echo            PORTABLE DRIVE BABY SITTER - INSTALLER
echo ============================================================
echo.

:GET_DRIVE
set "TARGET="
set /p "TARGET=Enter the drive letter to install to (e.g., I): "

:: Normalize: Remove spaces, remove colons, take only the first character
set "TARGET=%TARGET: =%"
set "TARGET=%TARGET::=%"
set "TARGET=%TARGET:~0,1%"

:: Validation: Check if input is empty
if "%TARGET%"=="" goto GET_DRIVE

:: Block C: drive
if /I "%TARGET%"=="C" (
    echo [ERROR] Installation to C: is restricted.
    echo.
    goto GET_DRIVE
)

:: Validate drive exists
if not exist "%TARGET%:\" (
    echo [ERROR] Drive %TARGET%: was not found.
    echo.
    goto GET_DRIVE
)

echo.
echo Installing to %TARGET%:\Integrity_Check...

:: 1. Create directory
mkdir "%TARGET%:\Integrity_Check" >nul 2>&1

:: 2. Copy files from the SFX temporary "files" folder
:: %~dp0 ensures it pulls from the current location of this script
xcopy /E /I /Y "%~dp0*" "%TARGET%:\Integrity_Check\" >nul

:: 3. Clean up the installer copy from the target drive
del "%TARGET%:\Integrity_Check\install.bat" >nul 2>&1

:: 4. Move the root tool (The "!" is handled safely because Delayed Expansion is OFF)
if exist "%TARGET%:\Integrity_Check\!VERIFY_INTEGRITY.BAT" (
    move /Y "%TARGET%:\Integrity_Check\!VERIFY_INTEGRITY.BAT" "%TARGET%:\" >nul
)

echo.
echo Installation complete!
echo Files installed to: %TARGET%:\Integrity_Check
echo Root tool installed to: %TARGET%:\
echo.

set /p "RUNNOW=Run Drive Baby Sitter now? (Y/N): "
if /I "%RUNNOW%"=="Y" (
    echo Launching...
    call "%TARGET%:\!VERIFY_INTEGRITY.BAT"
)

echo.
echo Closing installer...
pause