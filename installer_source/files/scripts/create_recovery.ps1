# ============================================================
# Portable Drive Baby Sitter - Integrity Suite
# File: create_recovery.ps1
# Author: sussjb99
# Version: 1.0
# Last Modified: <2026-04-12>
# Copyright (c) 2026 sussjb99. All rights reserved.
# Licensed under the MIT License. See LICENSE.txt for details.
# ============================================================



param(
    [Parameter(Mandatory=$true)]
    [string]$Drive
)

# 1. Setup
$Letter = $Drive.Replace(":", "").Replace("\", "").ToUpper()
$BasePath = "$($Letter):\"
$LogDir = Join-Path $BasePath "integrity_check\logs"
$Par2Exe = Join-Path $BasePath "integrity_check\bin\par2.exe"
$XmlPath = Join-Path $LogDir "baseline.xml"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# SAFETY CHECK: Protect System Drive
if ($Letter -eq "C") {
    Write-Host "CRITICAL: Operations on C: are prohibited." -ForegroundColor Red
    exit 1
}

# 2. THE SIMPLIFIED DOS DELETE
Write-Host "--- Step 1: DOS Cleanup (*.par2 and *.txt) ---" -ForegroundColor Cyan
# Clean up both par2 and old split text files to ensure a fresh start
cmd /c "del /F /Q `"$LogDir\*.par2`""
cmd /c "del /F /Q `"$LogDir\files_part*.txt`""

# 3. VERIFICATION WAIT
Write-Host "Waiting for disk to commit changes..." -NoNewline -ForegroundColor Yellow
$timeout = 10
$elapsed = 0
while ($elapsed -lt $timeout) {
    $remaining = Get-ChildItem -Path $LogDir -Filter "*.par2"
    if (-not $remaining) {
        Write-Host " Success. Path is clear." -ForegroundColor Green
        break
    }
    Write-Host "." -NoNewline -ForegroundColor White
    Start-Sleep -Seconds 1
    $elapsed++
}

if ($elapsed -ge $timeout) {
    Write-Host "`nERROR: Files still exist. Please close any open 'logs' folders." -ForegroundColor Red
    return
}

# 4. Extract Filenames and Chunking
Write-Host "`n--- Step 2: Extracting and Chunking File List ---" -ForegroundColor Cyan
try {
    [xml]$xmlData = Get-Content $XmlPath
    $fileList = $xmlData.dfxml.fileobject.filename
    $totalFiles = $fileList.Count
    $chunkSize = 25000
    
    # Create an array of arrays (chunks)
    $chunks = @()
    for ($i = 0; $i -lt $totalFiles; $i += $chunkSize) {
        $endIndex = [Math]::Min($i + $chunkSize - 1, $totalFiles - 1)
        $chunks += ,($fileList[$i..$endIndex])
    }
    Write-Host "Total Files: $totalFiles. Split into $($chunks.Count) sets (Max $chunkSize per set)." -ForegroundColor Yellow
}
catch {
    Write-Host "Failed to read baseline.xml: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# 5. Create PAR2 (Sequential Execution)
Write-Host "`n--- Step 3: Running Turbo PAR2 Sequentially ---" -ForegroundColor Cyan
$oldLoc = Get-Location
Set-Location $BasePath

$chunkIndex = 1
foreach ($chunk in $chunks) {
    # Define paths for this specific chunk
    $currentOutPath = Join-Path $LogDir "files_part$chunkIndex.txt"
    $currentRecoveryPath = Join-Path $LogDir "recovery_data_part$chunkIndex.par2"

    Write-Host "`n>>> Processing Part $chunkIndex ($($chunk.Count) files) <<<" -ForegroundColor Magenta
    
    # Write current chunk to its own file list
    [System.IO.File]::WriteAllLines($currentOutPath, $chunk, $Utf8NoBom)

    # Prepare Arguments
    $BaseArg = "-B." 
    $BlockSize = "-s1048576" 
    $par2Args = @(
        "c",
        "-t8",
        "-m2048",
        $BaseArg,
        $BlockSize,
        $currentRecoveryPath,
        "@$currentOutPath"
    )

    Write-Host "Executing PAR2 for Part $chunkIndex..." -ForegroundColor Gray
    & $Par2Exe @par2Args

    $chunkIndex++
}

Set-Location $oldLoc
Write-Host "`nAll Parts Complete!" -ForegroundColor Green