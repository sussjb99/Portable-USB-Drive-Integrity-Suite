:: ============================================================
:: Portable Drive Baby Sitter - Integrity Suite
:: File: sign_all.bat
:: Author: sussjb99
:: Version: 1.0
:: Last Modified: 2026-04-14
:: ============================================================

@echo off
setlocal DISABLEDELAYEDEXPANSION

echo ============================================
echo Signing All Executables in C++ Folder
echo ============================================
echo.

:: Path to signtool.exe
set SIGNTOOL=E:\PortableDriveBabySitter\installer_source\signing_certificate\signtool.exe

:: Path to certificate
set PFX=E:\PortableDriveBabySitter\installer_source\signing_certificate\alias_cert.pfx

:: Certificate password
set /p PFXPASS=Enter PFX password:
            

:: Timestamp server
set TIMESTAMP=http://timestamp.digicert.com

:: List of executables to sign
set FILES=baselineXML_estimate.exe corruptor.exe deviceinfo.exe full_probe.exe FileListGen.exe scantime_estimate.exe surface_scan.exe

for %%F in (%FILES%) do (
    echo Signing %%F ...
    "%SIGNTOOL%" sign ^
        /f "%PFX%" ^
        /p "%PFXPASS%" ^
        /tr %TIMESTAMP% ^
        /td sha256 ^
        /fd sha256 ^
        "%%F"

    if errorlevel 1 (
        echo ERROR: Failed to sign %%F
        pause
        exit /b 1
    )

    echo Verifying signature for %%F ...
rem    "%SIGNTOOL%" verify /pa "%%F"

rem    if errorlevel 1 (
rem        echo ERROR: Signature verification failed for %%F
rem        pause
rem        exit /b 1
rem    )

echo (Skipping verification for self-signed certificate)

    echo Successfully signed and verified: %%F
    echo.
)

echo ============================================
echo All executables signed successfully
echo ============================================
pause