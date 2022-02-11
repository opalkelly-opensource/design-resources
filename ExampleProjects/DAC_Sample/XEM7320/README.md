# SYZYGY Signal Generator

## Overview

FM/AM modulator built using an Opal Kelly XEM7320 with the SYZYGY DAC
peripheral connected to PORT A. A SYZYGY PMOD breakout may optionally be
connected to SYZYGY PORT B. A Digilent I2S2 PMOD on PORT 1 of the PMOD breakout
can be used as an optional secondary audio source.

Modulation parameters can be controlled via FrontPanel. Both an XML FrontPanel
GUI and a C++ FrontPanel CLI application are provided. The GUI uses the ADC
PMOD to receive audio data while the CLI uses audio files or generated sine
waves piped over USB. Supports control of carrier frequency, modulation type
(AM, FM, FM+AM, None), AM depth, and FM frequency deviation.

## HDL Description

The provided HDL is written in Verilog and makes use of the FrontPanel SDK.

### ADC

When using the Digilent ADC PMOD along with the FrontPanel XML-based GUI, audio
data comes in via the I2S protocol with clocks generated on the FPGA. The
stereo audio is averaged to produce mono data that is then shifted and sliced
for the DAC's 12-bit unsigned input.

### USB Pipe

When using the USB pipe audio source, audio data is stored and read from a
FIFO. The FIFO's empty and full signals are connected to LEDs D1 and D2 on the
board, respectively.

### DAC

The DAC module uses a CORDIC and a counter to generate a sine wave for use in
carrier generation on the I channel. FM and AM modulation modules are inserted
before and after the CORDIC to modify the increments or scaling done to the
data before entering the DAC PHY. Carrier frequency input and FM deviation are
scaled to accurately reflect Hz-level settings on the FrontPanel interface
through host-side prescaling and FPGA-side bitshifts.

Note: Use of host-side prescaling for Hz resolution requires use of FrontPanel
5.1 or higher.

## HDL Build

To build each sample design, start a new Vivado project with the xc7a75tfgg484-1
part selected and add the sources in the HDL folder to the project.

With the project created and sources added, simply click the "Generate Bitstream"
button in the Vivado Flow Navigator to build a bitstream. The result can be found
in the Vivado project folder under:

(project name).runs/impl_1/(project name).bit

## Software Description

### XFP

The XFP is a simple XML parsed by FrontPanel. Note that this project's XFP
requires a version of FrontPanel capable of prescaling.

### C++

The provided C++ code can either generate a sine wave or read in an audio
file with libsndfile to pipe over USB with the FrontPanel API. It takes command
line arguments for frequency, modulation type, AM depth, FM frequency deviation,
and bitfile.

## Software Build

Requirements:
  * FrontPanel
  * libsndfile

```
cd Cxx
make
```

### Example Usage
```
# 10MHz frequency, 70Hz FM frequency deviation, program with bitfile.bit, 'audio.wav' file.
./AudioPipe -h 10000000 -d 70 -m fm -b bitfile.bit --file audio.wav
# Generate 440Hz sine wave, modulated onto 10MHz carrier.
./AudioPipe -h 10000000 -d 70 -m fm -b bitfile.bit --sine 440
```
