# Zynq UltraScale+ MPSoC IP Preset

This subfolder is not used during the PetaLinux build process. 

The `BRK1900.tcl` file can be used within Vivado for the Zynq UltraScale+ MPSoC IP to “Apply Configuration” 
under “Presets” in the GUI. This will configure the IP to the settings used when exporting the hardware 
description from Vivado that is then in turn used by the PetaLinux tools. This preset can be used as a 
reference for creating your own breakout board configurations, or a starter template to modifying our 
existing configuration for the BRK1900 breakout board.

You may also use this preset file to create a compatible bitfile. See the following for more information:
https://docs.opalkelly.com/ecm1900/getting-started-guide/
