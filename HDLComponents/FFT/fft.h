// ----------------------------------------------------------------------------------------
// A synthesizable templated library providing parameter inputs for transform size
// and input and output data widths for a fixed-point radix-2 decimation in frequency
// (DIF) fast Fourier transform (FFT) and the inverse (IFFT).
//
// Template Parameter Restrictions:
//   - The transform size (N) must be a power of two.
//   - The input and output types must be `std::complex<ap_fixed<>>` .
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

#ifndef __fft__
#define __fft__

#include <complex>
#include <ap_fixed.h>
#include <math.h>

// 7-Series has the DSP48E1 primitive with a 25*18 bit multiplier.
// UltraScale and UltraScale+ have the DSP48E2 primitive with a 27*18 bit multiplier.
// We target the 18 bit input of the DSP48 for the twiddle. The user's inputting
// bit width + bit growth (log2(transform size)) comes in on the other input.
// It is important to note that a bit width surpassing the size of a single DSP48
// will require multiple DSP48s to complete the multiplication. 
// Takeaway: Input bit width + log2(requested transform size) <= 25 (7-Series) or 27 (UltraScale and UltraScale+)
typedef ap_fixed<18,2> twiddleTypeForDSP48Primitive;

// Template metaprogramming for computing log2 at compile time.
template <int x>
 struct Log2 { enum { value = 1 + Log2<x/2>::value }; };
template <> struct Log2<1> { enum { value = 0 }; };

// Decimation in frequency "decimates" the output of the FFT, this just means 
// that the output is rearranged in a bit reversed order from the input. This 
// module undos that.
template <int N, typename T, typename U> void bitReversal(T dataIn[N], U dataOut[N]) {
    #pragma HLS DATAFLOW
    bitReversalLoop: for (int i = 0; i < N; i++) {
    #pragma HLS PIPELINE rewind
        dataOut[i] = dataIn[ap_uint<Log2<N>::value>(i).reverse()];
    }
}

// We follow the implementation for ROM in the "Implementing ROMs" section of UG1399.
template <int FFT, int N,typename T> void initTwiddleROM(std::complex<T> twiddleROM[N/2]){
    for (int i = 0; i < N/2; i++) {
        if (FFT) {
            twiddleROM[i] = std::complex<T>(T(cos(2 * M_PI * i / N)), T(-sin(2 * M_PI * i / N)));
        } else {
            twiddleROM[i] = conj(std::complex<T>(T(cos(2 * M_PI * i / N)), T(-sin(2 * M_PI * i / N))));
        }
    }
}

// With the DIF butterfly diagram in mind, this implementation was conceived by
// visually grouping together Xs within the butterfly diagram. We calculate both
// outputs of an X in the same logical step. An X's representation changes based
// based on the stage of the butterfly you are targeting. Descriptions of the 
// variables used for representing Xs in the butterfly are given below:
//   fftStage: Used to specificy which stage of the butterfly to target.
//   span: How far away the indexes are from one another that make up an "X".
//   accumulatingOffsetThreshold: Used to determine when to hop to the next grouping of "X"s.
//   accumulatingOffset: Once a hop to the next group happens, this value accumulates that offset.
//   twiddleMult: Used to multiply the twiddle based on which stage we are calculating.
template <int FFT, int N,typename T> void fftStage(int fftStage,T dataIn[N], T dataOut[N]){
    std::complex<twiddleTypeForDSP48Primitive> twiddleROM[N/2];
    initTwiddleROM<FFT, N, twiddleTypeForDSP48Primitive>(twiddleROM);
    int accumulatingOffset = 0;
    int accumulatingOffsetThreshold = N >> fftStage + 1;
    int span = N >> fftStage + 1;
    int twiddleMult = 1 << fftStage;
    T twiddleConstant;
    FFT_label1: for (int i = 0; i < N/2; i++) {
    #pragma HLS PIPELINE
        twiddleConstant = twiddleROM[(i % span)*twiddleMult];
        dataOut[i+accumulatingOffset] = dataIn[i+accumulatingOffset] + dataIn[i+accumulatingOffset+span];
        dataOut[i+accumulatingOffset+span] = (dataIn[i+accumulatingOffset] - dataIn[i+accumulatingOffset+span]) * twiddleConstant;

        if (i % accumulatingOffsetThreshold == accumulatingOffsetThreshold - 1){
            accumulatingOffset += accumulatingOffsetThreshold;
        }
    }
}

// With the DIF butterfly diagram in mind, this function takes the C++ array representation for all the
// butterfly diagram's combined pipelined memory and instructs HLS as to the intended implementation
// on FPGA resources. Finally, we specify what FFT stage logic is to be performed between each of these
// pipelined regions.
template <int FFT, int N,typename T> void fftWrapper(T dataIn[N], T dataOut[N]){
    #pragma HLS DATAFLOW
    static T stagesArray[Log2<N>::value-1][N];
    #pragma HLS ARRAY_PARTITION variable=stagesArray type=complete dim=1
    fftStage<FFT, N>(0,dataIn,stagesArray[0]);
    for (int i = 0; i < Log2<N>::value-2; i++) {
        #pragma HLS UNROLL
        fftStage<FFT, N>(i+1,stagesArray[i],stagesArray[i+1]);
    }
    fftStage<FFT, N>(Log2<N>::value-1,stagesArray[Log2<N>::value-2],dataOut);
}

// Based on the user's inputting ap_fixed data type we create a new type which 
// increases the integer bit width (to the left of the decimal point) by the number of stages to 
// accommodate for bit growth. Fractional bits do get truncated as a result of multiplications 
// with the twiddle factors, although this is pretty standard in implementations of the FFT. 
// The resulting value is finally truncated into the user provided input type dataOut. You 
// can size the type for dataOut to achieve your desired precision.
template <int FFT, int N,typename T, typename U>void fft_core(T dataIn[N], U dataOut[N]){
    #pragma HLS DATAFLOW
    
    // The bitgrowth is equal to the number of stages.
    typedef std::complex<ap_fixed<T::_Tp::width + Log2<N>::value, T::_Tp::iwidth + Log2<N>::value>> fixedComplexGrowthType;
    static fixedComplexGrowthType pipelineReg[N];
    static fixedComplexGrowthType dataBridge1[N];
    
    // Cast data on dataIn into the larger type to accommodate bit growth
    for (int i = 0; i < N; i++) {
        #pragma HLS PIPELINE rewind
        pipelineReg[i] = dataIn[i];
    }

    fftWrapper<FFT, N>(pipelineReg,dataBridge1);

    // In a decimation in frequency FFT implementation, the bit reversal happens on the outputting data.
    // bitReversal's template will truncate or sign extend the output based on the user provided dataOut U type
    bitReversal<N>(dataBridge1, dataOut);
}

// Following are the top level functions intended for use.
template <int N,typename T, typename U>void fft(T dataIn[N], U dataOut[N]){
    #pragma HLS DATAFLOW
    fft_core<1, N>(dataIn, dataOut);
}

template <int N,typename T, typename U>void ifft(T dataIn[N], U dataOut[N]){
    #pragma HLS DATAFLOW
    fft_core<0, N>(dataIn, dataOut);
}
    
#endif // __fft__
