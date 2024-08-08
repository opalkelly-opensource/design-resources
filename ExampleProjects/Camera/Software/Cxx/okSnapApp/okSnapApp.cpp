//------------------------------------------------------------------------
// okSnapApp.cpp
//
// This is a simple command-line interface to the EVB100X evaluation
// board.  The class okCCamera provides most of the heavy-lifting and
// interface to the camera via the FrontPanel API.
//
// Copyright (c) 2011  Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#include <fstream>
#include <iostream>
#include <memory>

#include <cstdint>
#include <stdio.h>
#include <string.h>

#include "okFrontPanel.h"
#include "okCCamera.h"


#if defined(_WIN32)
  #define strncpy strncpy_s
  #define sscanf  sscanf_s
#endif
#if defined(__linux__) || defined(__APPLE__)
	#include <unistd.h>
	#define Sleep(ms)   usleep(ms*1000)
#endif
#if defined(__QNX__)
	#include <unistd.h>
	#include <stdlib.h>
	#include <sys/usbdi.h>
#define Sleep(ms)   usleep((useconds_t) (ms*1000));
#endif



inline unsigned char *okAlloc(unsigned int ulLen)
{
#if defined(__QNX__)
	return (unsigned char *)usbd_alloc(ulLen);
#else
	return new unsigned char[ulLen];
#endif
}



inline void okFree(unsigned char *data)
{

#if defined(__QNX__)
	usbd_free(data);
#else
	delete[] data;
#endif
}


static void
printUsage(char *progname)
{
	printf("Usage: %s [-m test_mode] [-d directory] [-f raw|bmp] outfile\n", progname);
	printf("   outfile    - Destination output file.\n");
	printf("   test_mode  - Test pattern - optional  (0-9)\n");
	printf("   directory  - The directory with the bit files\n");
	printf("   raw|bmp    - Output file format (raw RGrGbB data is used by default(\n");
	exit(-1);
}



void
saveBMP(std::ofstream& out, unsigned char *u8Image, int w, int h)
{
	auto setValue32 = [](unsigned char* addr, int val) {
		addr[0] = static_cast<unsigned char>(val);
		addr[1] = static_cast<unsigned char>(val >> 8);
		addr[2] = static_cast<unsigned char>(val >> 16);
		addr[3] = static_cast<unsigned char>(val >> 24);
	};

	// Use the raw array to avoid struct members alignment.
	unsigned char header[54] = { 'B','M', 0,0,0,0, 0,0, 0,0, 54,0,0,0, 40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0, 24,0 };

	const int headerSize = 54;
	// Each row must be aligned on a 4 bytes boundary.
	const int rowSize = ((w * 3 + 3) & 0xfffffffc);
	const int imageSize = rowSize * h;
	const int fileSize = headerSize + imageSize;

	setValue32(header + 2, fileSize);
	setValue32(header + 18, w);
	setValue32(header + 22, h);
	setValue32(header + 34, imageSize);

	unsigned char *rgbData = okAlloc(imageSize);
	unsigned char *srcRow = u8Image;
	unsigned char *dstRow = rgbData;
	for (int y = 0; y < h; ++y) {
		for (int x = 0; x < w; ++x) {
			unsigned char srcPixel = srcRow[x];
			unsigned char *dstPixel = dstRow + 3*x;
			if (y % 2 == 0) {
				if (x % 2 == 0) {
					// R
					dstPixel[0] = srcPixel;
					dstPixel[1] = dstPixel[2] = 0;
				} else {
					// Gr
					dstPixel[1] = srcPixel;
					dstPixel[0] = dstPixel[2] = 0;
				}
			} else {
				if (x % 2 == 0) {
					// Gb
					dstPixel[1] = srcPixel;
					dstPixel[0] = dstPixel[2] = 0;
				} else {
					// B
					dstPixel[2] = srcPixel;
					dstPixel[0] = dstPixel[1] = 0;
				}
			}
		}
		srcRow += w;
		dstRow += rowSize;
	}

	out.write(reinterpret_cast<char*>(&header), headerSize);
	out.write(reinterpret_cast<char*>(rgbData), imageSize);
	okFree(rgbData);
}



int
main(int argc, char *argv[])
{
	char outfilename[128];
	int mode, i;
	bool bmp;


	printf("---- Opal Kelly ---- FPGA-EVB100X okSnap v1.0 ----\n");
	printf("Using FrontPanel %s.\n", OpalKelly::GetAPIVersionString());

	if (argc < 2)
		printUsage(argv[0]);

	strncpy(outfilename, argv[argc-1], 128);
	printf("Capturing frame to %s \n", outfilename);

	mode = -1;
	bmp = false;
	std::string bitfilesDir;
	for (i=1; i<argc-2; i++) {
		if (!strncmp("-m", argv[i], 2)) {
			i++;
			sscanf(argv[i], "%d", &mode);
			if ((mode < 0) || (mode > 9))
				printUsage(argv[0]);
		} else if (!strncmp("-d", argv[i], 2)) {
			i++;
			bitfilesDir = argv[i];
			if (!bitfilesDir.empty()) {
				bitfilesDir += "/";
			}
		} else if (!strncmp("-f", argv[i], 2)) {
			i++;
			if (!strncmp("raw", argv[i], 2)) {
				bmp = false;
			} else if (!strncmp("bmp", argv[i], 2)) {
				bmp = true;
			} else {
				printf("Unknown file format for '-f' parameter\n");
				exit(-1);
			}
		}
	}

	// Open the device and determine the bit file path
	std::unique_ptr<OpalKelly::FrontPanel> dev(new OpalKelly::FrontPanel());
	dev->OpenBySerial();
	const auto infoOrError = okCCamera::GetInfo(dev.get());
	if (!infoOrError) {
		puts(infoOrError.error.c_str());
		exit(-1);
	}

	// Initialize the camera
	okCCamera *cam = new okCCamera();
	std::string msg;
	if (okCCamera::NoError != cam->Initialize(msg, dev.release(), bitfilesDir + infoOrError.info.bitfileDefaultName)) {
		printf("Camera initialization failed: %s\n", msg.c_str());
		exit(-1);
	}
	if (-1 == mode)
		cam->SetTestMode(false, okCCamera::ColorField);
	else
		cam->SetTestMode(true, (okCCamera::TestMode)mode);
	cam->SetSkips(0,0);

	unsigned long ulLen = cam->GetFrameBufferSize();
	unsigned char *u8Image = okAlloc(ulLen);
	auto defaultSize = cam->GetDefaultSize();
	cam->SetSize(defaultSize.m_width, defaultSize.m_height);
	cam->SetSkips(0,0);
	if (okCCamera::NoError != cam->SingleCapture(u8Image)) {
		printf("Image write process failed.\n");
		exit(-1);
	} else {
		std::ofstream f_out;
		f_out.open(outfilename, std::ios::binary);
		if (false == f_out.is_open()) {
			printf("Error: Output file could not be opened.\n");
		} else {
			if (bmp) {
				saveBMP(f_out, u8Image, defaultSize.m_width, defaultSize.m_height);
			} else {
				f_out.write((char *)u8Image, ulLen);
			}
			f_out.close();
			printf("Frame capture successful.\n");
		}
	}

	okFree(u8Image);
	delete cam;

	return(0);
}
