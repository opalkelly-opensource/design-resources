# ----------------------------------------------------------------------------------------
# Example vitis_hls build script to import the DUT and TB, C simulate,
# synthesize, C/RTL co-simulate, and finally package the generated output
# products as an IP for use in Vivado. 
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

open_project vitis
set_top rfft32_i14_o19
add_files ../../fft.h
add_files rfft32_i14_o19.cpp
add_files rfft32_i14_o19.h
add_files -tb tb/tb.cpp
add_files -tb tb/outputExpectedComplexValues.txt
add_files -tb tb/inputRealValues.txt
open_solution "solution1" -flow_target vivado
# Change the part as appropriate. Below we build for the FPGA on the XEM8320-AU25P.
set_part {xcau25p-ffvb676-2-e}
create_clock -period 10 -name default

csim_design
csynth_design
cosim_design
export_design -format ip_catalog -display_name rfft32_i14_o19 -vendor opalkelly.com -library ip -ipname rfft32_i14_o19 -version 1.0 -taxonomy {/Opal\ Kelly\ Incorporated/FFT} -description \
{This core utilizes Opal Kelly's fft.h library to implement a real input pipelined streaming fixed point FFT with transform size of 32, input data width of 14 bits and output data width of 19 bits.}
exit
