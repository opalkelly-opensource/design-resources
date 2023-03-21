// ----------------------------------------------------------------------------------------
// The data this testbench tests against is generated from Python using
// Numpy. The example's input and output types are of a finite bit width,
// defined in the example's header file. The finite bit width determines
// the step size between successive bits. This causes inconsistencies from
// the Numpy calculated values because of quantization. Failure occurs if
// the IFFT's output is outside of some acceptable threshold.  
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

#include "../irfft256_i18_o10_norm.h"

#define REAL_TOLERANCE 0.01

int main()
{
    fixedInputComplexType dataIn[CONST_256_POINT];
    fixedOutputType dataOut[CONST_256_POINT];
    float irfftExpected[CONST_256_POINT];

    std::ifstream outputExpectedRealValues("outputExpectedRealValues.txt");
    std::ifstream inputComplexValues("inputComplexValues.txt");


    // First we pull out the expected outputs from the text files
    float real;
    for(int i = 0; i < CONST_256_POINT; i++){
        outputExpectedRealValues >> real;
        irfftExpected[i]=real;
    }
    float realWide, complexWide;
    for(int i = 0; i < CONST_256_POINT; i++){
        inputComplexValues >> realWide >> complexWide;
        dataIn[i]=fixedInputComplexType(realWide, complexWide);
    }

    outputExpectedRealValues.close();
    inputComplexValues.close();

    irfft256_i18_o10_norm(dataIn,dataOut);

    // Now we perform the comparisons
    int numErrors=0;
    float maxDifference = 0;
    for(int k=0; k<CONST_256_POINT; k++){
        float difference = abs(irfftExpected[k]) - abs((float)dataOut[k]);
        float absoluteDifference = abs(difference);
        std::cout << "Exp: " << irfftExpected[k] << " \t- Got: " << dataOut[k] << " \t- Norm: " << absoluteDifference << std::endl;
        if (difference > REAL_TOLERANCE) {
            numErrors++;
        }
        if (difference > maxDifference){
            maxDifference = difference;
        }
    }
    std::cout << "Max real difference:" << maxDifference << std::endl;


    if (numErrors == 0) {
        std::cout << "Tests have passed!" << std::endl;
    } else {
        std::cout << "Tests have failed! Number of failing tests:" << numErrors << std::endl;
    }
    return numErrors;

}
