// Audio Pipe - Transfer audio data to the XEM7320 signal generator 
// sample through a FrontPanel Pipe endpoint.
//------------------------------------------------------------------------
// Copyright (c) 2014-2018 Opal Kelly Incorporated
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

#ifndef AUDIOPIPE_H
#define AUDIOPIPE_H

#include <stdint.h>
#include <sndfile.h>
#include <okFrontPanelDLL.h>

#include "AudioFile.h"

struct Config;

int handleArgs(int argc, char *argv[], Config *config);
int readIntoBuffer(SNDFILE *sndFile, int *buffer, int len);
bool allDigits(const std::string &str);
void generateSine(double freq, int32_t volume, int32_t seconds, unsigned int* buffer);

#endif
