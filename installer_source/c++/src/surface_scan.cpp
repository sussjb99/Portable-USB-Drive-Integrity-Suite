/* ============================================================
   PUDIS (Portable‑USB‑Drive‑Integrity‑Suite)
   File: surface_scan.cpp
   Author: sussjb99
   Version: 1.0
   Last Modified: 2026-04-12
   Copyright (c) 2026 sussjb99. All rights reserved.
   Licensed under the MIT License. See LICENSE.txt for details.
   ============================================================ */


#include <windows.h>
#include <winioctl.h>
#include <setupapi.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <numeric>
#include <algorithm>
#include <iomanip>
#include <ctime>
#include <sstream>
#include <chrono>
#include <limits> 

#pragma comment(lib, "setupapi.lib")

using namespace std;
using namespace std::chrono;

// --- DEFINITIONS & STRUCTURES ---
#ifndef StorageDeviceRotationRateProperty
#define StorageDeviceRotationRateProperty 15
#endif

typedef struct _DEVICE_ROTATION_RATE_DESCRIPTOR {
    DWORD Version; DWORD Size; DWORD NominalMediaRotationRate; DWORD Reserved;
} DEVICE_ROTATION_RATE_DESCRIPTOR;

typedef struct _DEVICE_MANAGEMENT_STATUS_DESCRIPTOR {
    DWORD Version; DWORD Size; DWORD RetainContext; DWORD Reserved;
    DWORD ReportingInterface; DWORD DeviceCapabilities;
} DEVICE_MANAGEMENT_STATUS_DESCRIPTOR;

static const GUID GUID_DISK = { 0x4d36e967, 0xe325, 0x11ce, { 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18 } };

struct DriveInfo {
    string model = "Unknown Hardware";
    string serial = "Unknown Serial";
    string tech = "HDD"; 
    string interfaceStr = "Unknown";
    string fs = "Unknown";
    string recordingTech = ""; 
    int rpm = 0;
    bool isExternal = false;
    double capacityGB = 0.0; 
    DWORD diskIndex = 0xFFFFFFFF;
};

// --- UTILITY FUNCTIONS ---
void Trim(string& s) {
    s.erase(0, s.find_first_not_of(" \t\n\r"));
    s.erase(s.find_last_not_of(" \t\n\r") + 1);
}

string FormatSeconds(double totalSeconds) {
    int seconds = static_cast<int>(totalSeconds);
    int hh = seconds / 3600;
    int mm = (seconds % 3600) / 60;
    int ss = seconds % 60;
    stringstream ss_out;
    ss_out << setfill('0') << setw(2) << hh << ":" << setw(2) << mm << ":" << setw(2) << ss;
    return ss_out.str();
}

string ExtractBlock(const string& content, const string& tag) {
    string startTag = "<" + tag + ">";
    string endTag = "</" + tag + ">";
    size_t start = content.find(startTag);
    size_t end = content.find(endTag);
    if (start != string::npos && end != string::npos) {
        return content.substr(start, (end + endTag.length()) - start);
    }
    return "";
}

string GetTimestamp(bool filenameSafe = false) {
    time_t now = time(0); struct tm tstruct; localtime_s(&tstruct, &now);
    char buf[80]; strftime(buf, sizeof(buf), filenameSafe ? "%Y%m%d_%H%M%S" : "%Y-%m-%d %H:%M:%S", &tstruct);
    return string(buf);
}

// --- IMPROVED GRADING LOGIC ---
string GetTechnicalGrade(double stab, int errors, double avgSpeed) {
    if (errors > 0) return "CRITICAL (Data Loss)";
    
    // For slow/old drives, we lower the bar for "Healthy"
    // because OS background tasks cause huge % stability drops on slow hardware.
    if (avgSpeed < 10.0) {
        if (stab >= 50.0) return "Healthy";
        if (stab >= 15.0) return "Warning (Inconsistent)";
        return "Degraded (Extreme Jitter)";
    }

    // Standard high-speed drive grading
    if (stab >= 85.0) return "Healthy";
    if (stab >= 60.0) return "Warning";
    return "Degraded";
}

void FillPattern(vector<char>& buffer, long long fileStartOffset) {
    for (size_t i = 0; i < buffer.size(); i += 512) {
        long long absoluteOffset = fileStartOffset + i;
        if (i + sizeof(long long) <= buffer.size()) {
            memcpy(&buffer[i], &absoluteOffset, sizeof(long long));
        }
        for (size_t j = sizeof(long long); j < 512 && (i + j) < buffer.size(); ++j) {
            buffer[i + j] = (char)((absoluteOffset + j) % 256);
        }
    }
}

DriveInfo GetDriveDetails(string driveLetter) {
    DriveInfo info;
    string devicePath = "\\\\.\\" + driveLetter + ":";
    string rootPath = driveLetter + ":\\";
    UINT osDriveType = GetDriveTypeA(rootPath.c_str());
    
    char fsName[MAX_PATH] = { 0 };
    if (GetVolumeInformationA(rootPath.c_str(), NULL, 0, NULL, NULL, NULL, fsName, MAX_PATH)) info.fs = fsName;

    ULARGE_INTEGER freeBytes, totalBytes, tFree;
    if (GetDiskFreeSpaceExA(rootPath.c_str(), &freeBytes, &totalBytes, &tFree)) {
        info.capacityGB = (double)totalBytes.QuadPart / (1024.0 * 1024.0 * 1024.0);
    }

    HANDLE h = CreateFileA(devicePath.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (h != INVALID_HANDLE_VALUE) {
        DWORD bytes; BYTE buf[4096];
        STORAGE_DEVICE_NUMBER sdn;
        if (DeviceIoControl(h, IOCTL_STORAGE_GET_DEVICE_NUMBER, NULL, 0, &sdn, sizeof(sdn), &bytes, NULL)) info.diskIndex = sdn.DeviceNumber;
        
        STORAGE_PROPERTY_QUERY query = { StorageDeviceProperty, PropertyStandardQuery };
        if (DeviceIoControl(h, IOCTL_STORAGE_QUERY_PROPERTY, &query, sizeof(query), buf, sizeof(buf), &bytes, NULL)) {
            STORAGE_DEVICE_DESCRIPTOR* d = (STORAGE_DEVICE_DESCRIPTOR*)buf;
            string v = (d->VendorIdOffset != 0) ? (char*)(buf + d->VendorIdOffset) : "";
            string p = (d->ProductIdOffset != 0) ? (char*)(buf + d->ProductIdOffset) : "";
            info.model = v + " " + p; Trim(info.model);
            info.isExternal = (d->BusType == BusTypeUsb || osDriveType == DRIVE_REMOVABLE);
            info.interfaceStr = (d->BusType == BusTypeUsb) ? "USB" : (d->BusType == BusTypeSata) ? "SATA" : (d->BusType == BusTypeNvme) ? "NVMe" : "Other";
        }
        CloseHandle(h);
    }
    return info;
}

int main(int argc, char* argv[]) {
    if (argc < 6) { cout << "Usage: surface_scan.exe [Drive] [%] [Temp] [Report] [XML]" << endl; return 1; }

    auto startTime = steady_clock::now();

    string driveLtr = argv[1];
    if (driveLtr.find(':') != string::npos) driveLtr = driveLtr.substr(0, driveLtr.find(':'));
    if (driveLtr == "C" || driveLtr == "c") { cerr << "ERROR: C: Restricted." << endl; return 1; }

    DriveInfo dev = GetDriveDetails(driveLtr);
    if (dev.diskIndex == 0xFFFFFFFF) { cerr << "ERROR: Run as Admin or Drive Unplugged." << endl; return 1; }

    int percentage = stoi(argv[2]);
    string tmpPath = argv[3]; string rptPath = argv[4]; string xmlPath = argv[5];
    if (tmpPath.back() != '\\') tmpPath += "\\"; 
    if (rptPath.back() != '\\') rptPath += "\\";
    CreateDirectoryA(tmpPath.c_str(), NULL);
    CreateDirectoryA(rptPath.c_str(), NULL);

    ULARGE_INTEGER lpFreeBytesAvailable, lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes;
    string root = driveLtr + ":\\";
    long long freeBytesRaw = 0;
    if (GetDiskFreeSpaceExA(root.c_str(), &lpFreeBytesAvailable, &lpTotalNumberOfBytes, &lpTotalNumberOfFreeBytes)) {
        freeBytesRaw = lpFreeBytesAvailable.QuadPart;
    } else {
        freeBytesRaw = static_cast<long long>(dev.capacityGB * 1024.0 * 1024.0 * 1024.0);
    }

    double ratio = static_cast<double>(percentage) / 100.0;
    long long targetBytes = static_cast<long long>(static_cast<double>(freeBytesRaw) * ratio) - (100LL * 1024LL);
    
    const long long ONE_GB = 1024LL * 1024LL * 1024LL;
    const long long TWO_GB = 2048LL * 1024LL * 1024LL;
    size_t CHUNK_SIZE;

    if (freeBytesRaw >= TWO_GB) {
        CHUNK_SIZE = static_cast<size_t>(ONE_GB);
    } else {
        CHUNK_SIZE = 32768; // 32KB for small devices
    }

    if (targetBytes > 0 && targetBytes < (long long)CHUNK_SIZE) {
        CHUNK_SIZE = (static_cast<size_t>(targetBytes) / 512) * 512; 
        if (CHUNK_SIZE == 0 && targetBytes > 0) CHUNK_SIZE = 512;
    }

    if (targetBytes <= 0) targetBytes = 0;

    int totalFiles = (CHUNK_SIZE > 0) ? static_cast<int>(targetBytes / CHUNK_SIZE) : 0;
    if (totalFiles < 1 && targetBytes > 0) totalFiles = 1;

    vector<double> wSpeeds, rSpeeds;
    int errors = 0;
    stringstream errorLog;

    if (totalFiles > 0) {
        cout << " [1/2] WRITING: Initializing..." << flush;
        for (int i = 1; i <= totalFiles; ++i) {
            string p = tmpPath + to_string(i) + ".h2w";
            vector<char> buffer(CHUNK_SIZE);
            FillPattern(buffer, (long long)(i - 1) * CHUNK_SIZE);
            HANDLE h = CreateFileA(p.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH, NULL);
            if (h == INVALID_HANDLE_VALUE) { errors++; continue; }
            
            LARGE_INTEGER s, e, f; QueryPerformanceFrequency(&f); QueryPerformanceCounter(&s);
            DWORD bw; WriteFile(h, buffer.data(), (DWORD)CHUNK_SIZE, &bw, NULL);
            QueryPerformanceCounter(&e); CloseHandle(h);
            
            double speed = (static_cast<double>(CHUNK_SIZE) / (1024.0 * 1024.0)) / (static_cast<double>(e.QuadPart - s.QuadPart) / f.QuadPart);
            wSpeeds.push_back(speed);
            
            duration<double> diff = steady_clock::now() - startTime;
            if (CHUNK_SIZE >= ONE_GB || i % 500 == 0 || i == totalFiles) {
                cout << "\r [1/2] WRITING: " << (i * 100 / totalFiles) << "% | Speed: " << fixed << setprecision(1) << speed << " MB/s | Elapsed: " << FormatSeconds(diff.count()) << "   " << flush;
            }
        }
        cout << endl;

        cout << " [2/2] READING: Initializing..." << flush;
        for (int i = 1; i <= totalFiles; ++i) {
            string p = tmpPath + to_string(i) + ".h2w";
            HANDLE h = CreateFileA(p.c_str(), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
            if (h != INVALID_HANDLE_VALUE) {
                vector<char> buf(CHUNK_SIZE);
                LARGE_INTEGER s, e, f; QueryPerformanceFrequency(&f); QueryPerformanceCounter(&s);
                DWORD br; ReadFile(h, buf.data(), (DWORD)CHUNK_SIZE, &br, NULL);
                QueryPerformanceCounter(&e); CloseHandle(h);
                
                double speed = (static_cast<double>(CHUNK_SIZE) / (1024.0 * 1024.0)) / (static_cast<double>(e.QuadPart - s.QuadPart) / f.QuadPart);
                rSpeeds.push_back(speed);
                
                long long expected = (long long)(i - 1) * CHUNK_SIZE;
                for (size_t b = 0; b < CHUNK_SIZE; b += 512) {
                    if (b + sizeof(long long) > buf.size()) break;
                    long long val; memcpy(&val, &buf[b], sizeof(long long));
                    if (val != (expected + b)) { 
                        errors++; 
                        errorLog << "Mismatch @ File " << i << ".h2w Offset " << b << " | Found: 0x" << hex << val << " Expected: 0x" << (expected + b) << dec << "\n";
                    }
                }
                DeleteFileA(p.c_str());

                duration<double> diff = steady_clock::now() - startTime;
                if (CHUNK_SIZE >= ONE_GB || i % 500 == 0 || i == totalFiles) {
                    cout << "\r [2/2] READING: " << (i * 100 / totalFiles) << "% | Speed: " << fixed << setprecision(1) << speed << " MB/s | Elapsed: " << FormatSeconds(diff.count()) << "   " << flush;
                }
            }
        }
        cout << endl;
    }

    auto totalDuration = duration_cast<seconds>(steady_clock::now() - startTime);
    string durationStr = FormatSeconds(totalDuration.count());

    sort(rSpeeds.begin(), rSpeeds.end());
    double rStab = rSpeeds.empty() ? 0 : (rSpeeds[0] / rSpeeds.back()) * 100.0;
    double avgR = rSpeeds.empty() ? 0 : accumulate(rSpeeds.begin(), rSpeeds.end(), 0.0) / rSpeeds.size();

    // Final Grade Call
    string finalGrade = GetTechnicalGrade(rStab, errors, avgR);

    // XML Output Logic
    string content; ifstream in(xmlPath);
    if (in) { stringstream ss_in; ss_in << in.rdbuf(); content = ss_in.str(); in.close(); }
    string meta = ExtractBlock(content, "Metadata"), ident = ExtractBlock(content, "HardwareIdentity"), 
           cap = ExtractBlock(content, "StorageCapacity"), vit = ExtractBlock(content, "HardwareVitals"),
           pol = ExtractBlock(content, "Policy"), smrt = ExtractBlock(content, "SmartHealthStatus"),
           integ = ExtractBlock(content, "FileIntegrityScan");

    ofstream xml(xmlPath);
    if (xml) {
        xml << "<DriveBabySitter>\n";
        if(!meta.empty()) xml << "  " << meta << "\n"; 
        if(!ident.empty()) xml << "  " << ident << "\n";
        if(!cap.empty()) xml << "  " << cap << "\n"; 
        if(!vit.empty()) xml << "  " << vit << "\n";
        if(!pol.empty()) xml << "  " << pol << "\n"; 
        if(!smrt.empty()) xml << "  " << smrt << "\n";
        if(!integ.empty()) xml << "  " << integ << "\n";
        
        xml << "  <SurfaceScanInfo>\n"
            << "    <SurfaceScanDate>" << GetTimestamp() << "</SurfaceScanDate>\n"
            << "    <ActualTimeTaken>" << durationStr << "</ActualTimeTaken>\n"
            << "    <SurfaceGrade>" << finalGrade << "</SurfaceGrade>\n"
            << "    <StabilityScore>" << fixed << setprecision(1) << rStab << "</StabilityScore>\n"
            << "    <AvgReadSpeed>" << fixed << setprecision(2) << avgR << "</AvgReadSpeed>\n"
            << "    <ScanCoverage>" << percentage << "</ScanCoverage>\n"
            << "    <ErrorsDetected>" << errors << "</ErrorsDetected>\n"
            << "  </SurfaceScanInfo>\n</DriveBabySitter>\n";
    }

    if (errors > 0) {
        ofstream logFile(rptPath + "surface_errors.log", ios::app);
        if (logFile) { logFile << "--- SCAN AT " << GetTimestamp() << " ---\n" << errorLog.str() << "-----------------\n\n"; }
    }

    cout << "\n========================================" << endl;
    cout << " SCAN COMPLETE " << endl;
    cout << " Total Time: " << durationStr << endl;
    cout << " Grade:      " << finalGrade << endl;
    cout << " Errors:     " << errors << endl;
    cout << "========================================" << endl;

    return 0;
}
