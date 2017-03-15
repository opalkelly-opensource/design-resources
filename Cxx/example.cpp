//------------------------------------------------------------------------
// example.cpp
//
// Example usage of I2C API class.
//
// Copyright (c) 2014-2017 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <string.h>

#include "okFrontPanelDLL.h"
#include "i2c_api.h"

// This is the bitfile to be used through these examples.
#define BITFILE_NAME   "toplevel.bit"

using namespace OpalKelly;


#if defined(_WIN32)
	#include <Windows.h>   // for Sleep()
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



void
ExWriteEEPROM_8bit(okCFrontPanel *dev)
{
	I2C i2c(dev);
	unsigned char preamble[8], starts, stops, data[256];

	preamble[0] = 0xA0; // devAddr (write)
	preamble[1] = 0x00; // byteAddress
	starts = 0x00;
	stops = 0x00;
	i2c.Configure(2, starts, stops, preamble);
	data[0] = 0xDE;
	data[1] = 0xAD;
	data[2] = 0x00;
	data[3] = 0xF0;
	data[4] = 0x0D;
	data[5] = 0x00;
	data[6] = 0xBE;
	data[7] = 0xEF;
	data[8] = 0x00;
	data[9] = 0xFF;
	
	i2c.Transmit(data, 10);

	for (int i = 0; i < 10; i++) {
		printf("Wrote: %02X to memory\n", data[i]);
	}
}



void
ExWriteEEPROM_16bit(okCFrontPanel *dev)
{
	I2C i2c(dev);
	unsigned char preamble[8], starts, stops, data[256];

	preamble[0] = 0xA0; // devAddr (write)
	preamble[1] = 0x00; // byteAddress (MSB)
	preamble[2] = 0x00; // byteAddress (LSB)
	starts = 0x00;
	stops = 0x00;
	i2c.Configure(3, starts, stops, preamble);
	data[0] = 0xDE;
	data[1] = 0xAD;
	data[2] = 0x00;
	data[3] = 0xF0;
	data[4] = 0x0D;
	data[5] = 0x00;
	data[6] = 0xBE;
	data[7] = 0xEF;
	data[8] = 0x00;
	data[9] = 0xFF;
	
	i2c.Transmit(data, 10);

	for (int i = 0; i < 10; i++) {
		printf("Wrote: %02X to memory\n", data[i]);
	}
}



void
ExReadEEPROM_8bit(okCFrontPanel *dev)
{
	I2C i2c(dev);
	unsigned char preamble[8], starts, stops, data[256];

	preamble[0] = 0xA0; // devAddr (write)
	preamble[1] = 0x00; // byteAddress
	preamble[2] = 0xA1; // devAddr (read)
	starts = 0x02;
	stops = 0x00;
	i2c.Configure(3, starts, stops, preamble);
	
	i2c.Receive(data, 10);

	for (int i = 0; i < 10; i++) {
		printf("Read: %02X from memory\n", data[i]);
	}
}



void
ExReadEEPROM_16bit(okCFrontPanel *dev)
{
	I2C i2c(dev);
	unsigned char preamble[8], starts, stops, data[256];

	preamble[0] = 0xA0; // devAddr (write)
	preamble[1] = 0x00; // byteAddress (MSB)
	preamble[2] = 0x00; // byteAddress (LSB)
	preamble[3] = 0xA1; // devAddr (read)
	starts = 0x04;
	stops = 0x00;
	i2c.Configure(4, starts, stops, preamble);
	
	i2c.Receive(data, 10);

	for (int i = 0; i < 10; i++) {
		printf("Read: %02X from memory\n", data[i]);
	}
}



//--------------------
// L3G4200D Registers
//--------------------
#define WHO_AM_I       0x0F
#define CTRL_REG1      0x20
#define CTRL_REG2      0x21
#define CTRL_REG3      0x22
#define CTRL_REG4      0x23
#define CTRL_REG5      0x24
#define REFERENCE      0x25
#define OUT_TEMP       0x26
#define STATUS_REG     0x27
#define OUT_X_L        0x28
#define OUT_X_H        0x29
#define OUT_Y_L        0x2A
#define OUT_Y_H        0x2B
#define OUT_Z_L        0x2C
#define OUT_Z_H        0x2D
#define FIFO_CTRL_REG  0x2E
#define FIFO_SRC_REG   0x2F
#define INT1_CFG       0x30
#define INT1_SRC       0x31
#define INT1_TSH_XH    0x32
#define INT1_TSH_XL    0x33
#define INT1_TSH_YH    0x34
#define INT1_TSH_YL    0x35
#define INT1_TSH_ZH    0x36
#define INT1_TSH_ZL    0x37
#define INT1_DURATION  0x38
#define AUTO_INCREMENT 0x80
void
Gyro(okCFrontPanel *dev)
{
	I2C i2c(dev);
	
	unsigned char x;
	unsigned char devAddr = 0xD0;
	
	// Let's first check that we're communicating properly
	// The WHO_AM_I register should read 0xD3
	i2c.Read8(devAddr, WHO_AM_I, 1, &x);
	if (x != 0xD3) {
		printf("Not the gyro! (0x%02X)\n", x);
	}
 
	// Enable x, y, z and turn off power down:
	x = 0b00001111;
	i2c.Write8(devAddr, CTRL_REG1, 1, &x);
 
	// If you'd like to adjust/use the HPF, you can edit the line below to configure CTRL_REG2:
	x = 0b00000000;
	i2c.Write8(devAddr, CTRL_REG2, 1, &x);
 
	// Configure CTRL_REG3 to generate data ready interrupt on INT2
	// No interrupts used on INT1, if you'd like to configure INT1
	// or INT2 otherwise, consult the datasheet:
	x = 0b00001000;
	i2c.Write8(devAddr, CTRL_REG3, 1, &x);
 
	// CTRL_REG4 controls the full-scale range, among other things:
	unsigned char fullScale = 0x03;
	fullScale &= 0x03;
	x = fullScale<<4;
	i2c.Write8(devAddr, CTRL_REG4, 1, &x);
 
	// CTRL_REG5 controls high-pass filtering of outputs, use it
	// if you'd like:
	x = 0b00000000;
	i2c.Write8(devAddr, CTRL_REG5, 1, &x);
	
	
	int gx, gy, gz;
	unsigned char buf[16];
	while (1) {
		Sleep(1);
		i2c.Read8(devAddr, AUTO_INCREMENT | OUT_X_L, 6, buf);
		gx  = (buf[1] & 0xff) << 8;
		gx |= (buf[0] & 0xff);
		gy  = (buf[3] & 0xff) << 8;
		gy |= (buf[2] & 0xff);
		gz  = (buf[5] & 0xff) << 8;
		gz |= (buf[4] & 0xff);
		
		printf("X:%04X Y:%04X Z:%04X\n", gx, gy, gz);
	}
}



int
main(int argc, char *argv[])
{
	char dll_date[32], dll_time[32];


	printf("---- Opal Kelly ---- I2C Example ----\n");
	if (FALSE == okFrontPanelDLL_LoadLib(NULL)) {
		printf("FrontPanel DLL could not be loaded.\n");
		exit(-1);
	}
	okFrontPanelDLL_GetVersion(dll_date, dll_time);
	printf("FrontPanel DLL loaded.  Built: %s  %s\n", dll_date, dll_time);


	okCFrontPanel *dev = new okCFrontPanel;
	dev->OpenBySerial("");
	dev->ConfigureFPGA(BITFILE_NAME);
	if (dev->IsFrontPanelEnabled() == false) {
		printf("No FrontPanel\n");
		exit(-1);
	}

	Gyro(dev);
	//ExWriteEEPROM_8bit(dev);
	//ExWriteEEPROM_16bit(dev);
	//ExReadEEPROM_8bit(dev);
	//ExReadEEPROM_16bit(dev);

	delete dev;
	return(0);
}
