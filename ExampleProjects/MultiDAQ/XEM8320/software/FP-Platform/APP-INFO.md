The Multi-DAQ example app is a composite demonstration instrument that provides an 8 channel signal generator, and oscilloscope using the [XEM8320 ](https://opalkelly.com/products/xem8320/) and [SZG-MULTIDAQ](https://docs.opalkelly.com/syzygy-peripherals/szg-multidaq/).

## Compatibility

The Multi-DAQ app is compatible with the following FPGA module and peripheral combinations:

* XEM8320
  * [SZG-MULTIDAQ](https://docs.opalkelly.com/syzygy-peripherals/szg-multidaq/) - Note that this peripheral must be attached at Port D.

## Usage

The signal generator controls the output of the 8 channel DAC, and the oscilloscope captures and displays the input from up to 8 signal channels sampled by the ADC.

### Signal Generator

* Enable or disable any of the output channels with the corresponding switch.
* Set the frequency of the sinusoidal output signal for each channel.

### Oscilloscope

* Select the number of channels to sample with the ADC and display on the chart.

## Version History

* 3.1 (released 2025-08-26)
  * Updated to provide application information
* 3.0
  * Updated to use version 0.5.0 of the FrontPanel Platform API
  * Updated so application can be installed in the FrontPanel Platform launcher
* 2.0
  * Initial release of FrontPanel Platform App
