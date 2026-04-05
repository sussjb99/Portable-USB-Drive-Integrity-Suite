### 📂 Application Folder Structure

```directory
\
├── !VERIFY_INTEGRITY.BAT           # Main UI and menu controller
└── Integrity_Check\                # Root application folder
    ├── Drive_status.xml            # Unified health and scan log
    ├── Readme.txt                  # Documentation
    ├── bin\                        # Compiled binaries and engines
    │   ├── deviceinfo.exe          # Hardware detail gatherer
    │   ├── full_probe.exe          # Deep hardware analysis
    │   ├── hashdeep64.exe          # Hashing engine for bit-rot detection
    │   ├── par2.exe                # Repair and recovery engine
    │   ├── scantime_estimator.exe  # Benchmarking and time prediction
    │   ├── smartctl.exe            # S.M.A.R.T. monitoring tool
    │   └── surface_scan.exe        # Disk sector analysis
    ├── logs\                       # Storage for baseline and current XMLs
    ├── reports\                    # Generated scan results
    └── scripts\                    # Core logic execution
        ├── create_baseXML.ps1      # Generates the initial file snapshot
        ├── create_recovery.ps1     # Generates PAR2 recovery data
        ├── pager.ps1               # UI/Text pagination helper
        ├── quick_file_check.ps1    # Compares current state vs. baseline
        ├── full_surface_scan.bat   # Full surface scan script
        ├── pshell.bat              # PowerShell wrapper for batch
        └── quick_surface_scan.bat  # Quick limited surface scan script
