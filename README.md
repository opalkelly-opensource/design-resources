# FrontPanel HLS FIR

A basic example demonstrating use of a Vivado HLS module with the FrontPanel
interface on an XEM7320. For this example a basic FIR filter is implemented in
C++ for use with Vivado HLS.

Input data for the FIR filter is transferred from software through a FrontPanel
PipeIn endpoint to an input FIFO. This data is then passed through the HLS
module and transferred to an output FIFO to buffer the output data. This output
data is read by a FrontPanel PipeOut endpoint and returned to a PC.

Wires and triggers are used to handle the management interface of the HLS
module.

The HLS FIR filter used in this design is based heavily on the Xilinx HLS FIR
filter example available on [github](https://github.com/Xilinx/HLx_Examples).

## Octave

An octave script is provided to generate test data. The test data consists of
an input waveform to the filter and an expected output waveform after passing
through the filter. Data is provided in both fixed point number format (for
use in hardware) and floating point (for use in the Vivado HLS tools).

To use the octave script, simply run `octave gen_data.m`.

Note: The data files output from octave must be edited to remove the octave
comments at the top of the files and the blank lines at the end.

Example data is provided in the octave folder.

## Vivado HLS Project

Create a new Vivado HLS project according to the instructions below:

- In the Vivado HLS Welcome Page, select Create New project
- Enter an appropriate name and location. Click Next
- Add the `HLS\fir.cpp` file, click "Browse..." next to "Top Function" and select
  the `fir` function as the top level function. Click Next.
- Add the `HLS\fir_test.cpp` file. Click Next.
- Set the Clock Period to 9.92 and select the `xc7a75tfgg484-1` part. Click
  Finish.

With the new HLS project created, it is possible to run a C simulation,
synthesize HDL, and run a C/HDL co-simulation. For the purposes of this example,
only synthesis will be performed. Please refer to the Xilinx Vivado HLS
documentation for more information on C simulation and C/HDL co-simulation.

To synthesize the design, click `Solution->Run C Synthesis->Active Solution`.

With the design synthesized, export the design by clicking
`Solution->Export RTL`. In the new window, select the "IP Catalog" format and
click "OK". This will create a new Vivado IP repository that can be added to
a Vivado hardware project to manage the HLS IP.

## Vivado Project

To build this sample design, start a new Vivado project with the
`xc7a75tfgg484-1` part selected and add the `fp_top.v` source in the HDL
folder to the project.

With the project created, open the Vivado IP Catalog, right click on
"Vivado Repository" and select "Add Repository". In the popup window, navigate
to the `<HLS Project Directory>\<HLS Project>\<HLS Solution>\impl\ip`
directory and select it. The HLS IP should be added to the Vivado IP Catalog.
Select this IP to create an instance of it in the current project.

See the descriptions below for generating the FIFO IP. These parameters are
from Vivado 2017.4, though later versions should be similar.

With the project created and sources added, simply click the "Generate
Bitstream" button in the Vivado Flow Navigator to build a bitstream.

The result can be found in the Vivado project folder under:

(project name).runs/impl_1/(project name).bit

### Ingress FIFO IP

Instantiate a FIFO Generator IP with the following settings:

```
Interface Type: AXI Stream
Clock Type: Common Clock
TDATA NUM BYTES: 4
TID WIDTH: 0
TDEST WIDTH: 0
TUSER WIDTH: 0
TSTRB: Disabled
TKEEP: Disabled
TLAST: Disabled
Configuration Opetions: FIFO
FIFO Depth: 1024
ECC: Disabled
Embedded Registers: Disabled
Programmable Full/Empty: Disabled
Provide FIFO Occupancy Data Counts: Disabled
Underflow/Overflow Flags: Disabled
```

### Egress FIFO IP

Instantiate a FIFO Generator IP with the following settings:

```
Interface Type: Native
Fifo Implementation: Common Clock Block RAM
Read Mode: Standard FIFO
Write Width: 64
Write Depth: 1024
Read Width: 32
Output Registers: Disabled
Reset Pin: Enabled
Reset Type: Synchronous Reset
Dout Reset Value: 0
Almost Full Flag: Disabled
Almost Empty Flag: Disabled
All Handshaking Options: Disabled
Programmable Full/Empty: Disabled
Data Count: Disabled
```

## Running the sample

A Python script is provided to demonstrate interaction with the FrontPanel
interface in hardware. This script reads the input data from octave, pipes it
to the XEM7320, then reads the filtered data out and writes it to a file. The
output data is also compared against the expected output from octave to ensure
that the HLS module performed as expected.

The sample can be executed with the following command:

```
python3 FP-HLS.py <bitstream> <infile> <reference output> <outfile>
```

