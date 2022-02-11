############################################################################
# XEM7320 - Xilinx constraints file
#
# Pin mappings for the XEM7320 signal generator example.
#
# Copyright (c) 2004-2018 Opal Kelly Incorporated
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
set_property IOSTANDARD LVDS_25 [get_ports {sys_clkp}]
set_property PACKAGE_PIN D17 [get_ports {sys_clkp}]

set_property IOSTANDARD LVDS_25 [get_ports {sys_clkn}]
set_property PACKAGE_PIN C17 [get_ports {sys_clkn}]

create_clock -name sys_clk -period 5 [get_ports sys_clkp]
set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {mmcm0_clk0 okUH0}]

############################################################################
## User Reset
############################################################################
set_property PACKAGE_PIN Y18 [get_ports {reset}]
set_property IOSTANDARD LVCMOS18 [get_ports {reset}]
set_property SLEW FAST [get_ports {reset}]

############################################################################
## SYZYGY Ports
############################################################################
## DAC ##
# PORTA-5 
set_property PACKAGE_PIN AA10 [get_ports {dac_data[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[0]}]

# PORTA-6 
set_property PACKAGE_PIN AA9 [get_ports {dac_data[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[1]}]

# PORTA-7 
set_property PACKAGE_PIN AA11 [get_ports {dac_data[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[2]}]

# PORTA-8 
set_property PACKAGE_PIN AB10 [get_ports {dac_data[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[3]}]

# PORTA-9 
set_property PACKAGE_PIN Y11 [get_ports {dac_data[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[4]}]

# PORTA-10 
set_property PACKAGE_PIN AA13 [get_ports {dac_data[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[5]}]

# PORTA-11 
set_property PACKAGE_PIN Y12 [get_ports {dac_data[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[6]}]

# PORTA-12 
set_property PACKAGE_PIN AB13 [get_ports {dac_data[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[7]}]

# PORTA-13 
set_property PACKAGE_PIN AB16 [get_ports {dac_data[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[8]}]

# PORTA-14 
set_property PACKAGE_PIN V10 [get_ports {dac_data[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[9]}]

# PORTA-15 
set_property PACKAGE_PIN AB17 [get_ports {dac_data[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[10]}]

# PORTA-16 
set_property PACKAGE_PIN W10 [get_ports {dac_data[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {dac_data[11]}]

# PORTA-17 
set_property PACKAGE_PIN AB11 [get_ports dac_cs_n]
set_property IOSTANDARD LVCMOS18 [get_ports dac_cs_n]

# PORTA-18 
set_property PACKAGE_PIN Y16 [get_ports dac_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sclk]

# PORTA-19 
set_property PACKAGE_PIN AB12 [get_ports dac_sdio]
set_property IOSTANDARD LVCMOS18 [get_ports dac_sdio]

# PORTA-20 
set_property PACKAGE_PIN AA16 [get_ports dac_opamp_en]
set_property IOSTANDARD LVCMOS18 [get_ports dac_opamp_en]

# PORTA-21 
set_property PACKAGE_PIN Y14 [get_ports dac_reset_pinmd]
set_property IOSTANDARD LVCMOS18 [get_ports dac_reset_pinmd]

# PORTA-34 
set_property PACKAGE_PIN W15 [get_ports dac_clk]
set_property IOSTANDARD LVCMOS18 [get_ports dac_clk]

## I2S2 PMOD ##

# PORTB-13 
set_property PACKAGE_PIN U2 [get_ports i2s2_rx_sdin]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_sdin]

# PORTB-14 
set_property PACKAGE_PIN AA1 [get_ports i2s2_tx_sdout]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_sdout]

# PORTB-15 
set_property PACKAGE_PIN V2 [get_ports i2s2_rx_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_sclk]

# PORTB-16 
set_property PACKAGE_PIN AB1 [get_ports i2s2_tx_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_sclk]

# PORTB-17 
set_property PACKAGE_PIN W2 [get_ports i2s2_rx_lrck]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_lrck]

# PORTB-18 
set_property PACKAGE_PIN Y3 [get_ports i2s2_tx_lrck]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_lrck]

# PORTB-19 
set_property PACKAGE_PIN Y2 [get_ports i2s2_rx_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_rx_mclk]

# PORTB-20 
set_property PACKAGE_PIN AA3 [get_ports i2s2_tx_mclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s2_tx_mclk]

############################################################################
## LEDs
############################################################################
set_property PACKAGE_PIN A13 [get_ports {led[0]}]
set_property PACKAGE_PIN B13 [get_ports {led[1]}]
set_property PACKAGE_PIN A14 [get_ports {led[2]}]
set_property PACKAGE_PIN A15 [get_ports {led[3]}]
set_property PACKAGE_PIN B15 [get_ports {led[4]}]
set_property PACKAGE_PIN A16 [get_ports {led[5]}]
set_property PACKAGE_PIN B16 [get_ports {led[6]}]
set_property PACKAGE_PIN B17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[*]}]

############################################################################
## Timing
############################################################################
create_generated_clock -name dac_clk -source [get_pins szg_dac/dac_phy_impl/ODDR_inst/C] -divide_by 1 [get_ports dac_clk]

set_output_delay -clock [get_clocks dac_clk] -clock_fall -min -add_delay -1.500 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -clock_fall -max -add_delay 0.250 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -min -add_delay -1.600 [get_ports {dac_data[*]}]
set_output_delay -clock [get_clocks dac_clk] -max -add_delay 0.130 [get_ports {dac_data[*]}]
