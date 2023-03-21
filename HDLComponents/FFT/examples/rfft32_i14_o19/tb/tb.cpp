// ----------------------------------------------------------------------------------------
// The data this testbench tests against is generated from Python using
// Numpy. The example's input and output types are of a finite bit width,
// defined in the example's header file. The finite bit width determines
// the step size between successive bits. This causes inconsistencies from
// the Numpy calculated values because of quantization. Failure occurs if
// the FFT's output is outside of some acceptable threshold.  
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

#include <iostream>
#include <stdlib.h>
#include <fstream>
#include <complex>
#include <hls_math.h>
#include <complex.h>
#include <ap_fixed.h>

#include "../rfft32_i14_o19.h"

#define NORM_TOLERANCE 0.1

int main()
{
    fixedInputType dataIn[CONST_32_POINT];
    fixedOutputComplexType dataOut[CONST_32_POINT];
    floatComplexType fftExpected[CONST_32_POINT];

    std::ifstream inputRealValues("inputRealValues.txt");
    std::ifstream outputExpectedComplexValues("outputExpectedComplexValues.txt");


    // First we pull out the expected outputs from the text files
    float realWide, complexWide;
    for(int i = 0; i < CONST_32_POINT; i++){
        outputExpectedComplexValues >> realWide >> complexWide;
        fftExpected[i]=floatComplexType(realWide,complexWide);
    }
    float real;
    for(int i = 0; i < CONST_32_POINT; i++){
        inputRealValues >> real;
        dataIn[i]=fixedInputType(real);
    }

    inputRealValues.close();
    outputExpectedComplexValues.close();

    rfft32_i14_o19(dataIn,dataOut);

    // Now we perform the comparisons
    int numErrors=0;
    float maxDifference = 0;
    for(int k=0; k<CONST_32_POINT; k++){
        // We cast dataOut into a larger container before taking norm so it doesn't overflow
        float normDiff = std::norm(fftExpected[k]) - (float)std::norm((std::complex<ap_fixed<32,16>>)dataOut[k]);
        float absoluteNorm = abs(normDiff);
        std::cout << "Exp: " << fftExpected[k] << " \t- Got: " << dataOut[k] << " \t- Norm: " << absoluteNorm << std::endl;
        if (absoluteNorm > NORM_TOLERANCE) {
            numErrors++;
        }
        if (absoluteNorm > maxDifference){
            maxDifference = absoluteNorm;
        }
    }
    std::cout << "Max norm difference:" << maxDifference << std::endl;

    if (numErrors == 0) {
        std::cout << "Tests have passed!" << std::endl;
    } else {
        std::cout << "Tests have failed! Number of failing tests:" << numErrors << std::endl;
    }
    return numErrors;

}
