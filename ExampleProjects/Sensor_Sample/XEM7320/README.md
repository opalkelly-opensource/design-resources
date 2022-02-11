# XEM7320 SZG-SENSOR Sample

## Overview

The SZG-SENSOR sample project is designed to demonstrate use of the SZG-SENSOR
SYZYGY peripheral from Opal Kelly. This sample assumes the peripheral is
connected to PORT A on the XEM7320.

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



### Building the HDL

The FPGA design can be built using a recent (2017.3+) version of the
Xilinx Vivado tools:

1. Create a new Vivado project, select "RTL Project".

2. Add all of the source and constraints files in the `hdl` folder to the Vivado
project.

3. Add the Opal Kelly FrontPanel HDL files for the XEM7320 to the project.

4. Choose the `xc7a75tfgg484-1` FPGA part when prompted.

5. Select "Generate Bitfile" in the Vivado Flow Navigator.

## Python Script

The software portion of this design is provided as a set of Python scripts.
These scripts are designed to be compatible with both Python 2.7 and Python 3.

The `spi_api.py` and `i2c_api.py` scripts handle communication with the FPGA
SPI and I2C cores. Each sensor component then has its own script that uses
these classes to implement basic communication with a sensor, typically
polling a series of registers to gather sensor data.

