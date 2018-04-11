//------------------------------------------------------------------------
// i2c_api.cpp
//
// API for the I2C Controller
//
//------------------------------------------------------------------------
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
// 
//------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "okFrontPanelDLL.h"
#include "i2c_api.h"


#define I2C_TRIGIN                (0x50)
#define I2C_TRIGOUT               (0x70)
#define I2C_WIREIN_DATA           (0x10)
#define I2C_WIREOUT_DATA          (0x30)

#define I2C_TRIGIN_GO             (0)
#define I2C_TRIGIN_MEM_RESET      (1)
#define I2C_TRIGIN_MEM_WRITE      (2)
#define I2C_TRIGIN_MEM_READ       (3)
#define I2C_TRIGOUT_DONE          (0)

#define I2C_MAX_TIMEOUT_MS        (250)


using namespace OpalKelly;


#if defined(_WIN32)
	#include <windows.h>
	#define strncpy strncpy_s
	#define sscanf  sscanf_s
#endif
#if defined(__linux__) || defined(__APPLE__)
	#include <unistd.h>
	#define Sleep(ms)   usleep(ms*1000)
#endif
#if defined(__QNX__)
	#include <unistd.h>
	#define Sleep(ms)   usleep((useconds_t) (ms*1000));
#endif


I2C::I2C(okCFrontPanel *dev)
{
	m_dev = dev;
	m_dev->SetWireInValue(0x00, 0x0001, 0x0001);
	m_dev->UpdateWireIns();
	m_dev->SetWireInValue(0x00, 0x0000, 0x0001);
	m_dev->UpdateWireIns();
}



I2C::~I2C()
{
}


#if (0)
int
I2C::GetAPIDateTime(std::string date, std::string time)
{
	date.assign(__DATE__);
	time.assign(__TIME__);
	return(I2C::NoError);
}



/// TODO: This is presently unsupported.
int
I2C::GetFirmwareVersion(unsigned int *version, unsigned int *capability)
{
	if (false == m_dev->IsOpen()) {
		return(I2C::DeviceNotOpen);
	}

	m_dev->UpdateWireOuts();
	*version    = m_dev->GetWireOutValue(0x20);
	*capability = m_dev->GetWireOutValue(0x21);
	return(I2C::NoError);
}
#endif



/// STARTS - Defines the preamble bytes after which a start bit is 
///      transmitted. For example, if STARTS=0x04, a start bit is
///      transmitted after the 3rd preamble byte.
/// STOPS - Defines the preamble bytes after which a stop bit is 
///      transmitted. For example, if STOPS=0x04, a stop bit is
///      transmitted after the 3rd preamble byte.
/// LENGTH - Length of the preamble in bytes.
///
/// Note: If there is a one in the same position for both STARTS and STOPS,
///       the stop takes precedence.
void
I2C::Configure(unsigned char length, unsigned char starts, unsigned char stops, const unsigned char *preamble)
{
	if (false == m_dev->IsOpen()) {
		throw DeviceNotOpenException();
	}
	if (length > 7) {
		throw DataTooLongException();
	}
	
	int i;
	m_pBuf[0] = length;
	m_pBuf[1] = starts;
	m_pBuf[2] = stops;
	m_pBuf[3] = 0;        // Payload length will be provided later.
	for (i=0; i<length; i++) {
		m_pBuf[4+i] = preamble[i];
	}
	m_nDataStart = 4+i;
}



void
I2C::Transmit(const unsigned char *data, unsigned int length)
{
	int i;
	
	
	if (false == m_dev->IsOpen()) {
		throw DeviceNotOpenException();
	}
	
	if (0 == length) {
		return;
	}
	if ((m_nDataStart + length) >= I2C::MaxBufferLength) {
		throw DataTooLongException();
	}
	
	m_pBuf[3] = length;
	for (i=0; i<length; i++) {
		m_pBuf[m_nDataStart+i] = data[i];
	}

	// Reset the memory pointer and transfer the buffer.
	m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET);
	for (i=0; i<(length+m_nDataStart); i++) {
		m_dev->SetWireInValue(I2C_WIREIN_DATA, m_pBuf[i], 0x00ff);
		m_dev->UpdateWireIns();
		m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_WRITE);
	}
	
	// Start I2C transaction
	m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_GO);
	
	// Wait for transaction to finish
	for (i=0; i<(I2C_MAX_TIMEOUT_MS/10); i++) {
		m_dev->UpdateTriggerOuts();
		if (0 == m_dev->IsTriggered(I2C_TRIGOUT, (1<<I2C_TRIGOUT_DONE))) {
			return;
		}
		Sleep(10);
	}

	throw TimeoutException();
}



void
I2C::Receive(unsigned char *data, unsigned int length)
{
	if (false == m_dev->IsOpen()) {
		throw DeviceNotOpenException();
	}

	if (0 == length) {
		return;
	}
	if (length >= I2C::MaxBufferLength) {
		throw DataTooLongException();
	}
	
	int i;
	m_pBuf[0] |= 0x80;
	m_pBuf[3] = length;
	
	// Reset the memory pointer and transfer the buffer.
	m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET);
	for (i=0; i<m_nDataStart; i++) {
		m_dev->SetWireInValue(I2C_WIREIN_DATA, m_pBuf[i], 0x00ff);
		m_dev->UpdateWireIns();
		m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_WRITE);
	}
	
	// Start I2C transaction
	m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_GO);
	
	// Wait for transaction to finish
	for (i=0; i<(I2C_MAX_TIMEOUT_MS/10); i++) {
		m_dev->UpdateTriggerOuts();
		if (0 == m_dev->IsTriggered(I2C_TRIGOUT, (1<<I2C_TRIGOUT_DONE))) {
			// Reset the memory pointer
			m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET);
			for (i=0; i<length; i++) {
				m_dev->UpdateWireOuts();
				data[i] = m_dev->GetWireOutValue(I2C_WIREOUT_DATA);
				m_dev->ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_READ);
			}
			return;
		}
		Sleep(10);
	}

	throw TimeoutException();
}



void
I2C::Write8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, const unsigned char *data)
{
	unsigned char buf[256];
	buf[0] = (devAddr & 0xfe);
	buf[1] = regAddr;
	Configure(2, 0x00, 0x00, buf);
	Transmit(data, length);
}



/// Sequence is
/// [START] DEV_ADDR(W) REG_ADDR [START] DEV_ADDR(R) VALUE
void
I2C::Read8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, unsigned char *data)
{
	unsigned char buf[256];
	buf[0] = (devAddr & 0xfe);
	buf[1] = regAddr;
	buf[2] = (devAddr | 0x01);
	Configure(3, 0x02, 0x00, buf);
	Receive(buf, length);
	for (int i=0; i<length; i++) {
		data[i] = buf[i];
	}
}
