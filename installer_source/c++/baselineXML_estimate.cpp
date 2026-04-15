/* ============================================================
   Portable Drive Baby Sitter - Integrity Suite
   File: baselineXML_estimator.cpp
   Author: sussjb99
   Version: 1.0
   Last Modified: 2026-04-12
   Copyright (c) 2026 sussjb99. All rights reserved.
   Licensed under the MIT License. See LICENSE.txt for details.
   ============================================================ */


#include <windows.h>
#include <iostream>
#include <string>

struct ScanResult {
    unsigned __int64 totalBytes = 0;
};

// High-speed recursive crawl
void calculateSize(std::wstring path, ScanResult& result) {
    if (path.empty()) return;
    if (path.back() != L'\\') path += L'\\';

    WIN32_FIND_DATAW fd;
    std::wstring searchPath = path + L"*";
    HANDLE hFind = FindFirstFileExW(searchPath.c_str(), FindExInfoBasic, &fd, FindExSearchNameMatch, NULL, 0);

    if (hFind == INVALID_HANDLE_VALUE) return;

    do {
        std::wstring name = fd.cFileName;
        if (name == L"." || name == L"..") continue;

        // Skip the suite itself and protected system folders
        if (_wcsicmp(name.c_str(), L"integrity_check") == 0 || 
            _wcsicmp(name.c_str(), L"System Volume Information") == 0 || 
            _wcsicmp(name.c_str(), L"$RECYCLE.BIN") == 0) continue;

        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            calculateSize(path + name, result);
        } else {
            result.totalBytes += ((unsigned __int64)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
        }
    } while (FindNextFileW(hFind, &fd));

    FindClose(hFind);
}

int wmain(int argc, wchar_t* argv[]) {
    if (argc < 2) {
        std::wcerr << L"Error: Missing path." << std::endl;
        return 1;
    }

    std::wstring root = argv[1];
    DWORD dwAttrib = GetFileAttributesW(root.c_str());
    if (dwAttrib == INVALID_FILE_ATTRIBUTES || !(dwAttrib & FILE_ATTRIBUTE_DIRECTORY)) {
        std::wcerr << L"Error: Path invalid: " << root << std::endl;
        return 2;
    }

    ScanResult results;
    calculateSize(root, results);

    // Calculation: 60MB/s (Conservative HDD hashing speed)
    unsigned __int64 estSeconds = (results.totalBytes > 0) ? (results.totalBytes / (60ULL * 1024 * 1024)) : 0;

    if (results.totalBytes == 0) {
        std::wcout << L"Estimated Time to Rebuild Baseline: 0 Minutes" << std::endl;
    } else if (estSeconds < 60) {
        std::wcout << L"Estimated Time to Rebuild Baseline: < 1 Minute" << std::endl;
    } else if (estSeconds < 3600) {
        std::wcout << L"Estimated Time to Rebuild Baseline: ~" << (estSeconds / 60) << L" Minutes" << std::endl;
    } else {
        printf("Estimated Time to Rebuild Baseline: ~%.1f Hours\n", (double)estSeconds / 3600.0);
    }

    return 0;
}