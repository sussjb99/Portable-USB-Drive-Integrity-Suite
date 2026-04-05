@echo off

mode con cols=64 lines=42
setlocal enabledelayedexpansion
title Drive Baby Sitter - Integrity Suite
color 0F

:: 1. Setup Configuration
set "DRV=%~d0"
set "DRV_LETTER=%DRV:~0,1%"
set "HME=%DRV%\integrity_check"
set "SCRIPTS=%HME%\scripts"
set "STATUS_XML=%HME%\Drive_Status.xml"
set "BSL=%HME%\logs\baseline.xml"

:: --- UPDATED Launch Device Info ---
if exist "%HME%\bin\deviceinfo.exe" (
    echo [Status] Gathering hardware details...
    pushd "%HME%\bin"
    deviceinfo.exe %DRV_LETTER% "%STATUS_XML%"
    popd
)

:LOAD_DATA
:: Reset variables before parsing to ensure fresh data
set "MODEL=Unknown" & set "SERIAL=Unknown" & set "FS_TYPE=Unknown" & set "TECH=Unknown"
set "TOTAL_GB=N/A" & set "USED_GB=N/A" & set "FREE_GB=N/A"
set "SMART_STATUS=Unknown" & set "PROBE_DATE=Never"
set "F_HEALTH=Unscanned" & set "F_DATE=Never"
set "S_HEALTH=Unscanned" & set "S_DATE=Never"
set "S_STAB=--" & set "S_SPEED=--" & set "S_COV=--"

if exist "%STATUS_XML%" (
    :: 2. Parse Identity & Metadata
    for /f "tokens=3 delims=><" %%a in ('findstr "<Model>" "%STATUS_XML%"') do set "MODEL=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<Serial>" "%STATUS_XML%"') do set "SERIAL=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<FileSystem>" "%STATUS_XML%"') do set "FS_TYPE=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<Technology>" "%STATUS_XML%"') do set "TECH=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<LastHardwareProbe>" "%STATUS_XML%"') do set "PROBE_DATE=%%a"

    :: 3. Parse Capacity
    for /f "tokens=3 delims=><" %%a in ('findstr "<TotalGB>" "%STATUS_XML%"') do set "TOTAL_GB=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<UsedGB>" "%STATUS_XML%"') do set "USED_GB=%%a"
    for /f "tokens=3 delims=><" %%a in ('findstr "<FreeGB>" "%STATUS_XML%"') do set "FREE_GB=%%a"

    :: 4. Parse Health Sections (Block Aware)
    set "inBlock="
    for /f "tokens=2,3 delims=><" %%a in ('type "%STATUS_XML%"') do (
        if "%%a"=="SmartHealthStatus" set "inBlock=SMART"
        if "%%a"=="FileIntegrityScan" set "inBlock=FILE"
        if "%%a"=="SurfaceScanInfo" set "inBlock=SURF"
        if "%%a"=="DriveBabySitter" set "inBlock="
        
        if "!inBlock!"=="SMART" (
            if "%%a"=="SmartStatus" set "SMART_STATUS=%%b"
        )
        if "!inBlock!"=="FILE" (
            if "%%a"=="IntegrityGrade" set "F_HEALTH=%%b"
            if "%%a"=="LastScanDate" set "F_DATE=%%b"
        )
        if "!inBlock!"=="SURF" (
            if "%%a"=="SurfaceGrade" set "S_HEALTH=%%b"
            if "%%a"=="SurfaceScanDate" set "S_DATE=%%b"
            if "%%a"=="StabilityScore" set "S_STAB=%%b"
            if "%%a"=="AvgReadSpeed" set "S_SPEED=%%b"
            if "%%a"=="ScanCoverage" set "S_COV=%%b"
        )
    )
)

:: --- Timestamp Normalization (Force HH:MM:SS) ---
if not "!PROBE_DATE!"=="Never" if "!PROBE_DATE:~16,1!"=="" set "PROBE_DATE=!PROBE_DATE!:00"
if not "!F_DATE!"=="Never"      if "!F_DATE:~16,1!"==""      set "F_DATE=!F_DATE!:00"
if not "!S_DATE!"=="Never"      if "!S_DATE:~16,1!"==""      set "S_DATE=!S_DATE!:00"

:: --- Calculate "Last Updated" Global Timestamp ---
set "LAST_UPDATE=%PROBE_DATE%"
if "!F_DATE!" GTR "!LAST_UPDATE!" set "LAST_UPDATE=!F_DATE!"
if "!S_DATE!" GTR "!LAST_UPDATE!" set "LAST_UPDATE=!S_DATE!"
if "!LAST_UPDATE!"=="Never" set "LAST_UPDATE=No Data Available"

:MENU
cls
echo   ============================================================
echo                 DRIVE BABY SITTER - INTEGRITY SUITE
echo                 UPDATED: %LAST_UPDATE%
echo   ============================================================
echo    DEVICE            : %MODEL%
echo    SERIAL            : %SERIAL%
echo    MOUNTED           : [%DRV%]
echo    FILESYSTEM        : %FS_TYPE%
echo    TECHNOLOGY        : %TECH%
echo    SMARTHEALTH       : %SMART_STATUS%
echo.
echo    STORAGE CAPACITY
echo      Capacity: %TOTAL_GB% GB   Used: %USED_GB% GB   Free: %FREE_GB% GB
echo.
echo    FILE INTEGRITY (Bit-Rot Scan)
echo      Integrity       : %F_HEALTH%
echo      Checked At      : %F_DATE%
echo.
echo    SURFACE ANALYSIS (Performance Scan)
echo      Grade           : %S_HEALTH%
echo      Coverage        : %S_COV%%%
echo      Stability       : %S_STAB%%%
echo      Avg Rate        : %S_SPEED% MB/s
echo      Checked At      : %S_DATE%
echo   ============================================================
echo    TASKS -- FILE INTEGRITY
echo      [1] Scan for Bit Rot
echo      [2] Update File Baseline
echo      [3] Re-Generate Recovery Data
echo.
echo    TASKS -- SURFACE SCANS
echo      [4] Quick Surface Scan
echo      [5] Full Surface Scan (Sequential Read)
echo.
echo      [H] Help
echo      [E] Exit Suite
echo   ============================================================
echo.
set /p choice="	Select an option (1-5, H, E): "

set "DLTR=%DRV:~0,1%"

:: Safety Check
if /I "%DLTR%"=="C" (
    echo [Error] Operations on C: are strictly restricted.
    pause
    exit /b 1
)

if /I "%choice%"=="1" goto RUN_SCAN
if /I "%choice%"=="2" goto RUN_BASE
if /I "%choice%"=="3" goto RUN_RECOV
if /I "%choice%"=="4" goto PREP_QUICK_SURF
if /I "%choice%"=="5" goto PREP_FULL_SURF
if /I "%choice%"=="H" goto SHOW_HELP
if /I "%choice%"=="E" goto QUIT
goto MENU

:RUN_SCAN
if not exist "%BSL%" (
    echo.
    echo [Error] No baseline found. Run Option 2 first.
    pause
    goto MENU
)
call %SCRIPTS%\pshell quick_file_check.ps1 %DLTR%
pause
goto LOAD_DATA

:RUN_BASE
call %SCRIPTS%\pshell create_baselineXML.ps1 %DLTR%
pause
goto LOAD_DATA

:RUN_RECOV
call %SCRIPTS%\pshell create_recovery.ps1 %DLTR%
pause
goto LOAD_DATA

:PREP_QUICK_SURF
cls
echo ============================================================
echo                   QUICK SURFACE SCAN PREPARATION               
echo ============================================================
echo [Status] Benchmarking %DLTR%: (1%% Random Sample)...
echo.
"%HME%\bin\scantime_estimate.exe" %DLTR% 1 0
echo.
set /p proceed="Proceed with Quick Scan? (Y/N): "
if /I "%proceed%" NEQ "Y" goto MENU

echo 	[Status] Launching Quick Surface Scan...
if exist "%SCRIPTS%\quick_surface_scan.bat" (
    call "%SCRIPTS%\quick_surface_scan.bat" %DLTR%
) else (
    echo     [Error] quick_surface.bat missing in %SCRIPTS%
)
pause
goto LOAD_DATA

:PREP_FULL_SURF
cls
echo ============================================================
echo                    FULL SURFACE SCAN PREPARATION               
echo ============================================================
echo [Status] Benchmarking %DLTR%: (100%% Sequential Read)...
echo.
"%HME%\bin\scantime_estimate.exe" %DLTR% 100 0
echo.
set /p proceed="This is a total read. Proceed with Full Scan? (Y/N): "
if /I "%proceed%" NEQ "Y" goto MENU

echo [Status] Launching Full Surface Scan...
if exist "%SCRIPTS%\full_surface_scan.bat" (
    call "%SCRIPTS%\full_surface_scan.bat" %DLTR%
) else (
    echo [Error] full_surface.bat missing in %SCRIPTS%
)
pause
goto LOAD_DATA


:SHOW_HELP
cls
echo [Status] Opening Help Documentation...
call %SCRIPTS%\pshell pager.ps1 "%HME%\Readme.txt"
pause
goto MENU


:QUIT
echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul
if %errorlevel%==0 (
    echo.
    echo Exiting...
    timeout /t 2 >nul
    exit
) else (
    exit /b
)