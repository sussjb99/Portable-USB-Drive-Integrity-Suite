param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [int]$PageSize = 30
)

# If the provided path doesn't exist, try resolving relative to script directory
if (-not (Test-Path $Path)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Resolved = Join-Path $ScriptDir $Path

    if (Test-Path $Resolved) {
        $Path = $Resolved
    }
}

# Validate file
if (-not (Test-Path $Path)) {
    Write-Host "ERROR: File not found: $Path"
    Read-Host "Press Enter to return"
    exit
}

$lines = Get-Content $Path

if (-not $lines) {
    Write-Host "ERROR: File is empty or unreadable: $Path"
    Read-Host "Press Enter to return"
    exit
}

$index = 0

function Show-Page {
    Clear-Host
    $end = [Math]::Min($index + $PageSize - 1, $lines.Count - 1)
    $lines[$index..$end]
    Write-Host ""
    Write-Host "[Up/Down] Scroll  [PageUp/PageDown] Jump  [Q] Quit" -ForegroundColor Cyan
}

Show-Page

while ($true) {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # Quit on Q or q
    if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
        break
    }

    switch ($key.VirtualKeyCode) {
        38 {  # Up
            if ($index -gt 0) {
                $index--
                Show-Page
            }
        }

        40 {  # Down
            if ($index -lt $lines.Count - 1) {
                $index++
                Show-Page
            }
        }

        33 {  # PageUp
            $index = [Math]::Max($index - $PageSize, 0)
            Show-Page
        }

        34 {  # PageDown
            $index = [Math]::Min($index + $PageSize, $lines.Count - 1)
            Show-Page
        }
    }
}