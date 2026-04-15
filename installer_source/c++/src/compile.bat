:: ============================================================
:: Portable Drive Baby Sitter - Integrity Suite
:: File: compile.bat
:: Author: sussjb99
:: Version: 1.1
:: Last Modified: 2026-04-14
:: Copyright (c) 2026 sussjb99
:: Licensed under the MIT License. See LICENSE.txt for details.
:: ============================================================

@echo off
echo ============================================
echo Compiling Source Code + Resource Metadata
echo ============================================
echo.

:: ---- baselineXML_estimate ----
echo [1/7] baselineXML_estimate
rc baselineXML_estimate.rc
cl /EHsc baselineXML_estimate.cpp baselineXML_estimate.res /Fe:baselineXML_estimate.exe

:: ---- corruptor ----
echo [2/7] corruptor
rc corruptor.rc
cl /EHsc corruptor.cpp corruptor.res /Fe:corruptor.exe

:: ---- deviceinfo ----
echo [3/7] deviceinfo
rc deviceinfo.rc
cl /EHsc deviceinfo.cpp deviceinfo.res /Fe:deviceinfo.exe

:: ---- full_probe ----
echo [4/7] full_probe
rc full_probe.rc
cl /EHsc full_probe.cpp full_probe.res /Fe:full_probe.exe

:: ---- FileListGen ----
echo [5/7] FileListGen
rc FileListGen.rc
cl /EHsc FileListGen.cpp FileListGen.res /Fe:FileListGen.exe

:: ---- scantime_estimate ----
echo [6/7] scantime_estimate
rc scantime_estimate.rc
cl /EHsc scantime_estimate.cpp scantime_estimate.res /Fe:scantime_estimate.exe

:: ---- surface_scan ----
echo [7/7] surface_scan
rc surface_scan.rc
cl /EHsc surface_scan.cpp surface_scan.res /Fe:surface_scan.exe

echo.
echo ============================================
echo Build Complete!
echo ============================================
pause