# Application Manifest & Security Declaration
**Project:** PUDIS (Portable USB  Drive Integrity Suite)  
**Status:** Beta (Public Funding Phase)

## 1. Technical Justification
This software performs low-level hardware analysis to ensure data integrity on USB storage devices. Because it interacts directly with disk sectors to bypass OS caching, certain security scanners may flag these behaviors as "Defense Evasion" (T1006) or "Discovery" (T1082/T1083). These actions are strictly functional and required for accurate hardware stress testing.

## 2. File Inventory & Integrity Hashes
| Path | SHA-256 Hash |
| :--- | :--- |
| !VERIFY_INTEGRITY.BAT | `77AD6897D9A0420E81F9D85A313118D14F60F9707E4F35D0E5B64B045BFFCF7B` |
| Integrity_Check\bin\deviceinfo.exe | `8BC2FAE2D1D766B2F588A0F86F22D82A763008C9242B9E8EE55171AD180A637D` |
| Integrity_Check\bin\full_probe.exe | `5965C4689C670696ACF84F29D14AB64AA9A9EEE0B4A83B24572A7322AE634817` |
| Integrity_Check\bin\surface_scan.exe | `3F7BAEFBC044DED6C22B61BE290D0748D0B77AE4D3FA9D1368E8BB1E79C43FE3` |
| Integrity_Check\bin\par2.exe | `C74D268D05C5234D2C0DCB27B370F659DDE698B902F9E9A6E2626B90A5AC1411` |
| Integrity_Check\bin\corruptor.exe | `0139F9BC794A502E3D1FDF15894A24A4304EDB3B3C9AA85FE465A978453F491D` |
| Integrity_Check\bin\hashdeep64.exe | `5F52886614DE94F51742051A3F6A89872901D0286FEBDE13ABDD997997124AE9` |
| Integrity_Check\bin\smartctl.exe | `B5DB94E5082C042BE44994B7A4FA8F7B5C8E713B2AB1C9A560D8F7A7995EA27D` |
| I:\Integrity_Check\scripts\create_baselineXML.ps1 | `C7F38B4E6ECBF7784A1D7EF5C63D8F1A7B0C40BC45AB8717099E3E958073E9A2` |
| I:\Integrity_Check\scripts\create_recovery.ps1 | `4BB27E7B9571676D2FE1E32E827253078F3AF58947E64781A7BC0BC6E0296813` |
| I:\Integrity_Check\scripts\full_surface_scan.bat | `1AEBFD5034B0381596395311D4B276902DEA8B8EB886041FF8404AE99023E08F` |
| I:\Integrity_Check\scripts\generate_report.ps1 | `C394886ADCCC9E084D7BE025C7E164BC4C1E76B26ADC0F8E37C1F65980983304` |
| I:\Integrity_Check\scripts\pager.ps1 | `83BE18D0EBE1925565A48AFF77BD11CBFAB3912400E7C1B2BBEE06D04294E3FD` |
| I:\Integrity_Check\scripts\pshell.bat | `8F947B928411A768D7B07F8F3797233B6EB568C019525071A3ACF1EE2A08A541` |
| I:\Integrity_Check\scripts\quick_file_check.ps1 | `737EDA84500AF065B471CFEA8A21C41816E7277A7011F11992080FBBCAD14194` |
| I:\Integrity_Check\scripts\quick_surface_scan.bat | `BB090434B97537F67CEBD4A6644B0501A6D54FE5622D996F3CE8FACA390635AF` |


## 3. Behavioral Disclosure (MITRE ATT&CK Mapping)
To assist security auditors and automated scanners, we disclose the following expected behaviors[cite: 3]:
* **T1006 (Direct Volume Access):** Required by `surface_scan.exe` to verify physical sectors[cite: 3].
* **T1055 (Process Injection):** High-performance threading used for parallel parity calculation in `par2.exe`[cite: 3].
* **T1082/T1083 (Discovery):** Used to identify the correct physical drive and prevent accidental data loss on the system drive (C:)[cite: 3].
* **T1553.002 (Code Signing):** Files are currently **Self-Signed** due to project funding status[cite: 3].

## 4. External Dependencies
The following binaries are included as open-source dependencies:
* **par2.exe**: Forked from [sussjb99/par2cmdline](https://github.com/sussjb99/par2cmdline--filelist.txt). (Modified to support @filelist.txt).
* **hashdeep64.exe**: Sourced from [jessek/hashdeep](https://github.com/jessek/hashdeep).
* **smartctl.exe**: Sourced from [smartmontools](https://github.com/smartmontools/smartmontools).

---
*This manifest was generated to ensure transparency and verify that the distributed binaries match the developer's intent.*
