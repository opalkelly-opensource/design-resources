# ADC Sample Design for the XEM7320
## Overview
This project is based heavily on [Xilinx Application Note 524, XAPP524](https://www.xilinx.com/support/documentation/application_notes/xapp524-serial-lvds-adc-interface.pdf), and implements a simplified version of the design described by Xilinx. The project uses an LTC2264-12 ADC on Port A on the XEM7320 to read ADC data. Provided is a simple Python script that plots the data retrieved from the ADC and animates a graph. 

## A Note About the SZG-ADC-LTC2268-14
The SZG-ADC-LTC2268-14 is compatible with this design, but it will operate at the speeds of the SZG-ADC-LTC2264-12. The LVDS speeds for the SZG-ADC-LTC2264-12 are at the limit of what can be managed using static timing analysis. In contrast, the LVDS speeds for the SZG-ADC-LTC2268-14 exceed the capabilities of static timing analysis and necessitate the use of dynamic phase alignment techniques.
The implementation of dynamic phase alignment techniques to leverage the higher LVDS speeds offered by the SZG-ADC-LTC2268-14 is not covered here and is left as a task for the user. For additional guidance on implementing dynamic phase alignment techniques, please refer to page 5 of XAPP524.

## Gateware
Instructions to build the gateware are available at [docs.opalkelly.com](https://docs.opalkelly.com/syzygy-peripherals/szg-adc-ltc226x/syzygy-adc-ltc226x-reference-design)

## Python Script
You will need to install [Matplotlib](https://matplotlib.org/), a Python graphing utility as well as Opal Kelly's FrontPanel Python API wrappers. [Instructions are available on their website](https://docs.opalkelly.com/fpsdk/frontpanel-api/programming-languages/).

The Python script must be called with the path to the bitfile as an argument. 

Example: `.\adc_read.py .\xem7320_adc.bit`

## Additional Resources
[7 Series FPGAs SelectIO Resources, UG471.](https://docs.xilinx.com/v/u/en-US/ug471_7Series_SelectIO)

[Matplotlib, a Python graphing utility.](https://matplotlib.org/)

[Serial LVDS High-Speed ADC Interface, XAPP524](https://www.xilinx.com/support/documentation/application_notes/xapp524-serial-lvds-adc-interface.pdf)
