# set-clock-brk1900 Application

The `set-clock-brk1900` application, along with the `BRK1900-Si5338-Regs.h` ClockBuilder Pro 
configuration register export header file, applies the default clock settings for the Si5338 
on the BRK1900. The default clock frequencies set by this header file can be found under 
‘Si5338 Programmable Clock’ at [BRK1900 Peripherals](https://docs.opalkelly.com/ecm1900/brk1900-breakout-board/brk1900-peripherals/)
```
Usage: set-clock-brk1900 [-w/-c] [i2c device]
Example: set-clock-brk1900 -w /dev/i2c-0
Note: The Si5338 is connected to I2C device `/dev/i2c-0` in the provided BRK1900 linux image.
```
This application provides the write flag (-w) to write the `BRK1900-Si5338-Regs.h` configuration 
to the Si5338. The check flag (-c) is used to check if the `BRK1900-Si5338-Regs.h` configuration 
has been written to the Si5338.

New clock settings can be applied by re-generating the ClockBuilder Pro configuration 
register export header file with new output frequency configuration settings. The SiLabs [ClockBuilder Pro](https://www.silabs.com/developers/clockbuilder-pro-software) 
software can be downloaded at the provided link. Please use our provided 
ClockBuilder Pro project file found at design-resources/BoardTools/BRK1900/ClockConfig of this repository, 
apply changes for the desired output frequencies, and re-generate the configuration register export header file. The build sources 
can be found in the `/home/root/tools` directory of the provided linux images.The build sources expect this header to be named 
`BRK1900-Si5338-Regs.h`. Simply replace the current `BRK1900-Si5338-Regs.h` header file with the new header file containing the 
new register settings and run the provided makefile.

Note: The provided Opal Kelly linux image for the BRK1900 has the `set-clock-brk1900` application 
along with the default `BRK1900-Si5338-Regs.h` baked in. This application is run in the boot 
process to configure the clocks at startup. If you require new configuration settings to be run 
at startup, follow the instructions located at [BRK1900 Linux Image](https://docs.opalkelly.com/ecm1900/brk1900-breakout-board/brk1900-linux-image/)
