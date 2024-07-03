############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2024 Opal Kelly Incorporated
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
set_property PACKAGE_PIN H26 [get_ports dac_clk_o_0]
set_property IOSTANDARD LVCMOS18 [get_ports dac_clk_o_0]

##########################################################
# ADC Section
##########################################################

# PORTB-5
set_property IOSTANDARD LVDS [get_ports {adc_out_1p_0[0]}]

# PORTB-6
set_property IOSTANDARD LVDS [get_ports adc_fr_p_0]

# PORTB-7
set_property PACKAGE_PIN A22 [get_ports {adc_out_1p_0[0]}]
set_property PACKAGE_PIN A23 [get_ports {adc_out_1n_0[0]}]
set_property IOSTANDARD LVDS [get_ports {adc_out_1n_0[0]}]

# PORTB-8
set_property PACKAGE_PIN A24 [get_ports adc_fr_p_0]
set_property PACKAGE_PIN A25 [get_ports adc_fr_n_0]
set_property IOSTANDARD LVDS [get_ports adc_fr_n_0]

# PORTB-9
set_property IOSTANDARD LVDS [get_ports {adc_out_1p_0[1]}]

# PORTB-10
set_property IOSTANDARD LVDS [get_ports {adc_out_2p_0[0]}]

# PORTB-11
set_property PACKAGE_PIN E21 [get_ports {adc_out_1p_0[1]}]
set_property PACKAGE_PIN D21 [get_ports {adc_out_1n_0[1]}]
set_property IOSTANDARD LVDS [get_ports {adc_out_1n_0[1]}]

# PORTB-12
set_property PACKAGE_PIN D24 [get_ports {adc_out_2p_0[0]}]
set_property PACKAGE_PIN D25 [get_ports {adc_out_2n_0[0]}]
set_property IOSTANDARD LVDS [get_ports {adc_out_2n_0[0]}]

# PORTB-13
set_property PACKAGE_PIN E25 [get_ports adc_sdo_0]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sdo_0]

# PORTB-14
set_property IOSTANDARD LVDS [get_ports {adc_out_2p_0[1]}]

# PORTB-15
set_property PACKAGE_PIN E26 [get_ports adc_cs_n_0]
set_property IOSTANDARD LVCMOS18 [get_ports adc_cs_n_0]

# PORTB-16
set_property PACKAGE_PIN C23 [get_ports {adc_out_2p_0[1]}]
set_property PACKAGE_PIN B24 [get_ports {adc_out_2n_0[1]}]
set_property IOSTANDARD LVDS [get_ports {adc_out_2n_0[1]}]

# PORTB-17
set_property PACKAGE_PIN F23 [get_ports adc_sck_0]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sck_0]

# PORTB-19
set_property PACKAGE_PIN E23 [get_ports adc_sdi_0]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sdi_0]

# PORTB-33
set_property IOSTANDARD LVDS [get_ports adc_dco_p_0]

# PORTB-34
set_property IOSTANDARD LVDS [get_ports adc_encode_p_0]

# PORTB-35
set_property PACKAGE_PIN G24 [get_ports adc_dco_p_0]
set_property PACKAGE_PIN G25 [get_ports adc_dco_n_0]
set_property IOSTANDARD LVDS [get_ports adc_dco_n_0]

# PORTB-36
set_property PACKAGE_PIN H21 [get_ports adc_encode_p_0]
set_property PACKAGE_PIN H22 [get_ports adc_encode_n_0]
set_property IOSTANDARD LVDS [get_ports adc_encode_n_0]

############################################################################
## Timing
############################################################################

# DAC timing constraints
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets adc_dac_tester_i/clk_wiz_0/inst/clk_out1]
create_generated_clock -name dac_clk -source [get_ports dac_clk_o_0] -divide_by 1 [get_ports dac_clk_o_0]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -max -add_delay 0.25 [get_ports {dac_data_o_0[*]}]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -min -add_delay -1.2 [get_ports {dac_data_o_0[*]}]
set_output_delay -clock [get_clocks dac_clk] -max -add_delay 0.13 [get_ports {dac_data_o_0[*]}]
set_output_delay -clock [get_clocks dac_clk] -min -add_delay -1.1 [get_ports {dac_data_o_0[*]}]

# ADC timing constraints
create_clock -period 2.000 -name adc_dco_p -waveform {0.000 1.000} [get_ports adc_dco_p_0]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports {adc_out_1p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports {adc_out_1p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports {adc_out_1p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports {adc_out_1p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports {adc_out_1n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports {adc_out_1n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports {adc_out_1n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports {adc_out_1n_0[*]}]

set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports {adc_out_2p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports {adc_out_2p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports {adc_out_2p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports {adc_out_2p_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports {adc_out_2n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports {adc_out_2n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports {adc_out_2n_0[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports {adc_out_2n_0[*]}]

set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports adc_fr_p_0]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports adc_fr_p_0]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports adc_fr_p_0]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports adc_fr_p_0]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 0.350 [get_ports adc_fr_n_0]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 0.650 [get_ports adc_fr_n_0]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 0.350 [get_ports adc_fr_n_0]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 0.650 [get_ports adc_fr_n_0]

set_false_path -from [get_clocks -of_objects [get_pins adc_dac_tester_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_dac_tester_i/xem8320_adc_0/inst/adc_impl/adc_dco_impl/mmcm_dco/CLKOUT1]]

set_false_path -from [get_clocks -of_objects [get_pins adc_dac_tester_i/xem8320_adc_0/inst/adc_impl/adc_dco_impl/mmcm_dco/CLKOUT1]] -to [get_clocks -of_objects [get_pins adc_dac_tester_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]]

set_false_path -from [get_clocks -of_objects [get_pins adc_dac_tester_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_dac_tester_i/syzygy_dac_top_0/inst/dac_phy_impl/phy_pll/inst/mmcme4_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks -of_objects [get_pins adc_dac_tester_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_dac_tester_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks -of_objects [get_pins adc_dac_tester_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_dac_tester_i/frontpanel_0/inst/okHI/mmcm0/CLKOUT0]]
