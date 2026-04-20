/* ============================================================
   PUDIS (Portable‑USB‑Drive‑Integrity‑Suite)
   File: FileListGen.cpp
   Author: sussjb99
   Version: 1.0
   Last Modified: 2026-04-12
   Copyright (c) 2026 sussjb99. All rights reserved.
   Licensed under the MIT License. See LICENSE.txt for details.
   ============================================================ */



#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

std::string utf8_encode(const std::wstring &wstr) {
    if (wstr.empty()) return std::string();
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

// Pass path by reference to avoid copying strings
void listFiles(std::wstring& path, std::ofstream& outFile, const std::wstring& excludeToken) {
    size_t baseLength = path.length();
    
    // Ensure we don't add a slash if the path already ends in one (like H:\)
    if (path.back() != L'\\') {
        path += L'\\';
        baseLength++;
    }

    std::wstring searchPath = path + L"*";
    WIN32_FIND_DATAW fd;
    HANDLE hFind = FindFirstFileExW(searchPath.c_str(), FindExInfoBasic, &fd, FindExSearchNameMatch, NULL, 0);

    if (hFind == INVALID_HANDLE_VALUE) return;

    do {
        std::wstring name = fd.cFileName;
        if (name != L"." && name != L"..") {
            
            // Re-use the existing path string to save memory allocations
            path.append(name);

            // Case-insensitive comparison using _wcsicmp
            // Returns 0 if strings match regardless of case (e.g. Integrity_Check == integrity_check)
            if (_wcsicmp(name.c_str(), excludeToken.c_str()) == 0 || 
                _wcsicmp(name.c_str(), L"System Volume Information") == 0 || 
                _wcsicmp(name.c_str(), L"$RECYCLE.BIN") == 0) 
            {
                path.erase(baseLength); // Reset path for next item
                continue;
            }

            if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                listFiles(path, outFile, excludeToken);
            } else {
                outFile << utf8_encode(path) << "\n";
            }

            // Backtrack: remove the filename we just added
            path.erase(baseLength);
        }
    } while (FindNextFileW(hFind, &fd));

    FindClose(hFind);
}

int wmain(int argc, wchar_t* argv[]) {
    if (argc < 3) {
        std::wcout << L"Usage: FileListGen.exe <Directory> <OutputFile>" << std::endl;
        return 1;
    }

    std::wstring root = argv[1];
    std::wstring outPath = argv[2];

    // Remove trailing slash from root to handle normalization inside the function
    if (root.length() > 3 && root.back() == L'\\') {
        root.pop_back();
    }

    std::ofstream outFile(outPath, std::ios::out | std::ios::binary);
    
    // Performance Tweak: Set a large 1MB buffer for the file stream
    std::vector<char> buffer(1024 * 1024);
    outFile.rdbuf()->pubsetbuf(buffer.data(), buffer.size());

    if (!outFile.is_open()) return 1;

    std::wcout << L"Scanning: " << root << std::endl;
    
    // This will now match Integrity_Check, integrity_check, etc.
    listFiles(root, outFile, L"integrity_check");

    outFile.close();
    std::wcout << L"Done!" << std::endl;
    return 0;
}
