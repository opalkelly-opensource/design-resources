############################################################################
# XEM7320 - Xilinx constraints file
#
# Pin mappings for the XEM7320.  Use this as a template and comment out
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2023 Opal Kelly Incorporated
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## FrontPanel Host Interface
############################################################################
set_property PACKAGE_PIN Y19 [get_ports {okHU[0]}]
set_property PACKAGE_PIN R18 [get_ports {okHU[1]}]
set_property PACKAGE_PIN R16 [get_ports {okHU[2]}]
set_property PACKAGE_PIN P14 [get_ports {okHU[3]}]
set_property SLEW FAST [get_ports {okHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[*]}]

set_property PACKAGE_PIN W19 [get_ports {okUH[0]}]
set_property PACKAGE_PIN V18 [get_ports {okUH[1]}]
set_property PACKAGE_PIN U17 [get_ports {okUH[2]}]
set_property PACKAGE_PIN W17 [get_ports {okUH[3]}]
set_property PACKAGE_PIN T19 [get_ports {okUH[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUH[*]}]

set_property PACKAGE_PIN AB22 [get_ports {okUHU[0]}]
set_property PACKAGE_PIN AB21 [get_ports {okUHU[1]}]
set_property PACKAGE_PIN Y22 [get_ports {okUHU[2]}]
set_property PACKAGE_PIN AA21 [get_ports {okUHU[3]}]
set_property PACKAGE_PIN AA20 [get_ports {okUHU[4]}]
set_property PACKAGE_PIN W22 [get_ports {okUHU[5]}]
set_property PACKAGE_PIN W21 [get_ports {okUHU[6]}]
set_property PACKAGE_PIN T20 [get_ports {okUHU[7]}]
set_property PACKAGE_PIN R19 [get_ports {okUHU[8]}]
set_property PACKAGE_PIN P19 [get_ports {okUHU[9]}]
set_property PACKAGE_PIN U21 [get_ports {okUHU[10]}]
set_property PACKAGE_PIN T21 [get_ports {okUHU[11]}]
set_property PACKAGE_PIN R21 [get_ports {okUHU[12]}]
set_property PACKAGE_PIN P21 [get_ports {okUHU[13]}]
set_property PACKAGE_PIN R22 [get_ports {okUHU[14]}]
set_property PACKAGE_PIN P22 [get_ports {okUHU[15]}]
set_property PACKAGE_PIN R14 [get_ports {okUHU[16]}]
set_property PACKAGE_PIN W20 [get_ports {okUHU[17]}]
set_property PACKAGE_PIN Y21 [get_ports {okUHU[18]}]
set_property PACKAGE_PIN P17 [get_ports {okUHU[19]}]
set_property PACKAGE_PIN U20 [get_ports {okUHU[20]}]
set_property PACKAGE_PIN N17 [get_ports {okUHU[21]}]
set_property PACKAGE_PIN N14 [get_ports {okUHU[22]}]
set_property PACKAGE_PIN V20 [get_ports {okUHU[23]}]
set_property PACKAGE_PIN P16 [get_ports {okUHU[24]}]
set_property PACKAGE_PIN T18 [get_ports {okUHU[25]}]
set_property PACKAGE_PIN V19 [get_ports {okUHU[26]}]
set_property PACKAGE_PIN AB20 [get_ports {okUHU[27]}]
set_property PACKAGE_PIN P15 [get_ports {okUHU[28]}]
set_property PACKAGE_PIN V22 [get_ports {okUHU[29]}]
set_property PACKAGE_PIN U18 [get_ports {okUHU[30]}]
set_property PACKAGE_PIN AB18 [get_ports {okUHU[31]}]
set_property SLEW FAST [get_ports {okUHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[*]}]

set_property PACKAGE_PIN AA19 [get_ports {okRSVD[0]}]
set_property PACKAGE_PIN V17 [get_ports {okRSVD[1]}]
set_property PACKAGE_PIN AA18 [get_ports {okRSVD[2]}]
set_property PACKAGE_PIN R17 [get_ports {okRSVD[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okRSVD[*]}]

set_property PACKAGE_PIN N13 [get_ports okAA]
set_property IOSTANDARD LVCMOS18 [get_ports okAA]


create_clock -period 9.920 -name okUH0 [get_ports {okUH[0]}]

set_input_delay -clock [get_clocks okUH0] -max -add_delay 8.000 [get_ports {okUH[*]}]
set_input_delay -clock [get_clocks okUH0] -min -add_delay 10.000 [get_ports {okUH[*]}]
set_multicycle_path -setup -from [get_ports {okUH[*]}] 2

set_input_delay -clock [get_clocks okUH0] -max -add_delay 8.000 [get_ports {okUHU[*]}]
set_input_delay -clock [get_clocks okUH0] -min -add_delay 2.000 [get_ports {okUHU[*]}]
set_multicycle_path -setup -from [get_ports {okUHU[*]}] 2

set_output_delay -clock [get_clocks okUH0] -max -add_delay 2.000 [get_ports {okHU[*]}]
set_output_delay -clock [get_clocks okUH0] -min -add_delay -0.500 [get_ports {okHU[*]}]

set_output_delay -clock [get_clocks okUH0] -max -add_delay 2.000 [get_ports {okUHU[*]}]
set_output_delay -clock [get_clocks okUH0] -min -add_delay -0.500 [get_ports {okUHU[*]}]


############################################################################
## System Clock
############################################################################
set_property IOSTANDARD LVDS_25 [get_ports sys_clkp]

set_property IOSTANDARD LVDS_25 [get_ports sys_clkn]
set_property PACKAGE_PIN D17 [get_ports sys_clkp]
set_property PACKAGE_PIN C17 [get_ports sys_clkn]

set_property DIFF_TERM FALSE [get_ports sys_clkp]

create_clock -period 5.000 -name sys_clk [get_ports sys_clkp]
set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks {mmcm0_clk0 okUH0}]

# LEDs #####################################################################
set_property PACKAGE_PIN A13 [get_ports {led[0]}]
set_property PACKAGE_PIN B13 [get_ports {led[1]}]
set_property PACKAGE_PIN A14 [get_ports {led[2]}]
set_property PACKAGE_PIN A15 [get_ports {led[3]}]
set_property PACKAGE_PIN B15 [get_ports {led[4]}]
set_property PACKAGE_PIN A16 [get_ports {led[5]}]
set_property PACKAGE_PIN B16 [get_ports {led[6]}]
set_property PACKAGE_PIN B17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[*]}]

##########################################################
# ADC Section
##########################################################

# PORTA-5
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_1p[0]}]

# PORTA-6
set_property IOSTANDARD LVDS_25 [get_ports adc_fr_p]

# PORTA-7
set_property PACKAGE_PIN AA10 [get_ports {adc_out_1p[0]}]
set_property PACKAGE_PIN AA11 [get_ports {adc_out_1n[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_1n[0]}]

# PORTA-8
set_property PACKAGE_PIN AA9 [get_ports adc_fr_p]
set_property PACKAGE_PIN AB10 [get_ports adc_fr_n]
set_property IOSTANDARD LVDS_25 [get_ports adc_fr_n]

# PORTA-9
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_1p[1]}]

# PORTA-10
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_2p[0]}]

# PORTA-11
set_property PACKAGE_PIN Y11 [get_ports {adc_out_1p[1]}]
set_property PACKAGE_PIN Y12 [get_ports {adc_out_1n[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_1n[1]}]

# PORTA-12
set_property PACKAGE_PIN AA13 [get_ports {adc_out_2p[0]}]
set_property PACKAGE_PIN AB13 [get_ports {adc_out_2n[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_2n[0]}]

# PORTA-13
set_property PACKAGE_PIN AB16 [get_ports adc_sdo]
set_property IOSTANDARD LVCMOS25 [get_ports adc_sdo]

# PORTA-14
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_2p[1]}]

# PORTA-15
set_property PACKAGE_PIN AB17 [get_ports adc_cs_n]
set_property IOSTANDARD LVCMOS25 [get_ports adc_cs_n]

# PORTA-16
set_property PACKAGE_PIN V10 [get_ports {adc_out_2p[1]}]
set_property PACKAGE_PIN W10 [get_ports {adc_out_2n[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {adc_out_2n[1]}]

# PORTA-17
set_property PACKAGE_PIN AB11 [get_ports adc_sck]
set_property IOSTANDARD LVCMOS25 [get_ports adc_sck]

# PORTA-19
set_property PACKAGE_PIN AB12 [get_ports adc_sdi]
set_property IOSTANDARD LVCMOS25 [get_ports adc_sdi]

# PORTA-33
set_property IOSTANDARD LVDS_25 [get_ports adc_dco_p]

# PORTA-34
set_property IOSTANDARD LVDS_25 [get_ports adc_encode_p]

# PORTA-35
set_property PACKAGE_PIN W11 [get_ports adc_dco_p]
set_property PACKAGE_PIN W12 [get_ports adc_dco_n]
set_property IOSTANDARD LVDS_25 [get_ports adc_dco_n]

# PORTA-36
set_property PACKAGE_PIN W15 [get_ports adc_encode_p]
set_property PACKAGE_PIN W16 [get_ports adc_encode_n]
set_property IOSTANDARD LVDS_25 [get_ports adc_encode_n]

# ADC timing constraints
create_clock -period 6.250 -name adc_dco_p -waveform {0.000 3.125} [get_ports adc_dco_p]

set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports {adc_out_1p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports {adc_out_1p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports {adc_out_1p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports {adc_out_1p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports {adc_out_1n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports {adc_out_1n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports {adc_out_1n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports {adc_out_1n[*]}]

set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports {adc_out_2p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports {adc_out_2p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports {adc_out_2p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports {adc_out_2p[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports {adc_out_2n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports {adc_out_2n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports {adc_out_2n[*]}]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports {adc_out_2n[*]}]

set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports adc_fr_p]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports adc_fr_p]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports adc_fr_p]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports adc_fr_p]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -min -add_delay 1.090 [get_ports adc_fr_n]
set_input_delay -clock [get_clocks adc_dco_p] -clock_fall -max -add_delay 2.035 [get_ports adc_fr_n]
set_input_delay -clock [get_clocks adc_dco_p] -min -add_delay 1.090 [get_ports adc_fr_n]
set_input_delay -clock [get_clocks adc_dco_p] -max -add_delay 2.035 [get_ports adc_fr_n]


set_clock_groups -name decode_reset_group -asynchronous -group [get_clocks -of_objects [get_pins okHI/mmcm0/CLKOUT0]] -group [get_clocks -include_generated_clocks adc_dco_p]

# Async
set_false_path -from [get_pins {wire00/ep_dataout_reg[0]/C}] -to [get_pins {adc_impl/reset_idelay_cnt_reg[*]/*}]
set_false_path -from [get_pins {wire00/ep_dataout_reg[0]/C}] -to [get_pins adc_impl/reset_idelay_reg/PRE]
