# ----------------------------------------------------------------------------------------
# Assisting script for vitis_hls to synthesize and package the HLS IFFT as
# a Vivado IP Core for use in the FFT Signal Generator sample. 
#
# ----------------------------------------------------------------------------------------
# Copyright (c) 2024 Opal Kelly Incorporated
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
set_top rfft1024_i12_o22_norm
add_files ../fft.h
add_files rfft1024_i12_o22.cpp
open_solution "solution1" -flow_target vivado
# Change the part as appropriate. Below we build for the FPGA on the XEM8320-AU25P.
set_part {xcau25p-ffvb676-2-e}
create_clock -period 25 -name default

csynth_design
export_design -format ip_catalog -display_name rfft1024_i12_o22_norm -vendor opalkelly.com -library ip -ipname rfft1024_i12_o22_norm -version 1.0 -taxonomy {/Opal\ Kelly\ Incorporated/FFT} -description \
{This core utilizes Opal Kelly's fft.h library to implement a 1/N normalized real output pipelined streaming fixed point FFT with transform size of 1024, input data width of 22 bits and output data width of 12 bits.}

