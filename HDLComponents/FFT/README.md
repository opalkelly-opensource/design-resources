Synthesizable and Scalable Pipelined Streaming Fixed-Point Decimation-In-Frequency FFT and IFFT FPGA Library for use with AMD-Xilinx's High Level Synthesis (HLS)
=================================================================================================================================================================
This library was written as an exhibition experiment to explore the capabilities of AMD-Xilinx's high-level synthesis compilers. In its present form, is not
intended to be an optimized, production-ready core. AMD-Xilinx provides the [Fast Fourier Transform LogiCORE IP](https://docs.xilinx.com/r/en-US/pg109-xfft)
as their [Production](https://www.xilinx.com/products/intellectual-property/ip-life-cycle-defns.html) life cycled FFT and it is highly optimized for their FPGA
architectures.

## Getting Started
[Examples](examples/) are provided. To run, follow:
1. In a system command line, navigate to an example directory containing a `build.tcl` script.
2. Run the Vitis HLS settings script typically found at `C:\Xilinx\Vitis_HLS\<version year>.<version number>\settings{64,32}.{bat,sh}` (run the appropriate script for your OS architecture).
3. Run the script using the command `vitis_hls -f build.tcl`.

Additionally, our [FFT Signal Generator](https://docs.opalkelly.com/fpsdk/samples-and-tools/sample-fft-signal-generator/) sample is a complete in-hardware sample
utilizing this library. Its sources are also located within this repository at [ExampleProjects/FFT_Sample](../../ExampleProjects/FFT_Sample/).

## Usage at a Glance
The `fft.h` library provides the `fft` and `ifft` templated functions. They allow parameters for the transform size and 
the input and output bit widths. The following example explicitly inputs the `<transformSize>` at the function call,
while the input and output data widths are inferred by the function through the variable's type:
```
#include "fft.h"

// Template Parameter Restrictions:
//   - The transform size (<transformSize>) must be a power of two.
//   - The input and output types must be `std::complex<ap_fixed<>>` .

#define transformSize 1024
std::complex<ap_fixed<14,1>> timeDomainIn[transformSize];
std::complex<ap_fixed<24,11>> frequencyDomain[transformSize];
std::complex<ap_fixed<10,1>> timeDomainOut[transformSize];

fft<transformSize>(timeDomainIn, frequencyDomain);
ifft<transformSize>(frequencyDomain, timeDomainOut);
```

## Acknowledgments
- [IIT Madras's radix-2 decimation-in-time (DIT) FFT](https://gitlab.com/chandrachoodan/teach-fpga)
- [PG109 Fast Fourier Transform LogiCORE IP Product Guide](https://docs.xilinx.com/r/en-US/pg109-xfft)
- [Vitis High-Level Synthesis User Guide (UG1399)](https://docs.xilinx.com/r/en-US/ug1399-vitis-hls/Introduction-to-Vitis-HLS)