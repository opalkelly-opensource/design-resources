The DAC-ADC example app is a composite demonstration instrument that provides an IFFT-based signal generator, oscilloscope, and FFT-based spectrum analyzer using the [XEM8320 ](https://opalkelly.com/products/xem8320/)with the [SZG-DAC-AD9116](https://docs.opalkelly.com/syzygy-peripherals/szg-dac-ad911x/) and [SZG-ADC-LTC226x](https://docs.opalkelly.com/syzygy-peripherals/szg-adc-ltc226x/).

# Compatibility

The DAC-ADC app is compatible with the following FPGA module and peripheral combinations:

* XEM8320
  * [SZG-DAC-AD911X](https://opalkelly.com/products/szg-dac-ad911x/) - Note that this peripheral must be attached at Port A.
  * [SZG-ADC-LTC226X](https://opalkelly.com/products/szg-adc-ltc226x/) - Note that this peripheral must be attached at Port B.

# Usage

The signal generator controls the output of the dual channel DAC. The oscilloscope captures and displays the input signals from the dual channel ADC. The input signal is then passed through the FFT and the results are displayed in the spectrum chart.

## Signal Generator

* Enable or disable a tone by setting the corresponding switch.
* Set the frequency of each tone by selecting the IFFT bin using the slider.
* Set the amplitude of the tones by setting the value in the number entry.
* Add an additional tone if needed using the 'Add Tone' button.
* Enable 'Autoscale' to adjust the full-scale output to prevent clipping.

## Oscilloscope

* Turn on continuous capture to periodically capture the input signal from the ADC.
* Turn off continuous capture and click the 'Capture' button to capture the input signal manually.

# Version History

* 3.1 (released 2025-08-26)
  * Updated to provide application information
* 3.0
  * Updated to use version 0.5.0 of the FrontPanel Platform API
  * Updated so application can be installed in the FrontPanel Platform launcher
* 2.0
  * Initial release of FrontPanel Platform App
