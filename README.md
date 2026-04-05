# Portable Drive Baby Sitter – Integrity Suite

Portable Drive Baby Sitter is a maintenance and monitoring toolkit designed to keep external storage devices healthy over long periods of time. It performs two major categories of checks:

- **File Integrity (Bit‑Rot Detection)**
- **Surface Analysis (Performance & Stability Scans)**

The suite works with USB flash drives, portable HDDs/SSDs, and other removable storage devices. It never modifies files unless you explicitly choose to run a recovery procedure.

This software is portable and is designed to be installed and run directly on your storage devices.

This software is was written in C++, Powershell, and bat scripting languages.

---

## Features

### 🔍 Device Information
Displays detailed information about the currently mounted drive:

- Device model  
- Hardware serial number  
- Drive letter  
- Filesystem type (FAT32, exFAT, NTFS, etc.)  
- Storage technology (Flash, HDD, SSD, Unknown)  
- SMART health (if supported)

### 📦 Capacity Validation
Validates whether the drive’s reported capacity matches its actual usable capacity.  
This helps detect counterfeit or defective flash drives that silently discard data once their true limit is exceeded.

During a **Full Surface Scan**, the suite writes controlled test files across free space and reads them back to verify:

- All regions of the drive are real and readable  
- No hidden capacity limits  
- No controller failures  
- No unstable regions under load

### 🧬 File Integrity (Bit‑Rot Detection)
The suite maintains a cryptographic baseline of all files, including:

- File paths  
- File sizes  
- Timestamps  
- Hash values  

**It detects:** 
- New files  
- Deleted files  
- Modified files  
- Corrupted files (bit rot) — files whose hash value has changed even though the timestamp is the same.

If PAR2 recovery data exists, the suite can automatically repair corrupted files.  
Recovered files are written back safely, and corrupted originals are preserved with a `.1` suffix.

### 📊 Surface Scans

#### Quick Surface Scan
Reads a small sample of the drive to estimate stability and performance.

#### Full Surface Scan
Performs a full read/write validation across the drive’s free space.  
This is the most thorough test and is especially effective at detecting:

- Fake‑capacity flash drives  
- Failing flash cells  
- Misreporting controllers  
- Unstable regions under load

---

## Tasks Overview

### 1. Scan for Bit Rot
Compares all files against the stored baseline and detects new, deleted, modified, or corrupted files.

### 2. Update File Baseline
Creates or updates the integrity baseline.

### 3. Re‑Generate Recovery Data
Creates or updates PAR2 recovery files for future repair operations.

### 4. Quick Surface Scan
Fast stability and performance sampling.

### 5. Full Surface Scan
Sequential read/write validation across all free space.

---

## Recommended Usage

- **New installations:**  
  Update File Baseline → Re‑Generate Recovery Data

- **Before retrieving data:**  
  Run Scan for Bit Rot

- **Routine health checks:**  
  - Quick Surface Scan monthly  
  - Full Surface Scan every 6 months or after unexpected disconnects

- **Whenever drive contents change:**  
  Update File Baseline + Re‑Generate Recovery Data

---

## Notes

- Flash drives wear out over time — regular scans help detect early failure.  
- Bit rot can affect any storage device; the integrity baseline allows detection of even single‑bit corruption.

  
- PAR2 recovery data is optional but strongly recommended for archival drives.  
- Capacity validation protects against counterfeit or defective flash drives.

---
## Building From Source

To build from source:

1. Clone this repository  
2. Open the project in your preferred development environment  
3. Build using your standard toolchain  

(You can expand this section later with exact build steps for C#, C++, Python, or whatever languages you use.)

---

## Contributing

Contributions are welcome.  
By submitting code, you agree that your contributions will be licensed under the GPLv3.

See `CONTRIBUTING.md` for details.

---

## Disclaimer

The software is provided **“AS IS”**, without warranty of any kind.  
You assume all risks associated with using the software.

See the LICENSE and AUA for full details.

---

## Contact

For questions, suggestions, or feedback, please open an issue on GitHub.

