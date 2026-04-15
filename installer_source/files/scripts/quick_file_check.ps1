# ============================================================
# Portable Drive Baby Sitter - Integrity Suite
# File: quick_file_check.ps1
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
$Par2Exe      = "$Bin\par2.exe"
$Baseline     = "$Logs\baseline.xml"
$Current      = "$Logs\current_check.xml"
$AuditList    = "$Logs\quick_check_files.txt"
$RepairList   = "$Logs\repair_list.txt"
#$OutPath      = "$Logs\files.txt"
$OutPath      = "$Logs\baseline_files.txt"
$StatusFile   = "$CleanDrive$ExcludeToken\Drive_Status.xml"

# Force encoding for tool communication
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 2. Generate Current Scan ---
Write-Host "Step 1: Inventorying Drive..." -ForegroundColor Cyan

if (-not (Test-Path $Logs)) { New-Item -Path $Logs -ItemType Directory -Force | Out-Null }

# Use FileListGen with standard paths
& $FileGen "$CleanDrive" "$AuditList"

if (-not (Test-Path $AuditList)) { Write-Host "Error: FileListGen failed."; exit 4 }
$FileCount = (Get-Content $AuditList).Count

# Step 2 UI Update
Write-Host "Step 2: Hashing $FileCount files..." -ForegroundColor Yellow
Write-Host "      [Scanning hardware; please wait...]" -ForegroundColor Gray
Push-Location $CleanDrive

# Generate the current XML using standard paths (using md5 to match baseline)
#6 threads  & $HashDeep -c md5 -l -d -f "$AuditList" | Out-File -FilePath "$Current" -Encoding utf8
& $HashDeep -c md5 -l -d -f "$AuditList" | Set-Content -Path "$Current" -Encoding utf8

Pop-Location

if (Test-Path $AuditList) { Remove-Item $AuditList -Force }

# --- 3. Comparison Logic with In-Line Progress ---
function Get-FileInventory($Path) {
    $Inventory = @{}
    if (-not (Test-Path $Path)) { return $Inventory }
    
    $FileName = Split-Path $Path -Leaf
    Write-Host "Parsing $FileName... " -NoNewline -ForegroundColor Gray
    [xml]$xml = Get-Content $Path -Raw -Encoding UTF8
    
    $nodes = $xml.dfxml.fileobject
    if ($null -eq $nodes) { return $Inventory }
    $totalNodes = $nodes.Count
    $n = 0

    foreach ($node in $nodes) {
        $n++
        if ($n % 100 -eq 0 -or $n -eq $totalNodes) { 
            $pct = [int](($n / $totalNodes) * 100)
            Write-Host "`rParsing $FileName... $pct% " -NoNewline -ForegroundColor Gray
        }
        if ($null -eq $node.filename) { continue }
        
        $p = ($node.filename -replace '^[a-zA-Z]:', '' -replace '^\.\\','').Replace('\','/').ToLower()
        $Inventory[$p] = $node
    }
    Write-Host "" 
    return $Inventory
}

$bFiles = Get-FileInventory $Baseline
$cFiles = Get-FileInventory $Current

$newList = @(); $modList = @(); $delList = @(); $corList = @()

Write-Host "Step 3: Comparing Inventories..." -ForegroundColor Cyan
$totalToCompare = $cFiles.Count
$currentIdx = 0

foreach ($key in $cFiles.Keys) {
    $currentIdx++
    if ($currentIdx % 50 -eq 0 -or $currentIdx -eq $totalToCompare) {
        $pct = [int](($currentIdx / $totalToCompare) * 100)
        Write-Host "`r      Progress: $pct% ($currentIdx/$totalToCompare)" -NoNewline -ForegroundColor Cyan
    }

    if (-not $bFiles.ContainsKey($key)) {
        $newList += $cFiles[$key].filename
        continue
    }

    $old = $bFiles[$key]
    $new = $cFiles[$key]
    
    # Updated hash check to use MD5 to match your current baseline system
    $oldHash = ($old.hashdigest | Where-Object { $_.type -eq 'md5' }).'#text'
    $newHash = ($new.hashdigest | Where-Object { $_.type -eq 'md5' }).'#text'

    if ($oldHash -and $newHash -and ($oldHash.ToLower() -ne $newHash.ToLower())) {
        $oldTime = [DateTime]::Parse($old.mtime).ToUniversalTime()
        $newTime = [DateTime]::Parse($new.mtime).ToUniversalTime()
        if ([Math]::Abs(($newTime - $oldTime).TotalSeconds) -lt 2.1) {
            $corList += $new.filename
        } else {
            $modList += $new.filename
        }
    }
    $bFiles.Remove($key)
}
Write-Host "" 

foreach ($key in $bFiles.Keys) { $delList += $bFiles[$key].filename }

# --- 4. Ordered Display ---
Write-Host "`n--- DISCREPANCIES FOUND ---" -ForegroundColor White
if ($newList.Count -eq 0 -and $modList.Count -eq 0 -and $delList.Count -eq 0 -and $corList.Count -eq 0) {
    Write-Host "None." -ForegroundColor Gray
}
foreach ($item in $newList) { Write-Host "[NEW]      $item" -ForegroundColor Cyan }
foreach ($item in $modList) { Write-Host "[MODIFIED] $item" -ForegroundColor Yellow }
foreach ($item in $delList) { Write-Host "[DELETED]  $item" -ForegroundColor Magenta }
foreach ($item in $corList) { Write-Host "[CORRUPT]  $item" -ForegroundColor Red }

Write-Host "`n----------------------------------------"
Write-Host "Results: New=$($newList.Count), Mod=$($modList.Count), Del=$($delList.Count), CORRUPT=$($corList.Count)"
Write-Host "----------------------------------------"

# --- 5. XML Status Update Logic ---
$timestamp = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if (Test-Path $StatusFile) {
    [xml]$statusXml = Get-Content $StatusFile
} else {
    [xml]$statusXml = "<DriveBabySitter></DriveBabySitter>"
}

function Set-XmlValue($ParentNode, $ElementName, $Value) {
    $node = $ParentNode.SelectSingleNode($ElementName)
    if ($null -eq $node) {
        $node = $statusXml.CreateElement($ElementName)
        $ParentNode.AppendChild($node) | Out-Null
    }
    $node.InnerText = [string]$Value
}

$root = $statusXml.DocumentElement
foreach ($section in @("SmartHealthStatus", "FileIntegrityScan", "SurfaceScanInfo")) {
    if ($null -eq $root.SelectSingleNode($section)) {
        $root.AppendChild($statusXml.CreateElement($section)) | Out-Null
    }
}

Set-XmlValue ($root.SelectSingleNode("SmartHealthStatus")) "LastScanDate" $timestamp
Set-XmlValue ($root.SelectSingleNode("SmartHealthStatus")) "HealthStatus" $(if ($null -ne $root.HardwareVitals) { $root.HardwareVitals.HealthRating } else { "PASSED" })

$file = $root.SelectSingleNode("FileIntegrityScan")
Set-XmlValue $file "LastScanDate" $timestamp
Set-XmlValue $file "FilesChecked" "$($cFiles.Count)"
Set-XmlValue $file "CorruptFiles" "$($corList.Count)"
Set-XmlValue $file "IntegrityGrade" $(if ($corList.Count -gt 0) { "Low" } else { "High" })

$surf = $root.SelectSingleNode("SurfaceScanInfo")
Set-XmlValue $surf "LastScanDate" $timestamp
Set-XmlValue $surf "SurfaceGrade" $(if ($corList.Count -gt 0) { "Caution" } else { "Healthy" })

# --- 6. Intelligent Split-Parity Repair ---
if ($corList.Count -gt 0) {
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($RepairList, $corList, $Utf8NoBom)

    Write-Host "`nWARNING: Silent corruption detected." -ForegroundColor Red
    if ((Read-Host "Start repair using multi-part parity sets? (Y/N)") -ieq 'Y') {
        
        if (-not (Test-Path $OutPath)) {
            Write-Host "ERROR: $OutPath missing. Cannot calculate part numbers." -ForegroundColor Red
            return
        }

        Write-Host "Loading master file index..." -ForegroundColor Gray
        $masterList = Get-Content $OutPath
        $oldLoc = Get-Location
        Set-Location $CleanDrive

        foreach ($corruptFile in $corList) {
            # Determine the part number mathematically (Chunk Size = 25000)
            $index = [array]::IndexOf($masterList, $corruptFile)
            
            if ($index -ge 0) {
                $partNum = [Math]::Floor($index / 25000) + 1
                $currentParSet = Join-Path $Logs "recovery_data_part$($partNum).par2"

                if (Test-Path $currentParSet) {
                    Write-Host "Repairing $corruptFile using Part $partNum..." -ForegroundColor Green
                    # We create a temporary single-line repair list for this specific file
                    $tempList = Join-Path $Logs "temp_r.txt"
                    [System.IO.File]::WriteAllLines($tempList, @($corruptFile), $Utf8NoBom)
                    
                    & $Par2Exe r -B . "$currentParSet" "@$tempList"
                    
                    if (Test-Path $tempList) { Remove-Item $tempList -Force }
                } else {
                    Write-Host "ERROR: Parity set $currentParSet not found." -ForegroundColor Red
                }
            } else {
                Write-Host "ERROR: $corruptFile not found in master index." -ForegroundColor Red
            }
        }
        Set-Location $oldLoc
    }
} else {
    Write-Host "`nNo silent corruption detected." -ForegroundColor Green
}

$statusXml.Save($StatusFile)
Write-Host "Drive_Status.xml synchronized successfully." -ForegroundColor Gray