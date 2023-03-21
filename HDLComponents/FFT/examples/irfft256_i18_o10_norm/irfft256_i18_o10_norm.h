// ----------------------------------------------------------------------------------------
// This header holds the example's definitions for the transform size, input data
// type, and output data type definitions.
// Recall the library's template parameter restrictions:
//   - The transform size (CONST_256_POINT) must be a power of two.
//   - The input and output types must be `std::complex<ap_fixed<>>` .
//
// The TB's Numpy generated real only test data is between the range of [-1.0, 1.0).
// Imagine fitting this into the type ap_fixed<10,1>, which only has one
// integer bit (to the left of the decimal point) that acts as the sign bit. We
// send our Numpy generated real data through the Numpy FFT. The Numpy 8 stage,
// 256 point FFT, will experience 8 bits of growth, so we have sized the complex
// number input to 18 bits, with 9 integer bits (to the left of the decimal point),
// i.e. ap_fixed<18,9>, to account for this bit growth. Ultimately we know we are
// converging back to the ap_fixed<10,1> of the generated real only test data that
// we started with. This is why we have sized the output to ap_fixed<10,1>.
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

#include <complex.h>
#include <ap_fixed.h>
#include "../../fft.h"

// Because the function and file names for this implementation have the number of points
// in them i.e. irfft256, you should not change this #define. Although it is left in for
// instructional purposes to highlight the locations requiring change if a different
// point FFT is required.
#define CONST_256_POINT 256

typedef ap_fixed<18,9> fixedInputType;
typedef ap_fixed<10,1> fixedOutputType;
typedef std::complex<fixedInputType> fixedInputComplexType;
typedef std::complex<fixedOutputType> fixedOutputComplexType;
typedef std::complex<float> floatComplexType;

void irfft256_i18_o10_norm(fixedInputComplexType dataIn[CONST_256_POINT], fixedOutputType dataOut[CONST_256_POINT]);
