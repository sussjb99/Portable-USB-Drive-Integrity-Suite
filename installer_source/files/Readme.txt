============================================================
                 DRIVE BABY SITTER - INTEGRITY SUITE
============================================================

OVERVIEW
--------
Drive Baby Sitter is a maintenance and monitoring tool designed
to help you keep external drives healthy over long periods of
time. It performs two major categories of checks:

  * FILE INTEGRITY (Bit-Rot Detection)
  * SURFACE ANALYSIS (Performance & Stability Scans)

The suite works with USB flash drives, portable HDDs/SSDs,
and other removable storage devices. It will not modify files
unless you explicitly choose to perform a data recovery
procedure.

------------------------------------------------------------
DEVICE INFORMATION
------------------------------------------------------------
The main screen shows details about the currently mounted 
drive:

  DEVICE        The model name reported by the drive.
  SERIAL        The unique hardware serial number.
  MOUNTED       The drive letter currently assigned.
  FILESYSTEM    FAT32, exFAT, NTFS, etc.
  TECHNOLOGY    Flash, HDD, SSD, or Unknown.
  SMARTHEALTH   SMART status (if supported).

STORAGE CAPACITY
  Capacity      Total size of the drive.
  Used / Free   Current space usage.

CAPACITY VALIDATION
  The suite verifies whether the drive's reported capacity
  matches its actual usable capacity. Some counterfeit or
  defective flash drives falsely advertise larger sizes than
  they can physically store. These devices appear normal until
  the system writes past their true limit, causing silent data
  loss.

  During a Full Surface Scan, the suite writes controlled test
  files across the free space of the drive and reads them back
  to confirm that all regions are real, stable, and readable.
  Any mismatch, write failure, or read-back error is reported
  immediately.

FILE INTEGRITY (Bit-Rot Scan)
  Integrity     Overall condition of stored files.
  Checked At    Timestamp of the last integrity scan.

SURFACE ANALYSIS (Performance Scan)
  Grade         Overall health rating based on read stability.
  Coverage      How much of the drive surface was scanned.
  Stability     Percentage of stable reads.
  Avg Rate      Average read speeds during the scan.
  Checked At    Timestamp of the last surface scan.

------------------------------------------------------------
HOW FILE INTEGRITY WORKS
------------------------------------------------------------

The suite maintains a "baseline" of all files on the drive. 
This baseline includes:

  * File paths
  * File sizes
  * Timestamps
  * Cryptographic hash values

During a scan, each file is compared against the baseline. 
The suite can detect:

  * NEW FILES
      Files that exist on the drive but not in the baseline.

  * DELETED FILES
      Files that were in the baseline but no longer exist.

  * MODIFIED FILES
      Files whose timestamp or size has changed since the last
      baseline update.

  * CORRUPTED FILES (Bit Rot)
      Files whose hash value has changed even though the
      timestamp is the same. This indicates silent corruption, 
      not a normal edit.

When corruption is detected, the suite checks whether PAR2
recovery data exists for the affected file. If recovery is
possible, the suite offers to repair the file automatically.

Recovered files are written back to their original location.
The previous (corrupted) version is preserved and renamed with
a ".1"suffix for safety. No file is ever overwritten during 
recovery.

------------------------------------------------------------
TASKS -- FILE INTEGRITY
------------------------------------------------------------

[1] Scan for Bit Rot
    Compares all files on the drive against the stored baseline.
    Detects new, deleted, modified, and corrupted files. 
    If corruption is found and recovery data exists, the suite 
    offers a guided recovery procedure using PAR2. Only
    files that meet recovery criteria are processed. Corrupted
    originals are preserved with a ".1" suffix during repair.
    Use this function for new devices or after adding, removing,
    or modifying files on the drive. 

[2] Update File Baseline
    Creates or updates the integrity baseline file using the 
    current state of all files. Use this for new devices or
    after adding, removing, or modifying files on the drive. 
    This overwrites the previous baseline.

[3] Re-Generate Recovery Data
    Creates or updates PAR2 recovery files. These allows damaged
    files to be repaired later if corruption is detected. Use 
    this for new devices or after adding, removing, or modifying
    files on the drive. This overwrites the previous PAR2 
    recovery files.


------------------------------------------------------------
TASKS -- SURFACE SCANS
------------------------------------------------------------

[4] Quick Surface Scan
    Reads a small sample of the drive to estimate stability and
    performance. Useful for routine checks or when time is 
    short.

[5] Full Surface Scan (Sequential Read/Write Validation)
    Performs the most thorough test available. The suite writes
    a series of small test files across the free capacity of the
    drive until the free space is fully occupied. These files 
    are then read back sequentially to verify that:

      * The drive can store data across its entire advertised
        capacity.
      * All written data can be read back without corruption.
      * No hidden capacity limits or controller failures exist.

    After validation, all temporary test files are deleted.

    This scan is especially effective at detecting:
      * Fake-capacity flash drives.
      * Drives with failing flash cells.
      * Controllers that misreport available space.
      * Regions of the drive that become unstable under load.

    Because this test writes and reads the entire free space,
    it takes longer on large drives but provides the highest
    level of confidence in the device's true health.

------------------------------------------------------------
EXITING
------------------------------------------------------------

[E] Exit Suite
    Returns to the operating system.

------------------------------------------------------------
RECOMMENDED USAGE
------------------------------------------------------------

For New Installations:
* Update File Baseline, then run Re-Generate Recovery Data.

Before Retrieving Information from the Storage Device:
* Run Scan for Bit Rot.

For Surface Quality Checks:
* Run Quick Surface Scan monthly on frequently used drives.
* Run Full Surface Scan every 6 months or after unexpected
  disconnects.

* Update the File Baseline and re-generate Recovery Data
  whenever you change the contents of your storage device.

------------------------------------------------------------
NOTES
------------------------------------------------------------

* Flash drives wear out over time. Regular scans help detect
  early failure before data loss occurs.

* Bit rot can affect any storage device. The integrity baseline
  allows the suite to detect even single-bit corruption.

* Recovery data (PAR2) is optional but strongly recommended for
  long-term archival drives.

* Capacity validation helps protect against counterfeit or
  defective flash drives that may silently discard data once
  their true physical limit is reached.

============================================================
END OF DOCUMENT
============================================================