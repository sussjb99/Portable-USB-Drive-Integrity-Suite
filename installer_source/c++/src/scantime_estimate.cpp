/* ============================================================
   Portable Drive Baby Sitter - Integrity Suite
   File: scantime_estimate.cpp
   Author: sussjb99
   Version: 1.0
   Last Modified: 2026-04-12
   Copyright (c) 2026 sussjb99. All rights reserved.
   Licensed under the MIT License. See LICENSE.txt for details.
   ============================================================ */

#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
#include <numeric>
#include <algorithm>

using namespace std;

int main(int argc, char* argv[]) {
    if (argc < 3) { cout << "Usage: scantime_estimate.exe [Drive] [Percentage]" << endl; return 1; }

    string driveLetter = argv[1];
    if (driveLetter.find(':') != string::npos) driveLetter = driveLetter.substr(0, driveLetter.find(':'));
    string root = driveLetter + ":\\";
    int percentage = stoi(argv[2]);

    if (driveLetter == "C" || driveLetter == "c") { cerr << "Safety: C: Restricted." << endl; return 1; }

    // GET FREE SPACE (This is what surface_scan actually uses)
    ULARGE_INTEGER freeBytes, totalBytes, tFree;
    if (!GetDiskFreeSpaceExA(root.c_str(), &freeBytes, &totalBytes, &tFree)) {
        cerr << "Error: Drive not ready." << endl; return 1;
    }

    // --- MATCHING SURFACE_SCAN LOGIC ---
    const double CHUNK_SIZE_MB = 1024.0;
    // We only scan the requested percentage of AVAILABLE space
    double totalMBToScan = (freeBytes.QuadPart * (percentage / 100.0)) / (1024.0 * 1024.0);
    
    int totalChunks = static_cast<int>(totalMBToScan / CHUNK_SIZE_MB);
    if (totalChunks < 1 && totalMBToScan > 0) totalChunks = 1;

    // --- BENCHMARK (128MB Sprint) ---
    const size_t TEST_MB = 128;
    const size_t TEST_SIZE = TEST_MB * 1024 * 1024;
    vector<char> buffer(TEST_SIZE, 'A');
    string tempFile = root + "estimate_temp.dat";

    cout << "Benchmarking " << driveLetter << " Free Space (" << fixed << setprecision(2) << totalMBToScan/1024.0 << " GB)..." << endl;

    LARGE_INTEGER s, e, f;
    QueryPerformanceFrequency(&f);

    // Write Benchmark
    HANDLE hW = CreateFileA(tempFile.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH, NULL);
    if (hW == INVALID_HANDLE_VALUE) { cerr << "Access Denied." << endl; return 1; }
    QueryPerformanceCounter(&s);
    DWORD bw; WriteFile(hW, buffer.data(), (DWORD)TEST_SIZE, &bw, NULL);
    FlushFileBuffers(hW); 
    QueryPerformanceCounter(&e); CloseHandle(hW);
    double wSpeed = (TEST_MB) / (static_cast<double>(e.QuadPart - s.QuadPart) / f.QuadPart);

    // Read Benchmark
    HANDLE hR = CreateFileA(tempFile.c_str(), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL);
    QueryPerformanceCounter(&s);
    DWORD br; ReadFile(hR, buffer.data(), (DWORD)TEST_SIZE, &br, NULL);
    QueryPerformanceCounter(&e); CloseHandle(hR);
    DeleteFileA(tempFile.c_str());
    double rSpeed = (TEST_MB) / (static_cast<double>(e.QuadPart - s.QuadPart) / f.QuadPart);

    // --- REFINED REAL-WORLD CONSTANTS ---
    // 1. Transfer with 15% Sustained-Write Penalty
    double timeTransfer = ((totalMBToScan / wSpeed) + (totalMBToScan / rSpeed)) * 1.15;
    
    // 2. RAM Pattern Gen & 512-byte Offset Verification
    // (Pattern Gen ~1.5s/GB + Verification Loop ~2.5s/GB)
    double timeProcessing = totalChunks * 4.0;

    // 3. Hardware Commitment (CloseHandle/Flush overhead)
    double timeCommit = totalChunks * 7.0;

    // 4. Fixed SetupAPI/Init overhead
    double timeInit = 8.0;

    double totalSeconds = timeTransfer + timeProcessing + timeCommit + timeInit;

    int hh = (int)totalSeconds / 3600;
    int mm = ((int)totalSeconds % 3600) / 60;
    int ss = (int)totalSeconds % 60;

    cout << "------------------------------------------" << endl;
    cout << "Testable Space : " << fixed << setprecision(2) << (totalMBToScan / 1024.0) << " GB" << endl;
    cout << "Write Speed    : " << fixed << setprecision(1) << wSpeed << " MB/s" << endl;
    cout << "Read Speed     : " << fixed << setprecision(1) << rSpeed << " MB/s" << endl;
    cout << "Estimated Time : " << setfill('0') << setw(2) << hh << ":" << setw(2) << mm << ":" << setw(2) << ss << endl;
    cout << "------------------------------------------" << endl;

    return 0;
}