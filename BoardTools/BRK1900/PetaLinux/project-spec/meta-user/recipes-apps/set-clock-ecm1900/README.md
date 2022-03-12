# set-clock-ecm1900 Application

The `set-clock-ecm1900` application, along with the `ECM1900-Si5341-Regs.h` ClockBuilder Pro 
configuration register export header file, applies the default clock settings for the Si5341
on the ECM1900. The default clock frequencies set by this header file can be found in the ECM1900
[Clock Generator](https://docs.opalkelly.com/ecm1900/clock-generator/)
documentation.
```
Usage: set-clock-ecm1900 [i2c device]
Example: set-clock-ecm1900 /dev/i2c-0
Note: The Si5341 is connected to I2C device `/dev/i2c-0` in the provided BRK1900 linux image.
```
New clock settings can be applied by re-generating the ClockBuilder Pro configuration 
register export header file with new output frequency configuration settings. The SiLabs [ClockBuilder Pro](https://www.silabs.com/developers/clockbuilder-pro-software) 
software can be downloaded at the provided link. Please use our provided ClockBuilder Pro project file 
found at design-resources/BoardTools/BRK1900/ClockConfig of this repository, apply changes for the desired 
output frequencies, and re-generate the configuration register export header file. The build sources can be 
found in the `/home/root/tools` directory of the provided linux image.The build sources expects 
this header to be named `ECM1900-Si5341-Regs.h`. Simply replace the current `ECM1900-Si5341-Regs.h` header 
file with the new header file containing the new register settings and run the provided makefile.

Note: The provided Opal Kelly linux image for the BRK1900 has the `set-clock-ecm1900` application 
along with the default `ECM1900-Si5341-Regs.h` baked in. This application is run in the boot 
process to configure the clocks at startup. If you require new configuration settings to be run 
at startup, follow the instructions located at [Linux Image](https://docs.opalkelly.com/ecm1900/brk1900-breakout-board/brk1900-linux-image/)
