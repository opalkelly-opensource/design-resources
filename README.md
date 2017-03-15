I2CController Software Distribution
===================================
This is a full-featured I2C Controller designed to brdige the
[Opal Kelly](https://www.opalkelly.com/) FrontPanel interface and an I2C 
device. The sources are relatively FPGA agnostic, and support for other 
platforms can be easily acheived by replacing the okDRAM64X8D module with 
a platform-specific BRAM module. The included okDRAM64X8D is based on 
Xilinx memory primitives.


Example XEM6002 Project
-----------------------
An example project has been setup for use with the Opal Kelly [XEM6002](https://www.opalkelly.com/products/xem6002/).
This example is designed to interact with a PMOD Gyro on the XEM6002 POD1
port.


Software
--------
A C++ API is provided to interact with the I2C device through the 
FrontPanel software interface.

An example program written in C++ is also provided and can be used to
communicate with EEPROM devices connected to the FPGA I2C controller along
with the PMOD Gyro.


Simulation
----------
A test fixture is provided for the I2C controller in the Simulation
folder. This text fixture is designed to interact with an I2C EEPROM
simulation model (see below). This test is intended to demonstrate usage
of the I2C controller only and is not indended to be used in verification.


I2C EEPROM Device Simulation Models
-----------------------------------
Simulation Models for Microchip I2C EEPROMs are used in the simulation of the
controller. These models may be downloaded directly from Microchip and are
not included in this distribution. You may want to change the tWC (write 
cycle time) in the simulations to a short period for testing.

License
-------
This project is released under the [MIT License](https://opensource.org/licenses/MIT).
Please see the LICENSE file for more information.
