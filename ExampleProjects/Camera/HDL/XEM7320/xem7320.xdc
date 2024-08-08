############################################################################
# XEM7320 - Xilinx constraints file
#
# Pin mappings for the XEM7320.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
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
set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p}]
set_property PACKAGE_PIN D17 [get_ports {sys_clk_p}]

set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_n}]
set_property PACKAGE_PIN C17 [get_ports {sys_clk_n}]


############################################################################
## SYZYGY PORTA - SZG-CAMERA Peripheral
############################################################################

# PORTA-5 
set_property PACKAGE_PIN AA10 [get_ports {slvs_p[0]}]

# PORTA-7 
set_property PACKAGE_PIN AA11 [get_ports {slvs_n[0]}]

# PORTA-8 
set_property PACKAGE_PIN AB10 [get_ports {cam_reset_b}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_reset_b}]

# PORTA-9 
set_property PACKAGE_PIN Y11 [get_ports {slvs_p[1]}]

# PORTA-11 
set_property PACKAGE_PIN Y12 [get_ports {slvs_n[1]}]

# PORTA-13 
set_property PACKAGE_PIN AB16 [get_ports {slvs_p[2]}]
# PORTA-15 
set_property PACKAGE_PIN AB17 [get_ports {slvs_n[2]}]

# PORTA-17 
set_property PACKAGE_PIN AB11 [get_ports {slvs_p[3]}]

# PORTA-19 
set_property PACKAGE_PIN AB12 [get_ports {slvs_n[3]}]

# PORTA-21 
set_property PACKAGE_PIN Y14 [get_ports {cam_sdata}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_sdata}]

# PORTA-23 
set_property PACKAGE_PIN AA15 [get_ports {cam_sclk}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_sclk}]

# PORTA-25 
set_property PACKAGE_PIN U15 [get_ports {cam_saddr}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_saddr}]

# PORTA-33 
set_property PACKAGE_PIN W11 [get_ports {slvsc_p}]
set_property IOSTANDARD LVDS_25 [get_ports {slvsc_p}]

# PORTA-34 
set_property PACKAGE_PIN W15 [get_ports {cam_extclk}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_extclk}]

# PORTA-35 
set_property PACKAGE_PIN W12 [get_ports {slvsc_n}]
set_property IOSTANDARD LVDS_25 [get_ports {slvsc_n}]

set_property IOSTANDARD LVDS_25 [get_ports {slvs_p[*]}]
set_property IOSTANDARD LVDS_25 [get_ports {slvs_n[*]}]

create_clock -period 6.80 -name slvsc_p -waveform {0.000 3.401} [get_ports slvsc_p]
set_input_delay -clock [get_clocks slvsc_p] -clock_fall -min -add_delay 1.020 [get_ports {slvs_n[*]}]
set_input_delay -clock [get_clocks slvsc_p] -clock_fall -max -add_delay 2.381 [get_ports {slvs_n[*]}]
set_input_delay -clock [get_clocks slvsc_p] -min -add_delay 1.020 [get_ports {slvs_n[*]}]
set_input_delay -clock [get_clocks slvsc_p] -max -add_delay 2.381 [get_ports {slvs_n[*]}]
set_input_delay -clock [get_clocks slvsc_p] -clock_fall -min -add_delay 1.020 [get_ports {slvs_p[*]}]
set_input_delay -clock [get_clocks slvsc_p] -clock_fall -max -add_delay 2.381 [get_ports {slvs_p[*]}]
set_input_delay -clock [get_clocks slvsc_p] -min -add_delay 1.020 [get_ports {slvs_p[*]}]
set_input_delay -clock [get_clocks slvsc_p] -max -add_delay 2.381 [get_ports {slvs_p[*]}]

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

# Note: DRAM constraints are handled by the Xilinx IP at this time.
# DRAM #####################################################################
#set_property PACKAGE_PIN N18 [get_ports {ddr3_dq[0]}]
#set_property PACKAGE_PIN L20 [get_ports {ddr3_dq[1]}]
#set_property PACKAGE_PIN N20 [get_ports {ddr3_dq[2]}]
#set_property PACKAGE_PIN K18 [get_ports {ddr3_dq[3]}]
#set_property PACKAGE_PIN M18 [get_ports {ddr3_dq[4]}]
#set_property PACKAGE_PIN K19 [get_ports {ddr3_dq[5]}]
#set_property PACKAGE_PIN N19 [get_ports {ddr3_dq[6]}]
#set_property PACKAGE_PIN L18 [get_ports {ddr3_dq[7]}]
#set_property PACKAGE_PIN L16 [get_ports {ddr3_dq[8]}]
#set_property PACKAGE_PIN L14 [get_ports {ddr3_dq[9]}]
#set_property PACKAGE_PIN K14 [get_ports {ddr3_dq[10]}]
#set_property PACKAGE_PIN M15 [get_ports {ddr3_dq[11]}]
#set_property PACKAGE_PIN K16 [get_ports {ddr3_dq[12]}]
#set_property PACKAGE_PIN M13 [get_ports {ddr3_dq[13]}]
#set_property PACKAGE_PIN K13 [get_ports {ddr3_dq[14]}]
#set_property PACKAGE_PIN L13 [get_ports {ddr3_dq[15]}]
#set_property PACKAGE_PIN D22 [get_ports {ddr3_dq[16]}]
#set_property PACKAGE_PIN C20 [get_ports {ddr3_dq[17]}]
#set_property PACKAGE_PIN E21 [get_ports {ddr3_dq[18]}]
#set_property PACKAGE_PIN D21 [get_ports {ddr3_dq[19]}]
#set_property PACKAGE_PIN G21 [get_ports {ddr3_dq[20]}]
#set_property PACKAGE_PIN C22 [get_ports {ddr3_dq[21]}]
#set_property PACKAGE_PIN E22 [get_ports {ddr3_dq[22]}]
#set_property PACKAGE_PIN B22 [get_ports {ddr3_dq[23]}]
#set_property PACKAGE_PIN A20 [get_ports {ddr3_dq[24]}]
#set_property PACKAGE_PIN D19 [get_ports {ddr3_dq[25]}]
#set_property PACKAGE_PIN A19 [get_ports {ddr3_dq[26]}]
#set_property PACKAGE_PIN F19 [get_ports {ddr3_dq[27]}]
#set_property PACKAGE_PIN C18 [get_ports {ddr3_dq[28]}]
#set_property PACKAGE_PIN E19 [get_ports {ddr3_dq[29]}]
#set_property PACKAGE_PIN A18 [get_ports {ddr3_dq[30]}]
#set_property PACKAGE_PIN C19 [get_ports {ddr3_dq[31]}]
#set_property SLEW FAST [get_ports {ddr3_dq[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[*]}]
#
#set_property PACKAGE_PIN J21 [get_ports {ddr3_addr[0]}]
#set_property PACKAGE_PIN J22 [get_ports {ddr3_addr[1]}]
#set_property PACKAGE_PIN K21 [get_ports {ddr3_addr[2]}]
#set_property PACKAGE_PIN H22 [get_ports {ddr3_addr[3]}]
#set_property PACKAGE_PIN G13 [get_ports {ddr3_addr[4]}]
#set_property PACKAGE_PIN G17 [get_ports {ddr3_addr[5]}]
#set_property PACKAGE_PIN H15 [get_ports {ddr3_addr[6]}]
#set_property PACKAGE_PIN G16 [get_ports {ddr3_addr[7]}]
#set_property PACKAGE_PIN G20 [get_ports {ddr3_addr[8]}]
#set_property PACKAGE_PIN M21 [get_ports {ddr3_addr[9]}]
#set_property PACKAGE_PIN J15 [get_ports {ddr3_addr[10]}]
#set_property PACKAGE_PIN G15 [get_ports {ddr3_addr[11]}]
#set_property PACKAGE_PIN H13 [get_ports {ddr3_addr[12]}]
#set_property PACKAGE_PIN K22 [get_ports {ddr3_addr[13]}]
#set_property PACKAGE_PIN L21 [get_ports {ddr3_addr[14]}]
#set_property SLEW FAST [get_ports {ddr3_addr[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[*]}]
#
#set_property PACKAGE_PIN H18 [get_ports {ddr3_ba[0]}]
#set_property PACKAGE_PIN J19 [get_ports {ddr3_ba[1]}]
#set_property PACKAGE_PIN H19 [get_ports {ddr3_ba[2]}]
#set_property SLEW FAST [get_ports {ddr3_ba[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[*]}]
#
#set_property PACKAGE_PIN J16 [get_ports {ddr3_ras_n}]
#set_property SLEW FAST [get_ports {ddr3_ras_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ras_n}]
#
#set_property PACKAGE_PIN H17 [get_ports {ddr3_cas_n}]
#set_property SLEW FAST [get_ports {ddr3_cas_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cas_n}]
#
#set_property PACKAGE_PIN J20 [get_ports {ddr3_we_n}]
#set_property SLEW FAST [get_ports {ddr3_we_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_we_n}]
#
#set_property PACKAGE_PIN F21 [get_ports {ddr3_reset_n}]
#set_property SLEW FAST [get_ports {ddr3_reset_n}]
#set_property IOSTANDARD LVCMOS15 [get_ports {ddr3_reset_n}]
#
#set_property PACKAGE_PIN G18 [get_ports {ddr3_cke[0]}]
#set_property SLEW FAST [get_ports {ddr3_cke[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke[*]}]
#
#set_property PACKAGE_PIN H20 [get_ports {ddr3_odt[0]}]
#set_property SLEW FAST [get_ports {ddr3_odt[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[*]}]
#
#set_property PACKAGE_PIN L19 [get_ports {ddr3_dm[0]}]
#set_property PACKAGE_PIN L15 [get_ports {ddr3_dm[1]}]
#set_property PACKAGE_PIN D20 [get_ports {ddr3_dm[2]}]
#set_property PACKAGE_PIN B20 [get_ports {ddr3_dm[3]}]
#set_property SLEW FAST [get_ports {ddr3_dm[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[*]}]
#
#set_property PACKAGE_PIN N22 [get_ports {ddr3_dqs_p[0]}]
#set_property PACKAGE_PIN M22 [get_ports {ddr3_dqs_n[0]}]
#set_property PACKAGE_PIN K17 [get_ports {ddr3_dqs_p[1]}]
#set_property PACKAGE_PIN J17 [get_ports {ddr3_dqs_n[1]}]
#set_property PACKAGE_PIN B21 [get_ports {ddr3_dqs_p[2]}]
#set_property PACKAGE_PIN A21 [get_ports {ddr3_dqs_n[2]}]
#set_property PACKAGE_PIN F18 [get_ports {ddr3_dqs_p[3]}]
#set_property PACKAGE_PIN E18 [get_ports {ddr3_dqs_n[3]}]
#set_property SLEW FAST [get_ports {ddr3_dqs*}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs*}]
#
#set_property PACKAGE_PIN J14 [get_ports {ddr3_ck_p[0]}]
#set_property PACKAGE_PIN H14 [get_ports {ddr3_ck_n[0]}]
#set_property SLEW FAST [get_ports {ddr3_ck*}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_*}]


#**************************************************************
# Asyncronous Clocks
#**************************************************************
set_clock_groups -name async-pixclk-clk_pll -asynchronous -group  {slvsc_p pix_clk}  -group {clk_out1_mig_pix_clkgen clk_pll_i sys_clk_p} -group {okUH0 mmcm0_clk0}
