//------------------------------------------------------------------------
// i2c_api.h
//
// Class definition for detector communication.
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
//------------------------------------------------------------------------

#ifndef __i2c_api_H__
#define __i2c_api_H__

#include <string.h>

#include "i2c_api.h"
#include "okFrontPanelDLL.h"


namespace OpalKelly {

class DeviceNotOpenException : public std::exception {
public:
	DeviceNotOpenException()
		: std::exception() { };
};
class OperationFailedException : public std::exception {
public:
	OperationFailedException()
		: std::exception() { };
};
class TimeoutException : public std::exception {
public:
	TimeoutException()
		: std::exception() { };
};
class DataTooLongException : public std::exception {
public:
	DataTooLongException()
		: std::exception() { };
};


class I2C
{
public:
	static const int MaxBufferLength = 64;
	
protected:
	okCFrontPanel  *m_dev;
	unsigned char  m_pBuf[MaxBufferLength];
	int            m_nDataStart;


private:
	void fullReset();
	void i2cWrite(unsigned int devAddr, unsigned long addr, unsigned long data);
	unsigned long i2cRead(unsigned int devAddr, unsigned long addr);


public:
	I2C(okCFrontPanel *dev);
	~I2C();

	/// Returns the build date and time for the API.
	void GetAPIDateTime(std::string date, std::string time);

	/// Retrieve the firmware version and capability.
	void GetFirmwareVersion(unsigned int *version, unsigned int *capability);

	/// 
	void Configure(unsigned char length, unsigned char starts, unsigned char stops, const unsigned char *preamble);

	///
	void Receive(unsigned char *data, unsigned int length);

	///
	void Transmit(const unsigned char *data, unsigned int length);
	
	/// Write (8-bit addressing).
	void Write8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, const unsigned char *data);
	
	/// Read (8-bit addressing).
	void Read8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, unsigned char *data);
};

}; // namespace OpalKelly

#endif // __i2c_api_H__
