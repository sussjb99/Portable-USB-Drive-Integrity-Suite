# ============================================================
# Portable Drive Baby Sitter - Integrity Suite
# File: create_baselineXML.ps1
# Author: sussjb99
# Version: 1.0
# Last Modified: <2026-04-12>
# Copyright (c) 2026 sussjb99. All rights reserved.
# Licensed under the MIT License. See LICENSE.txt for details.
# ============================================================

param ([string]$DriveLetter)
$ErrorActionPreference = "Stop"

# --- 1. Path Setup ---
if ([string]::IsNullOrWhiteSpace($DriveLetter)) { exit 1 }

$JustDrive = $DriveLetter.Substring(0,1) + ":"
$CleanDrive = $JustDrive + "\"
$ExcludeToken = "integrity_check"

$Bin          = "$CleanDrive$ExcludeToken\bin"
$Logs         = "$CleanDrive$ExcludeToken\logs"
$FileGen      = "$Bin\FileListGen.exe"
$HashDeep     = "$Bin\hashdeep64.exe"
$Baseline     = "$Logs\baseline.xml"
$AuditList    = "$Logs\baseline_files.txt"

# Force UTF-8 for tool communication
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ensure Logs directory exists
if (-not (Test-Path $Logs)) { New-Item -Path $Logs -ItemType Directory -Force | Out-Null }

# --- 2. Inventory Drive (C++ Accelerated - Standard Paths) ---
Write-Host "Step 1: Inventorying $CleanDrive (Standard Paths)..." -ForegroundColor Cyan

& $FileGen "$CleanDrive" "$AuditList"

# --- 2.5 Logic Check ---
if (-not (Test-Path $AuditList)) { Write-Host "Error: FileListGen failed."; exit 4 }
$FileCount = (Get-Content $AuditList).Count

# --- 3. Generate Master Baseline XML ---
# Since the .bat file handled the estimate and confirmation, we start immediately.
Write-Host "Step 2: Hashing $FileCount files..." -ForegroundColor Yellow

# Use the list to generate the XML
# TRYING ANOTHER OUTPUT FORMAT METHOD & $HashDeep -c md5 -l -d -f "$AuditList" | Out-File -FilePath "$Baseline" -Encoding utf8
# & $HashDeep -c md5 -l -d -f "$AuditList" | Set-Content -Path "$Baseline" -Encoding utf8
# & $HashDeep -c md5 -l -d -j 1 -f "$AuditList" | Set-Content "$Baseline" -Encoding utf8
& $HashDeep -c md5 -l -d -f "$AuditList" | Set-Content -Path "$Baseline" -Encoding utf8



# --- 4. Cleanup ---
# if (Test-Path $AuditList) { Remove-Item $AuditList -Force }

if (Test-Path $Baseline) {
    Write-Host "`nSuccess! Master Baseline created at: $Baseline" -ForegroundColor Green
}