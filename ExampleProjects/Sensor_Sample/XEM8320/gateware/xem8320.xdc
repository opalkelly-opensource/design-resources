############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2016 Opal Kelly Incorporated
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## FrontPanel Host Interface
############################################################################
set_property PACKAGE_PIN U20 [get_ports {okHU[0]}]
set_property PACKAGE_PIN U26 [get_ports {okHU[1]}]
set_property PACKAGE_PIN T22 [get_ports {okHU[2]}]
set_property SLEW FAST [get_ports {okHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[*]}]

set_property PACKAGE_PIN V23 [get_ports {okUH[0]}]
set_property PACKAGE_PIN T23 [get_ports {okUH[1]}]
set_property PACKAGE_PIN U22 [get_ports {okUH[2]}]
set_property PACKAGE_PIN U25 [get_ports {okUH[3]}]
set_property PACKAGE_PIN U21 [get_ports {okUH[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUH[*]}]

set_property PACKAGE_PIN P26 [get_ports {okUHU[0]}]
set_property PACKAGE_PIN P25 [get_ports {okUHU[1]}]
set_property PACKAGE_PIN R26 [get_ports {okUHU[2]}]
set_property PACKAGE_PIN R25 [get_ports {okUHU[3]}]
set_property PACKAGE_PIN R23 [get_ports {okUHU[4]}]
set_property PACKAGE_PIN R22 [get_ports {okUHU[5]}]
set_property PACKAGE_PIN P21 [get_ports {okUHU[6]}]
set_property PACKAGE_PIN P20 [get_ports {okUHU[7]}]
set_property PACKAGE_PIN R21 [get_ports {okUHU[8]}]
set_property PACKAGE_PIN R20 [get_ports {okUHU[9]}]
set_property PACKAGE_PIN P23 [get_ports {okUHU[10]}]
set_property PACKAGE_PIN N23 [get_ports {okUHU[11]}]
set_property PACKAGE_PIN T25 [get_ports {okUHU[12]}]
set_property PACKAGE_PIN N24 [get_ports {okUHU[13]}]
set_property PACKAGE_PIN N22 [get_ports {okUHU[14]}]
set_property PACKAGE_PIN V26 [get_ports {okUHU[15]}]
set_property PACKAGE_PIN N19 [get_ports {okUHU[16]}]
set_property PACKAGE_PIN V21 [get_ports {okUHU[17]}]
set_property PACKAGE_PIN N21 [get_ports {okUHU[18]}]
set_property PACKAGE_PIN W20 [get_ports {okUHU[19]}]
set_property PACKAGE_PIN W26 [get_ports {okUHU[20]}]
set_property PACKAGE_PIN W19 [get_ports {okUHU[21]}]
set_property PACKAGE_PIN Y25 [get_ports {okUHU[22]}]
set_property PACKAGE_PIN Y26 [get_ports {okUHU[23]}]
set_property PACKAGE_PIN Y22 [get_ports {okUHU[24]}]
set_property PACKAGE_PIN V22 [get_ports {okUHU[25]}]
set_property PACKAGE_PIN W21 [get_ports {okUHU[26]}]
set_property PACKAGE_PIN AA23 [get_ports {okUHU[27]}]
set_property PACKAGE_PIN Y23 [get_ports {okUHU[28]}]
set_property PACKAGE_PIN AA24 [get_ports {okUHU[29]}]
set_property PACKAGE_PIN W25 [get_ports {okUHU[30]}]
set_property PACKAGE_PIN AA25 [get_ports {okUHU[31]}]
set_property SLEW FAST [get_ports {okUHU[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[*]}]

set_property PACKAGE_PIN T19 [get_ports {okAA}]
set_property IOSTANDARD LVCMOS18 [get_ports {okAA}]

create_clock -name okUH0 -period 9.920 [get_ports {okUH[0]}]

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {okUH[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}] 9.920 [get_ports {okUH[*]}]

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  7.000 [get_ports {okUHU[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okUHU[*]}]

# SZG PORT A ###############################################################

# PORTA-5 
set_property PACKAGE_PIN L18 [get_ports {cam_m8q_spi_cs_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_spi_cs_n}]

# PORTA-6 
set_property PACKAGE_PIN M25 [get_ports {hts221_cs}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_cs}]

# PORTA-7 
set_property PACKAGE_PIN K18 [get_ports {cam_m8q_extint}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_extint}]

# PORTA-8 
set_property PACKAGE_PIN M26 [get_ports {hts221_drdy}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_drdy}]

# PORTA-9 
set_property PACKAGE_PIN M20 [get_ports {cam_m8q_timepulse}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_timepulse}]

# PORTA-10 
set_property PACKAGE_PIN L24 [get_ports {hts221_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_spi_sdi_sdo}]

# PORTA-11 
set_property PACKAGE_PIN M21 [get_ports {cam_m8q_d_sel}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_d_sel}]

# PORTA-12 
set_property PACKAGE_PIN L25 [get_ports {lsm9ds1_den_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_den_ag}]

# PORTA-13 
set_property PACKAGE_PIN J19 [get_ports {cam_m8q_safeboot_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_safeboot_n}]

# PORTA-14 
set_property PACKAGE_PIN K25 [get_ports {lsm9ds1_int2_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int2_ag}]

# PORTA-15 
set_property PACKAGE_PIN J20 [get_ports {cam_m8q_uart_txd_spi_miso}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_uart_txd_spi_miso}]

# PORTA-16 
set_property PACKAGE_PIN K26 [get_ports {lsm9ds1_int1_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int1_ag}]

# PORTA-17 
set_property PACKAGE_PIN L22 [get_ports {cam_m8q_uart_rxd_spi_mosi}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_uart_rxd_spi_mosi}]

# PORTA-18 
set_property PACKAGE_PIN K22 [get_ports {lsm9ds1_int_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int_m}]

# PORTA-19 
set_property PACKAGE_PIN L23 [get_ports {gnss_ext_ant_en}]
set_property IOSTANDARD LVCMOS18 [get_ports {gnss_ext_ant_en}]

# PORTA-20 
set_property PACKAGE_PIN K23 [get_ports {lsm9ds1_cs_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_cs_m}]

# PORTA-21 
set_property PACKAGE_PIN H24 [get_ports {lps22hb_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_spi_sdi_sdo}]

# PORTA-22 
set_property PACKAGE_PIN L19 [get_ports {lsm9ds1_drdy_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_drdy_m}]

# PORTA-23 
set_property PACKAGE_PIN J21 [get_ports {lps22hb_spi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_spi_sdo}]

# PORTA-24 
set_property PACKAGE_PIN M19 [get_ports {lsm9ds1_cs_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_cs_ag}]

# PORTA-25 
set_property PACKAGE_PIN H23 [get_ports {lps22hb_int_drdy}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_int_drdy}]

# PORTA-26 
set_property PACKAGE_PIN L20 [get_ports {lsm9ds1_spi_sdo_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdo_m}]

# PORTA-27 
set_property PACKAGE_PIN K21 [get_ports {lps22hb_cs}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_cs}]

# PORTA-28 
set_property PACKAGE_PIN K20 [get_ports {lsm9ds1_spi_sdo_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdo_ag}]

# PORTA-29 
set_property PACKAGE_PIN F24 [get_ports {si1153_scl}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_scl}]

# PORTA-30 
set_property PACKAGE_PIN J26 [get_ports {lsm9ds1_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdi_sdo}]

# PORTA-31 
set_property PACKAGE_PIN F25 [get_ports {si1153_sda}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_sda}]

# PORTA-32 
set_property PACKAGE_PIN J25 [get_ports {si1153_int}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_int}]

# PORTA-34 
set_property PACKAGE_PIN H26 [get_ports {spi_clk}]
set_property IOSTANDARD LVCMOS18 [get_ports {spi_clk}]


