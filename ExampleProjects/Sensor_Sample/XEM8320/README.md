# XEM8320 SZG-SENSOR Sample

## Overview

The SZG-SENSOR sample project is designed to demonstrate use of the SZG-SENSOR
SYZYGY peripheral from Opal Kelly. This sample assumes the peripheral is
connected to PORT A on the XEM8320.

Hardware interfaces to each sensor on the peripheral are implemented in the
FPGA fabric. These interfaces are connected to the FrontPanel interface
enabling simple software control of each device through the FrontPanelAPI.

A sample Python script `pod-sensor.py` is provided. This script uses the
FrontPanelAPI to demonstrate basic communication with each of the sensors
on the SZG-SENSOR board. 

## FPGA Design

The FPGA is responsible for interfacing between the sensor components on the
SYZYGY peripheral and the FrontPanel USB interface. This is accomplished with
a series of Verilog IP cores implementing the various interfaces (SPI, I2C,
and UART) used by the sensors. These IP cores are then connected to the
FrontPanel interface either directly or through FIFOs for buffering.



### Building the gateware

1. Open Vivado GUI and `cd` to this directory containing project.tcl using the TCL console.
2. Run `source project.tcl`
3. Import FrontPanel HDL for the XEM8320 into the project. These sources are located within the FrontPanel SDK installation.
4. Generate Bitstream.

## Python Script

The software portion of this design is provided as a set of Python scripts.
These scripts are designed to be compatible with both Python 2.7 and Python 3.

The `spi_api.py` and `i2c_api.py` scripts handle communication with the FPGA
SPI and I2C cores. Each sensor component then has its own script that uses
these classes to implement basic communication with a sensor, typically
polling a series of registers to gather sensor data.

