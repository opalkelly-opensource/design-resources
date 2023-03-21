# ----------------------------------------------------------------------------------------
# This TCL script is used to generate projects with a varying number of stages.
# This script takes in three parameters. The first being either `fft` or `ifft`
# to specify which function to target. The latter two parameters represent the
# number of stages, and the two input parameters together represent the range of
# reports you wish to generate from Vitis HLS.
#
# For example to generate reports for the fft with a transform size 4 (2 stages)
# through 32768 (15 stages) you would use the following command:
# `vitis_hls -f report_utilization.tcl fft 2 15`
#
# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

set testDefines {
#include "../../fft.h"

#define N_POINTS <XXX>
typedef ap_fixed<14,1> fixedInputType;
typedef ap_fixed<14,6> fixedOutputType;
typedef std::complex<fixedInputType> fixedInputComplexType;
typedef std::complex<fixedOutputType> fixedOutputComplexType;

}

set fft {
void fft_i14_o14(fixedInputComplexType dataIn[N_POINTS], fixedOutputComplexType dataOut[N_POINTS]){
    #pragma HLS DATAFLOW
    #pragma HLS INTERFACE axis register off port=dataOut
    #pragma HLS INTERFACE axis register off port=dataIn
    fft<N_POINTS>(dataIn, dataOut);
}
}

set ifft {
void ifft_i14_o14(fixedInputComplexType dataIn[N_POINTS], fixedOutputComplexType dataOut[N_POINTS]){
    #pragma HLS DATAFLOW
    #pragma HLS INTERFACE axis register off port=dataOut
    #pragma HLS INTERFACE axis register off port=dataIn
    ifft<N_POINTS>(dataIn, dataOut);
}
}

if {[lindex $argv 2] == "fft"} {
    set inverse {}
} elseif {[lindex $argv 2] == "ifft"} {
    set inverse {i}
} else {
    puts {ERROR: Second argument must be either 'fft' or 'ifft'}
    quit
}

file mkdir build
cd build

open_project -reset vitis_[set inverse]fft_i14_o14
set_top [set inverse]fft_i14_o14

for { set a [lindex $argv 3]}  {$a <= [lindex $argv 4]} {incr a} {   
    set subTestDefines [regsub -all "<XXX>" $testDefines [expr int(pow(2, $a))]]
    set dut [open "buildfile_[set inverse]fft_i14_o14.cpp" w+]
    puts $dut $subTestDefines[set [set inverse]fft]
    close $dut
    add_files ../../fft.h
    add_files buildfile_[set inverse]fft_i14_o14.cpp
    open_solution -reset $a -flow_target vivado
    set_part {xcau25p-ffvb676-2-e}
    create_clock -period 10 -name default
    csynth_design
}
cd vitis_[set inverse]fft_i14_o14
exec python ../../writeUtilization.py [set inverse]fft [lindex $argv 3] [lindex $argv 4]
quit
