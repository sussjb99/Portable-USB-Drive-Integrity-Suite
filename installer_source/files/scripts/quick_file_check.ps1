param ([string]$DriveLetter)
$ErrorActionPreference = "Stop"

# --- 1. Path Setup ---
if ([string]::IsNullOrWhiteSpace($DriveLetter)) { exit 1 }

$JustDrive = $DriveLetter.Substring(0,1) + ":"
$CleanDrive = $JustDrive + "\"
$ExcludeToken = "integrity_check"

$Bin          = "$CleanDrive$ExcludeToken\bin"
$Logs         = "$CleanDrive$ExcludeToken\logs"
$HashDeep     = "$Bin\hashdeep64.exe"
$Par2Exe      = "$Bin\par2.exe"
$Baseline     = "$Logs\baseline.xml"
$Current      = "$Logs\current_check.xml"
$AuditList    = "$Logs\quick_check_files.txt"
$RepairList   = "$Logs\repair_list.txt"
$Par2Set      = "$Logs\recovery_data.par2"
$StatusFile   = "$CleanDrive$ExcludeToken\Drive_Status.xml"

# --- 2. Generate Current Scan ---
Write-Host "Step 1: Inventorying Drive..." -ForegroundColor Cyan
$Files = Get-ChildItem -Path $CleanDrive -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch "System Volume Information" -and 
    $_.FullName -notmatch "\`$RECYCLE\.BIN" -and 
    $_.FullName -notmatch [regex]::Escape($ExcludeToken)
}

if (-not (Test-Path $Logs)) { New-Item -Path $Logs -ItemType Directory -Force | Out-Null }
$Files.FullName | Out-File -FilePath $AuditList -Encoding ascii

# Step 2 UI Update
Write-Host "Step 2: Hashing $($Files.Count) files..." -ForegroundColor Yellow
Write-Host "      [Scanning hardware; please wait...]" -ForegroundColor Gray
Push-Location $CleanDrive
# & $HashDeep -c sha256 -l -d -f "$AuditList" > "$Current"
# cmd /c "cd /d $CleanDrive && "$HashDeep" -c sha256 -l -d -f "$AuditList" > "$Current""
cmd /c "cd /d $CleanDrive && ""$HashDeep"" -c sha256 -l -d -f ""$AuditList"" > ""$Current"""

Pop-Location

if (Test-Path $AuditList) { Remove-Item $AuditList -Force }

# --- 3. Comparison Logic with In-Line Progress ---
function Get-FileInventory($Path) {
    $Inventory = @{}
    if (-not (Test-Path $Path)) { return $Inventory }
    
    $FileName = Split-Path $Path -Leaf
    Write-Host "Parsing $FileName... " -NoNewline -ForegroundColor Gray
    [xml]$xml = Get-Content $Path -Raw
    
    $nodes = $xml.dfxml.fileobject
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
    Write-Host "" # Move to next line
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
    $oldHash = ($old.hashdigest | Where-Object { $_.type -eq 'SHA256' }).'#text'
    $newHash = ($new.hashdigest | Where-Object { $_.type -eq 'SHA256' }).'#text'

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
Write-Host "" # Clear line

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

# Handle Repairs
if ($corList.Count -gt 0) {
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($RepairList, $corList, $Utf8NoBom)

    Write-Host "`nWARNING: Silent corruption detected." -ForegroundColor Red
    if ((Read-Host "Start repair using $Par2Set? (Y/N)") -ieq 'Y') {
        $oldLoc = Get-Location
        Set-Location $CleanDrive
        & $Par2Exe r -B . "$Par2Set" "@$RepairList"
        Set-Location $oldLoc
    }
} else {
    Write-Host "`nNo silent corruption detected." -ForegroundColor Green
}

$statusXml.Save($StatusFile)
Write-Host "Drive_Status.xml synchronized successfully." -ForegroundColor Gray