### 📂 Application Folder Structure

```directory
\
├── !VERIFY_INTEGRITY.BAT                         # Main UI and menu controller
└── Integrity_Check\                              # Root application folder
    ├── Drive_status.xml                          # Unified health and scan log
    ├── Help.txt                                  # Hwlp File
    ├── bin\                                      # Compiled binaries and engines
    │   ├── baselineXML_estimate.exe              # Estimaates time required to rebuild baseline.xml
    │   ├── corruptor.exe                         # Generates bit rot files for testing
    │   ├── deviceinfo.exe                        # Gathers information about identified storage device
    │   ├── FileListGen.exe                       # Quickly generates file listing
    │   ├── full_probe.exe                        # Gathers information about all connected storage devices
    │   ├── hashdeep64.exe                        # Gahters information about all connected storage devices
    │   ├── par2.exe                              # Custimized version of Turbo par2.exe used for creating partity system
    │   └── scantime_estimate.exe                 # Estimates time required to do a surface scan
    │   └── smartctl.exe                          # Reports SMART info from compatible storage devices
    │   └── surface_scan.exe                      # Performs Sufface Scan and analysis of deviced by writing and reading files.
    ├── logs\                                     # Location for par2 and other system related files
        ├── baseline.xml                          # Contains baseline XML listing file properties
        ├── baseline_files.txt                    # Contains baseline listing of files
        ├── current_check.xml                     # Contains current XML listing of file properties
        ├── files_part1.txt                       # Contains 1st batch of files required for par2 processing
        ├── files_part2.txt                       # Contains 2nd batch of files required for par2 processing
        ├── recovery_data_part1.par2              # Contains index, filelist and hash blocks for par2 data recovery
        ├── recovery_data_part1.vol000+01.par2    # Contains parity blocks for recovering corrupted files
    ├── reports\                                  # Location for generated scan reports
        ├── REPORT_20260415_111950.html           # HTML Reports Generated when Surface Scanned
    └── scripts\                                  # Location for core logic execution scripts
        ├── create_baseXML.ps1                    # Generates the initial basline state baseline.xml
        ├── create_recovery.ps1                   # Generates the par2 data recovery sets
        ├── full_surface_Scan.bat                 # Runs full surface scans
        ├── generate_report.ps1                   # Generated and stores html reports of scan results
        ├── pager.ps1                             # Displays help.txt file with basic navigation
        ├── pshell.bat                            # Wrapper for running PowerShell scripts
        └── quick_file_check.ps1                  # Checks for bit rot and other types of changes
        └── quick_surface_scan.bat                # Performs limited surface scan for quick validations
