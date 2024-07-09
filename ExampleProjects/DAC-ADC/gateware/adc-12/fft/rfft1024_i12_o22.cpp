// ----------------------------------------------------------------------------------------
// This function utilizes the `fft.h` library to implement a real input
// pipelined streaming fixed point FFT with transform size of 32, input
// data width of 14 bits and output data width of 19 bits. See
// the associated `rfft32_i14_o19.h` header file for the transform size,
// input type, and output type definitions.
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

typedef ap_fixed<12,1> fixedInputType;
typedef ap_fixed<22,11> fixedOutputType;
typedef std::complex<fixedInputType> fixedInputComplexType;
typedef std::complex<fixedOutputType> fixedOutputComplexType;
typedef std::complex<float> floatComplexType;


void rfft1024_i12_o22_norm(fixedInputType dataIn[CONST_1024_POINTS], fixedOutputComplexType dataOut[CONST_1024_POINTS]){
    #pragma HLS DATAFLOW
    
    static fixedInputComplexType dataInComplex[CONST_1024_POINTS];
    
    // Convert the input data to the complex type for input into the DIF_FFT library
    for (int i = 0; i < CONST_1024_POINTS; i++) {
        #pragma HLS PIPELINE rewind
        dataInComplex[i] = fixedInputComplexType(dataIn[i], 0.0);
    }

    fft<CONST_1024_POINTS>(dataInComplex, dataOut);
}
