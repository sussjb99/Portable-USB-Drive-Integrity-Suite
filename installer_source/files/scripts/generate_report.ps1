# ============================================================
# Portable Drive Baby Sitter - Integrity Suite
# File: generate_report.ps1
# Author: sussjb99
# Version: 1.0
# Last Modified: <2026-04-12>
# Copyright (c) 2026 sussjb99. All rights reserved.
# Licensed under the MIT License. See LICENSE.txt for details.
# ============================================================


param ([string]$DriveLetter)

# --- 1. Path Setup ---
$JustDrive = $DriveLetter.Substring(0,1).ToUpper() + ":"
$CleanDrive = $JustDrive + "\"
$RootPath   = Join-Path $CleanDrive "Integrity_Check"
$StatusFile = Join-Path $RootPath "Drive_Status.xml"
$ReportDir  = Join-Path $RootPath "reports"

if (!(Test-Path $ReportDir)) { New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$displayTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ReportFile = Join-Path $ReportDir "REPORT_$($timestamp).html"

# --- 2. Load Data ---
if (!(Test-Path $StatusFile)) { exit 1 }
[xml]$xml = Get-Content $StatusFile
$Root = $xml.DriveBabySitter

# --- 3. Extract Data ---
$Model  = $Root.HardwareIdentity.Model
$Serial = $Root.HardwareIdentity.Serial
$FS     = $Root.HardwareIdentity.FileSystem
$Tech   = $Root.HardwareIdentity.Technology
$Total  = $Root.StorageCapacity.TotalGB
$Used   = $Root.StorageCapacity.UsedGB
$Free   = $Root.StorageCapacity.FreeGB
$SmartStatus = $Root.SmartHealthStatus.SmartStatus
$CurrentTemp = $Root.HardwareVitals.Temperature
$F_Grade = $Root.FileIntegrityScan.IntegrityGrade
$S_Grade = $Root.SurfaceScanInfo.SurfaceGrade
$S_Stab  = $Root.SurfaceScanInfo.StabilityScore
$S_Speed = $Root.SurfaceScanInfo.AvgReadSpeed
$S_Cov   = $Root.SurfaceScanInfo.ScanCoverage
$Errors  = $Root.SurfaceScanInfo.ErrorsDetected

# --- 4. Logic & Pro Coloring ---
if ([string]::IsNullOrEmpty($SmartStatus)) { $SmartStatus = "N/A" }
if ([string]::IsNullOrEmpty($CurrentTemp)) { $CurrentTemp = "N/A" }

$Green = "#28a745"; $Red = "#dc3545"; $Amber = "#e6a800"; $Blue = "#0056b3"

$GlobalStatus = "HEALTHY"; $GlobalColor = $Green
if ($S_Grade -eq "Degraded" -or $SmartStatus -eq "FAILING" -or ([int]$Errors -gt 0) -or $F_Grade -eq "Critical") {
    $GlobalStatus = "CAUTION"; $GlobalColor = $Red
}

$TempColor = "#444"
if ($CurrentTemp -ne "N/A") {
    if ([double]$CurrentTemp -ge 60) { $TempColor = $Red }
    elseif ([double]$CurrentTemp -ge 55) { $TempColor = $Amber }
}

# --- 5. Build HTML ---
$html = @"
<!DOCTYPE html>
<html>
<head>
<style>
    body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #e9ecef; padding: 25px; color: #333; margin: 0; }
    .container { max-width: 750px; margin: auto; background: white; border: 1px solid #dee2e6; border-radius: 4px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
    
    .verdict-header { background: $GlobalColor; color: white; padding: 12px 20px; display: flex; justify-content: space-between; align-items: center; }
    .verdict-title { font-size: 1.2em; font-weight: 900; letter-spacing: 1px; }
    
    /* Identity Module - Labels Bold, Values Normal */
    .identity-bar { background: #f8f9fa; padding: 15px 20px; border-bottom: 1px solid #dee2e6; }
    .id-row { display: flex; margin-bottom: 4px; font-size: 0.9em; }
    .id-row:last-child { margin-bottom: 0; }
    .id-label { width: 140px; color: #666; text-transform: uppercase; font-size: 0.8em; font-weight: bold; letter-spacing: 0.5px; }
    .id-value { color: #333; font-weight: normal; } 

    /* Vitals Strip - Labels Bold, Values Normal & Same Font */
    .vitals-strip { display: flex; border-bottom: 1px solid #dee2e6; background: #fff; }
    .vital-item { flex: 1; padding: 12px 20px; border-right: 1px solid #f0f0f0; }
    .vital-item:last-child { border-right: none; }
    .v-lab { display: block; font-size: 0.7em; text-transform: uppercase; color: #999; font-weight: bold; margin-bottom: 3px; }
    .v-val { font-size: 1em; font-weight: normal; color: #222; } 

    .content-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1px; background: #dee2e6; border-bottom: 1px solid #dee2e6; }
    .content-box { background: white; padding: 20px; }
    .section-title { font-size: 0.75em; font-weight: bold; color: $Blue; text-transform: uppercase; margin-bottom: 15px; border-bottom: 1px solid #f0f0f0; padding-bottom: 5px; }

    /* Data Rows - Labels Bold, Values Normal */
    .data-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 0.85em; }
    .d-lab { color: #777; font-weight: bold; }
    .d-val { font-weight: normal; } 

    .footer { padding: 10px 20px; background: #f8f9fa; color: #aaa; font-size: 0.75em; display: flex; justify-content: space-between; }
</style>
</head>
<body>
<div class='container'>
    <div class='verdict-header'>
        <span class='verdict-title'>DRIVE STATUS: $GlobalStatus</span>
        <span style='font-size: 0.8em; opacity: 0.9;'>$displayTime</span>
    </div>

    <div class='identity-bar'>
        <div class='id-row'>
            <span class='id-label'>Serial Number</span>
            <span class='id-value'>$Serial</span>
        </div>
        <div class='id-row'>
            <span class='id-label'>Device Model</span>
            <span class='id-value'>$Model</span>
        </div>
    </div>

    <div class='vitals-strip'>
        <div class='vital-item'>
            <span class='v-lab'>File Integrity</span>
            <span class='v-val'>$F_Grade</span>
        </div>
        <div class='vital-item'>
            <span class='v-lab'>Peak Temperature</span>
            <span class='v-val' style='color:$TempColor;'>$CurrentTemp C</span>
        </div>
        <div class='vital-item'>
            <span class='v-lab'>S.M.A.R.T. Health</span>
            <span class='v-val'>$SmartStatus</span>
        </div>
    </div>

    <div class='content-grid'>
        <div class='content-box'>
            <div class='section-title'>Surface Analysis</div>
            <div class='data-row'><span class='d-lab'>Technical Grade</span><span class='d-val'>$S_Grade</span></div>
            <div class='data-row'><span class='d-lab'>Read Stability</span><span class='d-val'>$S_Stab %</span></div>
            <div class='data-row'><span class='d-lab'>Average Speed</span><span class='d-val'>$S_Speed MB/s</span></div>
            <div class='data-row'><span class='d-lab'>Scan Coverage</span><span class='d-val'>$S_Cov %</span></div>
            <div class='data-row' style='margin-top:10px; color:$Red;'><span class='d-lab'>Total Errors</span><span class='d-val'>$Errors</span></div>
        </div>
        <div class='content-box'>
            <div class='section-title'>Storage & Format</div>
            <div class='data-row'><span class='d-lab'>Mount Point</span><span class='d-val'>$JustDrive</span></div>
            <div class='data-row'><span class='d-lab'>File System</span><span class='d-val'>$FS ($Tech)</span></div>
            <div class='data-row'><span class='d-lab'>Total Capacity</span><span class='d-val'>$Total GB</span></div>
            <div class='data-row'><span class='d-lab'>Used Space</span><span class='d-val'>$Used GB</span></div>
            <div class='data-row'><span class='d-lab'>Free Space</span><span class='d-val'>$Free GB</span></div>
        </div>
    </div>

    <div class='footer'>
        <span>Drive Baby Sitter v2.1</span>
        <span>Integrity Check Complete</span>
    </div>
</div>
</body>
</html>
"@

if ($ReportFile) {
    $html | Out-File -FilePath $ReportFile -Encoding utf8 -Force
    Write-Host "Engineering Report Generated: $ReportFile" -ForegroundColor Green
}