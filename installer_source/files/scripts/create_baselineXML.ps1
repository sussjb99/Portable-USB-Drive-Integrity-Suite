param ([string]$DriveLetter)
$ErrorActionPreference = "Stop"

# --- 1. Validation ---
if ([string]::IsNullOrWhiteSpace($DriveLetter)) { exit 1 }
if ($DriveLetter -notmatch ":$") { $DriveLetter += ":" }
$CleanDrive = $DriveLetter.Substring(0,2) + "\"

$ExcludeToken = "integrity_check"
$HashDeep     = "$($CleanDrive)$ExcludeToken\bin\hashdeep64.exe"
$OutFile      = "$($CleanDrive)$ExcludeToken\logs\baseline.xml"
$AuditList    = "$($CleanDrive)$ExcludeToken\logs\baseline_files.txt"

# Clear existing baseline and file list to ensure no stale data remains
if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
if (Test-Path $AuditList) { Remove-Item $AuditList -Force }


Write-Host "Generating fresh baseline for $CleanDrive..." -ForegroundColor Cyan

# --- 2. Gather Files (Excluding System Junk) ---
# This ensures test5.txt (and others) are included, but System Volume is NOT.
$Files = Get-ChildItem -Path $CleanDrive -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch "System Volume Information" -and 
    $_.FullName -notmatch "\`$RECYCLE\.BIN" -and 
    $_.FullName -notmatch $ExcludeToken
}

if ($Files.Count -eq 0) { Write-Host "No files found."; exit 4 }

# --- 3. Save List as ASCII (Crucial for HashDeep) ---
$Files.FullName | Out-File -FilePath $AuditList -Encoding ascii

# --- 4. Run HashDeep (Single Pass, No Fragments) ---
Write-Host "Hashing $($Files.Count) files..." -ForegroundColor Yellow
cmd /c "cd /d $CleanDrive && `"$HashDeep`" -c sha256 -l -d -f `"$AuditList`" > `"$OutFile`""

# --- 5. Cleanup ---
if (Test-Path $AuditList) { Remove-Item $AuditList -Force }

if (Test-Path $OutFile) {
    Write-Host "Success! Clean Baseline created at $OutFile" -ForegroundColor Green
}