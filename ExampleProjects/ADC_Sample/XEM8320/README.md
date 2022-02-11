# ADC Sample Design for the XEM8320
## Overview
This project is based heavily on [Xilinx Application Note 524, XAPP524](https://www.xilinx.com/support/documentation/application_notes/xapp524-serial-lvds-adc-interface.pdf), and implements a simplified version of the design described by Xilinx. The project uses an LTC2264-12 ADC on Port A on the XEM8320 to read ADC data. Provided is a simple Python script that plots the data retrieved from the ADC and animates a graph. 

## Gateware
Instructions to build the gateware are available at [docs.opalkelly.com](https://docs.opalkelly.com/syzygy-peripherals/szg-adc-ltc226x/syzygy-adc-ltc226x-reference-design)

## Python Script
You will need to install [Matplotlib](https://matplotlib.org/), a Python graphing utility as well as Opal Kelly's FrontPanel Python API wrappers. [Instructions are available on their website](https://docs.opalkelly.com/fpsdk/frontpanel-api/programming-languages/).

The Python script must be called with the path to the bitfile as an argument. 

Example: `.\adc_read.py .\xem8320_adc.bit`

## Additional Resources
[Bitslip in Logic, XAPP1208.](https://www.xilinx.com/support/documentation/application_notes/xapp1208-bitslip-logic.pdf)

[UltraScale Architecture SelectIO Resources, UG571.](https://www.xilinx.com/support/documentation/user_guides/ug571-ultrascale-selectio.pdf)

[Matplotlib, a Python graphing utility.](https://matplotlib.org/)

[Serial LVDS High-Speed ADC Interface, XAPP524](https://www.xilinx.com/support/documentation/application_notes/xapp524-serial-lvds-adc-interface.pdf)
