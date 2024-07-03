// ----------------------------------------------------------------------------------------
// This function utilizes the `fft.h` library to implement a 1/N normalized real output
// pipelined streaming fixed point IFFT with transform size of 1024, input data width of
// 20 bits and output data width of 12 bits.
//
// ----------------------------------------------------------------------------------------
// Copyright (c) 2024 Opal Kelly Incorporated
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
// ----------------------------------------------------------------------------------------

#include <complex.h>
#include <ap_fixed.h>
#include "../fft.h"

#define CONST_1024_POINTS 1024

typedef ap_fixed<22,11> fixedInputType;
typedef ap_fixed<12,1> fixedOutputType;
typedef std::complex<fixedInputType> fixedInputComplexType;

void irfft1024_i22_o12_norm(fixedInputComplexType dataIn[CONST_1024_POINTS], fixedOutputType dataOut[CONST_1024_POINTS]){
    #pragma HLS DATAFLOW

    static fixedInputComplexType dataOutComplex[CONST_1024_POINTS];
    
    ifft<CONST_1024_POINTS>(dataIn, dataOutComplex);
    
    // Apply a 1/N normalization factor to the output.
    for (int i=0; i<CONST_1024_POINTS; i++) {
		#pragma HLS PIPELINE rewind
    	dataOut[i] = dataOutComplex[i].real()/CONST_1024_POINTS;
    }
}
