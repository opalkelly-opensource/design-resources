// ----------------------------------------------------------------------------------------
// This function utilizes the `fft.h` library to implement a real input
// pipelined streaming fixed point FFT with transform size of 32, input
// data width of 14 bits and output data width of 19 bits. See
// the associated `rfft32_i14_o19.h` header file for the transform size,
// input type, and output type definitions.
//
// ----------------------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
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

#include "rfft32_i14_o19.h"

void rfft32_i14_o19(fixedInputType dataIn[CONST_32_POINT], fixedOutputComplexType dataOut[CONST_32_POINT]){
    #pragma HLS DATAFLOW
    #pragma HLS INTERFACE axis register off port=dataOut
    #pragma HLS INTERFACE axis register off port=dataIn
    
    static fixedInputComplexType dataInComplex[CONST_32_POINT];
    
    // Convert the input data to the complex type for input into the DIF_FFT library
    for (int i = 0; i < CONST_32_POINT; i++) {
        #pragma HLS PIPELINE rewind
        dataInComplex[i] = fixedInputComplexType(dataIn[i], 0.0);
    }

    fft<CONST_32_POINT>(dataInComplex, dataOut);
}
