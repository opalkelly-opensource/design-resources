############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2024 Opal Kelly Incorporated
############################################################################

# PORTD-5
set_property PACKAGE_PIN J12 [get_ports ADC_SDI_C]
set_property IOSTANDARD LVCMOS12 [get_ports ADC_SDI_C]
# PORTD-6
set_property PACKAGE_PIN W12 [get_ports DAC_SDI_C]
set_property IOSTANDARD LVCMOS12 [get_ports DAC_SDI_C]
# PORTD-7
set_property PACKAGE_PIN H12 [get_ports ADC_SDO_C]
set_property IOSTANDARD LVCMOS12 [get_ports ADC_SDO_C]
# PORTD-8
set_property PACKAGE_PIN W13 [get_ports DAC_SDO_C]
set_property IOSTANDARD LVCMOS12 [get_ports DAC_SDO_C]
# PORTD-9
set_property PACKAGE_PIN Y13 [get_ports ADC_SCLK_C]
set_property IOSTANDARD LVCMOS12 [get_ports ADC_SCLK_C]
# PORTD-10
set_property PACKAGE_PIN H14 [get_ports DAC_SCLK_C]
set_property IOSTANDARD LVCMOS12 [get_ports DAC_SCLK_C]
# PORTD-11
set_property PACKAGE_PIN AA13 [get_ports ADC_CS_N_C]
set_property IOSTANDARD LVCMOS12 [get_ports ADC_CS_N_C]
# PORTD-12
set_property PACKAGE_PIN G14 [get_ports DAC_CS_N_C]
set_property IOSTANDARD LVCMOS12 [get_ports DAC_CS_N_C]
# PORTD-13
set_property PACKAGE_PIN J13 [get_ports ADC_RST]
set_property IOSTANDARD LVCMOS12 [get_ports ADC_RST]

# LEDS #####################################################################
set_property PACKAGE_PIN G19 [get_ports {led[0]}]
set_property PACKAGE_PIN B16 [get_ports {led[1]}]
set_property PACKAGE_PIN F22 [get_ports {led[2]}]
set_property PACKAGE_PIN E22 [get_ports {led[3]}]
set_property PACKAGE_PIN M24 [get_ports {led[4]}]
set_property PACKAGE_PIN G22 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[*]}]

############################################################################
## System Clock
############################################################################
set_property IOSTANDARD LVDS [get_ports sys_clkp]

set_property PACKAGE_PIN T24 [get_ports sys_clkp]
set_property PACKAGE_PIN U24 [get_ports sys_clkn]
set_property IOSTANDARD LVDS [get_ports sys_clkn]

create_clock -period 10.000 -name sys_clk [get_ports sys_clkp]
set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks {mmcm0_clk0 okUH0}]
set_false_path -from [get_clocks -of_objects [get_pins adc_clk_inst/inst/plle4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins frontpanel_inst/inst/okHI/mmcm0/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins frontpanel_inst/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_clk_inst/inst/plle4_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins frontpanel_inst/inst/okHI/mmcm0/CLKOUT0]] -to [get_clocks -of_objects [get_pins adc_clk_inst/inst/plle4_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins adc_clk_inst/inst/plle4_adv_inst/CLKOUT0]] -to [get_clocks sys_clk]

############################################################################
## Timing
############################################################################
# Define output delay constraints

create_clock -name adc_clk -period 70 [get_ports ADC_SCLK_C]
set_input_delay -clock [get_clocks adc_clk] -clock_fall -min -add_delay 10.000 [get_ports ADC_SDO_C]
set_input_delay -clock [get_clocks adc_clk] -clock_fall -max -add_delay 25.000 [get_ports ADC_SDO_C]
set_output_delay -clock [get_clocks adc_clk] -clock_fall -min -add_delay -10.000 [get_ports ADC_CS_N_C]
set_output_delay -clock [get_clocks adc_clk] -clock_fall -max -add_delay 30.000 [get_ports ADC_CS_N_C]
set_output_delay -clock [get_clocks adc_clk] -clock_fall -min -add_delay -5.000 [get_ports ADC_SDI_C]
set_output_delay -clock [get_clocks adc_clk] -clock_fall -max -add_delay 5.000 [get_ports ADC_SDI_C]


create_clock -name dac_clk -period 38 [get_ports DAC_SCLK_C]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -min -add_delay -10.000 [get_ports DAC_CS_N_C]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -max -add_delay 13.000 [get_ports DAC_CS_N_C]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -min -add_delay -10.000 [get_ports DAC_SDI_C]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -max -add_delay 5.000 [get_ports DAC_SDI_C]

set_false_path -from [get_clocks -of_objects [get_pins adc_clk_inst/inst/plle4_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins frontpanel_inst/inst/okHI/mmcm0/CLKOUT0]]
