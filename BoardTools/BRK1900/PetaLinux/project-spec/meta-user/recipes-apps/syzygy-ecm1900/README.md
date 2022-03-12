# syzygy-ecm1900 Application

The `syzygy-ecm1900` application is an implementation of the [SYZYGY Standard](https://syzygyfpga.io/)
for the ECM1900 development board by Opal Kelly. This application
handles all communication with peripheral MCU's and the on-board power
supplies to set the appropriate VIO (VCCO) voltages. This application can also be
used to read/write binary DNA blob files from/to a peripheral MCU. 

This application also provides commands to set the VIO (VCCO) voltages manually.

Usage information is available by running `syzygy-ecm1900 -h`
```
Usage: syzygy-ecm1900 [option [argument]] <i2c device>
 <i2c device> is required for all commands. It must contain the
 path to the Linux i2c device. '/dev/i2c-0' should be used on the ECM1900
 
  Exactly one of the following options must be specified:
    -r - run smartVIO, queries attached MCU's and sets voltages accordingly
    -s - set VIO voltages to the values provided by -1, -2, -3, -4 options (Can only set one at a time)
    -j - print out a JSON object with DNA and SmartVIO information
    -h - print this help text
    -w <filename> - write a binary DNA to a peripheral, takes the DNA filename
                    as an argument
    -d <filename> - dump the DNA from a peripheral to a binary file, takes the
                    DNA filename as an argument
                    
  The following options may be used in conjunction with the above options:
    -1 <vio1> - Sets the voltage for VIO1(VCCO_87_88)
    -2 <vio2> - Sets the voltage for VIO2(VCCO_68)
    -3 <vio3> - Sets the voltage for VIO3(VCCO_67)
    -4 <vio4> - Sets the voltage for VIO4(VCCO_28)
                  *<vioX> must be specified as numbers in 10's of mV
                  *You may only set one voltage at a time
                  *The valid discrete voltage supplies provided by the power supply on the ECM1900 are:
                  VIO1: 120,  125,  150,  180,  250, 330 (Limited by HD bank range 1.2V to 3.3V)
                  VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)
                  VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)
                  VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)
    -p <number> - Specifies the peripheral number for the -w or -d options
    
  Examples:
    Run SmartVIO sequence:
      syzygy-ecm1900 -r /dev/i2c-0
    Dump DNA from the MCU on Port 1:
      syzygy-ecm1900 -d dna_file.bin -p 1 /dev/i2c-0
    Set VIO1 to 3.3V:
      syzygy-ecm1900 -s -1 330 /dev/i2c-0
```
