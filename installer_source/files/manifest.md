# Application Manifest & Security Declaration
**Project:** PUDIS (Portable USB  Drive Integrity Suite)  
**Status:** Beta (Public Funding Phase)

## 1. Technical Justification
This software performs low-level hardware analysis to ensure data integrity on USB storage devices. Because it interacts directly with disk sectors to bypass OS caching, certain security scanners may flag these behaviors as "Defense Evasion" (T1006) or "Discovery" (T1082/T1083). These actions are strictly functional and required for accurate hardware stress testing.

## 2. File Inventory & Integrity Hashes
| Path | Purpose | SHA-256 Hash (Integrity Check) |
| :--- | :--- | :--- |
| !VERIFY_INTEGRITY.BAT |  | `77AD6897D9A0420E81F9D85A313118D14F60F9707E4F35D0E5B64B045BFFCF7B` |
| deviceinfo.exe | Portable USB Drive Integrity Suite - Device Information Extractor | `8BC2FAE2D1D766B2F588A0F86F22D82A763008C9242B9E8EE55171AD180A637D` |
| full_probe.exe | Portable USB Drive Integrity Suite - Full Hardware Probe | `5965C4689C670696ACF84F29D14AB64AA9A9EEE0B4A83B24572A7322AE634817` |
| surface_scan.exe | Portable USB Drive Integrity Suite - Surface Scan Utility | `3F7BAEFBC044DED6C22B61BE290D0748D0B77AE4D3FA9D1368E8BB1E79C43FE3` |
| par2.exe | PUDIS PAR2 Engine | `C74D268D05C5234D2C0DCB27B370F659DDE698B902F9E9A6E2626B90A5AC1411` |
| corruptor.exe | Portable USB Drive Integrity Suite - Corruptor Utility | `0139F9BC794A502E3D1FDF15894A24A4304EDB3B3C9AA85FE465A978453F491D` |
| hashdeep64.exe |  | `5F52886614DE94F51742051A3F6A89872901D0286FEBDE13ABDD997997124AE9` |
| smartctl.exe | Control and Monitor Utility for SMART Disks | `B5DB94E5082C042BE44994B7A4FA8F7B5C8E713B2AB1C9A560D8F7A7995EA27D` |

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
