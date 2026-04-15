:: ============================================================
:: Portable Drive Baby Sitter - Integrity Suite
:: File: quick_surface_scan.bat
:: Author: sussjb99
:: Version: 1.0
:: Last Modified: 2026-04-12
:: Copyright (c) 2026 sussjb99. All rights reserved.
:: Licensed under the MIT License. See LICENSE.txt for details.
:: ============================================================

@echo off

:: Drive of the running script (returns like C:)
set "DRV=%~d0"

:: Drive letter only (returns like C)
set "DRV_LETTER=%DRV:~0,1%"

:: Set Percent for Surface Scan 1%
set "PERCENTAGE=1"

:: TempPath used for creeating the temporary test files
set "TEMPPATH=%DRV%\integrity_check\logs"

:: Set home director
set "HME=%DRV%\integrity_check"

:: Set script directory
set "SCRIPTS=%HME%\scripts"

:: ReportPath location to store generated reports
set "REPORTPATH=%HME%\reports"


:: Set executable locations
SET "SURFACE_SCAN=%HME%\bin\surface_scan.exe"

:: Location of Drive_Status.xml
set "DRV_STATUSXML=%HME%\Drive_Status.xml"

:: 1. Run the actual surface scan (The Worker)
:: %SURFACE_SCAN% %DRV_LETTER% PERCENT TEMPPATH REPORTPATH DRIVE_STATUSXML
%SURFACE_SCAN% %DRV_LETTER% %PERCENTAGE% %TEMPPATH% %REPORTPATH% %DRV_STATUSXML%

:: 2. Capture the Peak Temperature (The Scout)
:: --- Refresh Device Info ---
if exist "%HME%\bin\deviceinfo.exe" (
    pushd "%HME%\bin"
    deviceinfo.exe %DRV_LETTER% "%STATUS_XML%" >nul
    popd
)



:: 3. Generate the Visual Report (The Manager)
call %SCRIPTS%\pshell generate_report.ps1 %DRV%