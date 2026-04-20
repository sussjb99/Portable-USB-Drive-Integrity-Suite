/* ============================================================
   PUDIS (Portable‑USB‑Drive‑Integrity‑Suite)
   File: deviceinfo.cpp
   Author: sussjb99
   Version: 1.0
   Last Modified: 2026-04-12
   Copyright (c) 2026 sussjb99. All rights reserved.
   Licensed under the MIT License. See LICENSE.txt for details.
   ============================================================ */



#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <array>
#include <memory>
#include <sstream>
#include <ctime>
#include <iomanip>

// Helper to escape XML special characters
std::string XmlEscape(std::string data) {
    size_t pos = 0;
    while ((pos = data.find('&', pos)) != std::string::npos) {
        data.replace(pos, 1, "&amp;");
        pos += 5;
    }
    return data;
}

std::string ToUpper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { 
        return (char)std::toupper(c); 
    });
    return s;
}

struct DriveStats {
    std::string letter, model, serial, totalGB, usedGB, freeGB, interface, tech, fsType; 
    std::string hours, temp, reallocated, health;
    bool isSystemDrive = false;
};

// Helper to extract existing XML blocks so we don't overwrite scan results
std::string ExtractBlock(const std::string& content, const std::string& tag) {
    std::string startTag = "<" + tag + ">";
    std::string endTag = "</" + tag + ">";
    size_t start = content.find(startTag);
    size_t end = content.find(endTag);
    if (start != std::string::npos && end != std::string::npos) {
        return content.substr(start, (end + endTag.length()) - start);
    }
    return "";
}

std::string GetProbeOutput() {
    std::array<char, 128> buffer;
    std::string result;
    // Note: Ensure full_probe.exe is in the path or same directory
    std::unique_ptr<FILE, decltype(&_pclose)> pipe(_popen("full_probe.exe", "r"), _pclose);
    if (!pipe) return "";
    while (fgets(buffer.data(), (int)buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

std::string GetJsonValue(const std::string& block, const std::string& key) {
    std::string searchKey = "\"" + key + "\":";
    size_t pos = block.find(searchKey);
    if (pos == std::string::npos) return "N/A";

    size_t valStart = block.find_first_not_of(" \t\n\r", pos + searchKey.length());
    if (valStart == std::string::npos) return "N/A";

    if (block[valStart] == '\"') {
        size_t start = valStart + 1;
        size_t end = block.find('\"', start);
        return (end == std::string::npos) ? "N/A" : block.substr(start, end - start);
    } else {
        size_t end = block.find_first_of(",\n\r}", valStart);
        std::string val = block.substr(valStart, end - valStart);
        val.erase(std::remove_if(val.begin(), val.end(), ::isspace), val.end());
        return val;
    }
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cout << "Usage: deviceInfo.exe [DriveLetter] [PathToXML]\n";
        return 1;
    }

    std::string targetDrive = ToUpper(argv[1]);
    if (!targetDrive.empty() && targetDrive.back() != ':') targetDrive += ":";

    std::string xmlPath = argv[2];
    
    // 1. Read existing XML to preserve scan data
    std::string existingContent;
    std::ifstream existingFile(xmlPath);
    if (existingFile) {
        std::stringstream ss;
        ss << existingFile.rdbuf();
        existingContent = ss.str();
        existingFile.close();
    }

    // 2. Get Probe Data
    std::string json = GetProbeOutput();
    if (json.empty()) {
        std::cerr << "Error: No output from full_probe.exe\n";
        return 1;
    }

    DriveStats stats;
    bool found = false;
    size_t start = 0;

    while ((start = json.find("{", start)) != std::string::npos) {
        size_t end = json.find("}", start);
        if (end == std::string::npos) break;
        
        std::string block = json.substr(start, end - start + 1);
        std::string foundLetter = ToUpper(GetJsonValue(block, "Letter"));
        
        if (foundLetter == targetDrive) {
            stats.letter = targetDrive;
            stats.model = GetJsonValue(block, "Model");
            stats.serial = GetJsonValue(block, "Serial");
            stats.totalGB = GetJsonValue(block, "TotalGB");
            stats.usedGB  = GetJsonValue(block, "UsedGB");
            stats.freeGB  = GetJsonValue(block, "FreeGB");
            stats.interface = GetJsonValue(block, "Interface");
            stats.tech = GetJsonValue(block, "Technology");
            stats.fsType = GetJsonValue(block, "FsType"); // Correctly targets "FsType" from your JSON
            stats.hours = GetJsonValue(block, "Hours");
            stats.temp = GetJsonValue(block, "Temp");
            stats.reallocated = GetJsonValue(block, "Reallocated_Sectors_Ct");
            stats.health = GetJsonValue(block, "Health");
            
            if (GetJsonValue(block, "Stress_Profile") == "System Drive" || targetDrive == "C:") {
                stats.isSystemDrive = true;
            }
            found = true;
            break;
        }
        start = end + 1;
    }

    if (!found) {
        std::cerr << "Drive " << targetDrive << " not found in probe data.\n";
        return 1;
    }

    // 3. Extract blocks to preserve (Integrity/Surface)
    std::string integrityBlock = ExtractBlock(existingContent, "FileIntegrityScan");
    std::string surfaceBlock = ExtractBlock(existingContent, "SurfaceScanInfo");
    std::string smartBlock = "";
    
    if (stats.health != "N/A") {
        smartBlock = ExtractBlock(existingContent, "SmartHealthStatus");
    }

    // 4. Generate current hardware probe timestamp
    char tB[64];
    time_t n = time(0);
    tm l;
    localtime_s(&l, &n);
    strftime(tB, sizeof(tB), "%Y-%m-%d %H:%M:%S", &l);

    // 5. Write Unified XML
    std::ofstream xml(xmlPath);
    if (!xml) {
        std::cerr << "Error: Cannot write to " << xmlPath << "\n";
        return 1;
    }

    xml << "<DriveBabySitter>\n"
        << "  <Metadata>\n"
        << "    <LastHardwareProbe>" << tB << "</LastHardwareProbe>\n"
        << "  </Metadata>\n"
        << "  <HardwareIdentity>\n"
        << "    <Model>" << XmlEscape(stats.model) << "</Model>\n"
        << "    <Serial>" << XmlEscape(stats.serial) << "</Serial>\n"
        << "    <Interface>" << stats.interface << "</Interface>\n"
        << "    <Technology>" << stats.tech << "</Technology>\n"
        << "    <FileSystem>" << stats.fsType << "</FileSystem>\n" 
        << "  </HardwareIdentity>\n"
        << "  <StorageCapacity>\n"
        << "    <TotalGB>" << stats.totalGB << "</TotalGB>\n"
        << "    <UsedGB>" << stats.usedGB << "</UsedGB>\n"
        << "    <FreeGB>" << stats.freeGB << "</FreeGB>\n"
        << "  </StorageCapacity>\n"
        << "  <HardwareVitals>\n"
        << "    <PowerOnHours>" << stats.hours << "</PowerOnHours>\n"
        << "    <Temperature>" << stats.temp << "</Temperature>\n"
        << "    <ReallocatedSectors>" << stats.reallocated << "</ReallocatedSectors>\n"
        << "    <HealthRating>" << stats.health << "</HealthRating>\n"
        << "  </HardwareVitals>\n"
        << "  <Policy>\n"
        << "    <StressTestAllowed>" << (stats.isSystemDrive ? "False" : "True") << "</StressTestAllowed>\n"
        << "    <Notes>" << (stats.isSystemDrive ? "System Drive Protection Active" : "Standard Drive") << "</Notes>\n"
        << "  </Policy>\n";

    if (stats.health == "N/A") {
        xml << "  <SmartHealthStatus>\n"
            << "    <SmartStatus>N/A</SmartStatus>\n"
            << "  </SmartHealthStatus>\n";
    } else if (!smartBlock.empty()) {
        xml << "  " << smartBlock << "\n";
    }

    if (!integrityBlock.empty()) xml << "  " << integrityBlock << "\n";
    if (!surfaceBlock.empty())   xml << "  " << surfaceBlock << "\n";

    xml << "</DriveBabySitter>\n";
    xml.close();

    std::cout << "SUCCESS: Hardware data updated for " << targetDrive << " [" << tB << "]\n";
    return 0;
}
