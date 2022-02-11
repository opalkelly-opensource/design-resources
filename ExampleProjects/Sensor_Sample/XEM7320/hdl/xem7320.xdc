############################################################################
# XEM7320 - Xilinx constraints file
#
# Pin mappings for the XEM7320.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2017 Opal Kelly Incorporated
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

set_property PACKAGE_PIN N13 [get_ports {okAA}]
set_property IOSTANDARD LVCMOS18 [get_ports {okAA}]


create_clock -name okUH0 -period 9.920 [get_ports {okUH[0]}]

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {okUH[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}] 10.000 [get_ports {okUH[*]}]
set_multicycle_path -setup -from [get_ports {okUH[*]}] 2

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {okUHU[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
set_multicycle_path -setup -from [get_ports {okUHU[*]}] 2

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okUHU[*]}]


############################################################################
## System Clock
############################################################################
#set_property IOSTANDARD LVDS_25 [get_ports {sys_clkp}]
#set_property PACKAGE_PIN D17 [get_ports {sys_clkp}]

#set_property IOSTANDARD LVDS_25 [get_ports {sys_clkn}]
#set_property PACKAGE_PIN C17 [get_ports {sys_clkn}]

#create_clock -name sys_clk -period 5 [get_ports sys_clkp]
#set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {mmcm0_clk0 okUH0}]

# PORTA-5 
set_property PACKAGE_PIN AA10 [get_ports {cam_m8q_spi_cs_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_spi_cs_n}]

# PORTA-6 
set_property PACKAGE_PIN AA9 [get_ports {hts221_cs}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_cs}]

# PORTA-7 
set_property PACKAGE_PIN AA11 [get_ports {cam_m8q_extint}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_extint}]

# PORTA-8 
set_property PACKAGE_PIN AB10 [get_ports {hts221_drdy}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_drdy}]

# PORTA-9 
set_property PACKAGE_PIN Y11 [get_ports {cam_m8q_timepulse}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_timepulse}]

# PORTA-10 
set_property PACKAGE_PIN AA13 [get_ports {hts221_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {hts221_spi_sdi_sdo}]

# PORTA-11 
set_property PACKAGE_PIN Y12 [get_ports {cam_m8q_d_sel}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_d_sel}]

# PORTA-12 
set_property PACKAGE_PIN AB13 [get_ports {lsm9ds1_den_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_den_ag}]

# PORTA-13 
set_property PACKAGE_PIN AB16 [get_ports {cam_m8q_safeboot_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_safeboot_n}]

# PORTA-14 
set_property PACKAGE_PIN V10 [get_ports {lsm9ds1_int2_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int2_ag}]

# PORTA-15 
set_property PACKAGE_PIN AB17 [get_ports {cam_m8q_uart_txd_spi_miso}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_uart_txd_spi_miso}]

# PORTA-16 
set_property PACKAGE_PIN W10 [get_ports {lsm9ds1_int1_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int1_ag}]

# PORTA-17 
set_property PACKAGE_PIN AB11 [get_ports {cam_m8q_uart_rxd_spi_mosi}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam_m8q_uart_rxd_spi_mosi}]

# PORTA-18 
set_property PACKAGE_PIN Y16 [get_ports {lsm9ds1_int_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_int_m}]

# PORTA-19 
set_property PACKAGE_PIN AB12 [get_ports {gnss_ext_ant_en}]
set_property IOSTANDARD LVCMOS18 [get_ports {gnss_ext_ant_en}]

# PORTA-20 
set_property PACKAGE_PIN AA16 [get_ports {lsm9ds1_cs_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_cs_m}]

# PORTA-21 
set_property PACKAGE_PIN Y14 [get_ports {lps22hb_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_spi_sdi_sdo}]

# PORTA-22 
set_property PACKAGE_PIN W14 [get_ports {lsm9ds1_drdy_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_drdy_m}]

# PORTA-23 
set_property PACKAGE_PIN AA15 [get_ports {lps22hb_spi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_spi_sdo}]

# PORTA-24 
set_property PACKAGE_PIN V13 [get_ports {lsm9ds1_cs_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_cs_ag}]

# PORTA-25 
set_property PACKAGE_PIN U15 [get_ports {lps22hb_int_drdy}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_int_drdy}]

# PORTA-26 
set_property PACKAGE_PIN V14 [get_ports {lsm9ds1_spi_sdo_m}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdo_m}]

# PORTA-27 
set_property PACKAGE_PIN AB15 [get_ports {lps22hb_cs}]
set_property IOSTANDARD LVCMOS18 [get_ports {lps22hb_cs}]

# PORTA-28 
set_property PACKAGE_PIN V15 [get_ports {lsm9ds1_spi_sdo_ag}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdo_ag}]

# PORTA-29 
set_property PACKAGE_PIN AA14 [get_ports {si1153_scl}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_scl}]

# PORTA-30 
set_property PACKAGE_PIN T14 [get_ports {lsm9ds1_spi_sdi_sdo}]
set_property IOSTANDARD LVCMOS18 [get_ports {lsm9ds1_spi_sdi_sdo}]

# PORTA-31 
set_property PACKAGE_PIN Y13 [get_ports {si1153_sda}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_sda}]

# PORTA-32 
set_property PACKAGE_PIN T15 [get_ports {si1153_int}]
set_property IOSTANDARD LVCMOS18 [get_ports {si1153_int}]

# PORTA-34 
set_property PACKAGE_PIN W15 [get_ports {spi_clk}]
set_property IOSTANDARD LVCMOS18 [get_ports {spi_clk}]


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
