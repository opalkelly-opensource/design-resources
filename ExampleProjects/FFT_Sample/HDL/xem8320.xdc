############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2023 Opal Kelly Incorporated
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## SYZYGY Ports
############################################################################
## DAC ##
# PORTA-5
set_property PACKAGE_PIN L18 [get_ports {dac_data_o_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[0]}]

# PORTA-6
set_property PACKAGE_PIN M25 [get_ports {dac_data_o_0[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[1]}]

# PORTA-7
set_property PACKAGE_PIN K18 [get_ports {dac_data_o_0[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[2]}]

# PORTA-8
set_property PACKAGE_PIN M26 [get_ports {dac_data_o_0[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[3]}]

# PORTA-9
set_property PACKAGE_PIN M20 [get_ports {dac_data_o_0[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[4]}]

# PORTA-10
set_property PACKAGE_PIN L24 [get_ports {dac_data_o_0[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[5]}]

# PORTA-11
set_property PACKAGE_PIN M21 [get_ports {dac_data_o_0[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[6]}]

# PORTA-12
set_property PACKAGE_PIN L25 [get_ports {dac_data_o_0[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[7]}]

# PORTA-13
set_property PACKAGE_PIN J19 [get_ports {dac_data_o_0[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[8]}]

# PORTA-14
set_property PACKAGE_PIN K25 [get_ports {dac_data_o_0[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[9]}]

# PORTA-15
set_property PACKAGE_PIN J20 [get_ports {dac_data_o_0[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[10]}]

# PORTA-16
set_property PACKAGE_PIN K26 [get_ports {dac_data_o_0[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data_o_0[11]}]

# PORTA-17
set_property PACKAGE_PIN L22 [get_ports dac_cs_n_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_cs_n_0]

# PORTA-18
set_property PACKAGE_PIN K22 [get_ports dac_sclk_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sclk_0]

# PORTA-19
set_property PACKAGE_PIN L23 [get_ports dac_sdio_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sdio_0]

# PORTA-20

# PORTA-21
set_property PACKAGE_PIN H24 [get_ports dac_reset_pinmd_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_reset_pinmd_0]

# PORTA-34
set_property PACKAGE_PIN H26 [get_ports dac_clk_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_clk_0]


############################################################################
## Timing
############################################################################

set_false_path -from [get_pins ifft_i/syzygy_dac_top_0/inst/dac_control/dac_ready_reg/C] -to [get_pins {ifft_i/frontpanel_0/inst/wo20/wirehold_reg[1]/D}]

set_false_path -reset_path -from [get_clocks -of_objects [get_pins ifft_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins ifft_i/syzygy_dac_top_0/inst/dac_phy_impl/phy_pll/inst/mmcme4_adv_inst/CLKOUT0]]
set_false_path -reset_path -from [get_clocks -of_objects [get_pins ifft_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins ifft_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]]
