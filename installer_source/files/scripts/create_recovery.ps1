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
$OutPath = Join-Path $LogDir "files.txt"
$RecoveryPath = Join-Path $LogDir "recovery_data.par2"

# SAFETY CHECK: Protect System Drive
if ($Letter -eq "C") {
    Write-Host "CRITICAL: Operations on C: are prohibited." -ForegroundColor Red
    exit 1
}

# 2. THE SIMPLIFIED DOS DELETE
Write-Host "--- Step 1: DOS Cleanup (*.par2) ---" -ForegroundColor Cyan
Write-Host "Executing: del /F /Q $LogDir\*.par2" -ForegroundColor Gray

# Using your exact suggested syntax for maximum reliability
cmd /c "del /F /Q `"$LogDir\*.par2`""

# 3. VERIFICATION WAIT (Essential for FAT32 Sync)
Write-Host "Waiting for disk to commit changes..." -NoNewline -ForegroundColor Yellow
$timeout = 10
$elapsed = 0
while ($elapsed -lt $timeout) {
    # We check the folder one last time to be sure
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

# 4. Extract Filenames
Write-Host "`n--- Step 2: Creating File List ---" -ForegroundColor Cyan
try {
    [xml]$xmlData = Get-Content $XmlPath
    $fileList = $xmlData.dfxml.fileobject.filename
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($OutPath, $fileList, $Utf8NoBom)
}
catch {
    Write-Host "Failed to read baseline.xml: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# 5. Create PAR2
Write-Host "`n--- Step 3: Running Turbo PAR2 (2-Minute Rebuild) ---" -ForegroundColor Cyan
$oldLoc = Get-Location

# Switch to the drive root so "." refers to the root
Set-Location $BasePath

# 1. We use "." for the BasePath. This is the "magic bullet" for root drives.
# 2. We change "-B1M" to "-s" for block size. 
#    Note: "-s" expects bytes. 1MB = 1048576.
$BaseArg = "-B." 
$BlockSize = "-s1048576" 

$par2Args = @(
    "c",
    "-t8",
    "-m2048",
    $BaseArg,
    $BlockSize,    # Corrected from -B1M
    $RecoveryPath,
    "@$OutPath"
)

Write-Host "ARGS:" ($par2Args -join " ")
& $Par2Exe @par2Args

Set-Location $oldLoc
Write-Host "`nProcess Complete!" -ForegroundColor Green