===============================================
Portable Drive Baby Sitter - Integrity Suite
Copyright (c) 2026 sussjb99
All rights reserved.
Last Updated: 2026/04/12
===============================================


C++ Source Code Created by Author sussjb99
===============================================
- baselineXML_estimate.cpp
	Estimates the amount of time required
	to create the baseline.XML file

- corruptor.cpp
	Used to create a sample corrupted file
	for validating and testing file recovery

- deviceinfo.cpp
	Used to collect parameters associated
	with the storage device being tested.

- fullprobe.cpp
	Use to collect parameters associated
	with all the storage devices currently
	connected to the computer.

- FileListGen.cpp
	Use to quickly generate a list of files.
	Excludeds System and Integrity_Check folders.

- scantime_estimate.cpp
	Used to estimate the amount of time 
	that will be used to perform a surface
	scan.

- surface_scan.cpp
	Performs a surface scan by reading and writing
	blocks of information on the drive and validating
	their integrity.


=======================================================
3rd Party Executables
=======================================================

par2.exe Turbo

Original Source code is located here:
https://github.com/animetosho/par2cmdline-turbo

The source code for this program was downloaded
and modified to faciliate utilization of the @filelist 
parameter. 

A proposted patch has been provided back to the original
author. 

This program creates a data set, which in some cases, can 
be used to recovery files that have experienced bit rot. 
However, it can not always recovery such files so 
always employ backups in addition to this software.



=======================================================
smartctl.exe

Executable was downloaded from here: 
https://github.com/smartmontools/smartmontools/releases

This program retrieves information from storage
device that have the capacity to respond to 
SMART Commands.


=======================================================
hashdeep64.exe

Executabe was downloaded from here:
https://github.com/WSU-CDSC/hashcheck

This program takes as input a list of files and produces
as output an XML file which contain key information such 
as the filename, modified time, and hash value. 

This information is very valuable because objects that
have the same filename and mtime but have a different hash 
value, are candidates for repairs due to bit rot.


=======================================================
END OF DOCUMENT
=======================================================

