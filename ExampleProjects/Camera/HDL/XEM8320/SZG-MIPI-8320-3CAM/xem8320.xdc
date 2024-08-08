############################################################################
# XEM8320 - Xilinx constraints file
#
# Pin mappings for the XEM8320.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2022 Opal Kelly Incorporated
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
#set_multicycle_path -setup -from [get_ports {okUH[*]}] 2

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  7.000 [get_ports {okUHU[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
#set_multicycle_path -setup -from [get_ports {okUHU[*]}] 2

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {okUHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {okUHU[*]}]


############################################################################
## SYZYGY PORTA - SZG-MIPI-8320 Peripheral - Pcam connected to Camera 1
############################################################################

# PORTA-5 (S0_D0P)
set_property PACKAGE_PIN L18 [get_ports {mipi_phy_if_clk_p_1}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_p_1}]
# PORTA-7 (S2_D0N)
set_property PACKAGE_PIN K18 [get_ports {mipi_phy_if_clk_n_1}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_n_1}]
# PORTA-9 (S4_D2P)
set_property PACKAGE_PIN M20 [get_ports {mipi_phy_if_data_p_1[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_1[0]}]
# PORTA-11 (S6_D2N)
set_property PACKAGE_PIN M21 [get_ports {mipi_phy_if_data_n_1[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_1[0]}]
# PORTA-13 (S8_D4P)
set_property PACKAGE_PIN J19 [get_ports {mipi_phy_if_data_p_1[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_1[1]}]
# PORTA-15 (S10_D4N)
set_property PACKAGE_PIN J20 [get_ports {mipi_phy_if_data_n_1[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_1[1]}]

# PORTA-22 (S17)
set_property PACKAGE_PIN L19 [get_ports {pcam_sclk_1}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sclk_1}]
# PORTA-24 (S19)
set_property PACKAGE_PIN M19 [get_ports {pcam_sdata_1}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sdata_1}]
# PORTA-21 (S16)
set_property PACKAGE_PIN H24 [get_ports {pcam_power_en_1}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_power_en_1}]

############################################################################
## SYZYGY PORTB - SZG-MIPI-8320 Peripheral - Pcam connected to Camera 2
############################################################################

# PORTB-17 (S12_D6P)
set_property PACKAGE_PIN L22 [get_ports {mipi_phy_if_clk_p_2}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_p_2}]
# PORTB-19 (S14_D6N)
set_property PACKAGE_PIN L23 [get_ports {mipi_phy_if_clk_n_2}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_n_2}]
# PORTB-6 (S1_D1P)
set_property PACKAGE_PIN M25 [get_ports {mipi_phy_if_data_p_2[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_2[0]}]
# PORTB-8 (S3_D1N)
set_property PACKAGE_PIN M26 [get_ports {mipi_phy_if_data_n_2[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_2[0]}]
# PORTB-14 (S9_D5P)
set_property PACKAGE_PIN K25 [get_ports {mipi_phy_if_data_p_2[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_2[1]}]
# PORTB-16 (S11_D5N)
set_property PACKAGE_PIN K26 [get_ports {mipi_phy_if_data_n_2[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_2[1]}]

# PORTB-26 (S21)
set_property PACKAGE_PIN L20 [get_ports {pcam_sclk_2}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sclk_2}]
# PORTB-28 (S23)
set_property PACKAGE_PIN K20 [get_ports {pcam_sdata_2}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sdata_2}]
# PORTB-25 (S20)
set_property PACKAGE_PIN H23 [get_ports {pcam_power_en_2}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_power_en_2}]

############################################################################
## SYZYGY PORTC - SZG-MIPI-8320 Peripheral - Pcam connected to Camera 3
############################################################################

# PORTC-10 (S5_D3P)
set_property PACKAGE_PIN L24 [get_ports {mipi_phy_if_clk_p_3}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_p_3}]
# PORTC-12 (S7_D3N)
set_property PACKAGE_PIN L25 [get_ports {mipi_phy_if_clk_n_3}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_clk_n_3}]
# PORTC-18 (S13_D7P)
set_property PACKAGE_PIN K22 [get_ports {mipi_phy_if_data_p_3[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_3[0]}]
# PORTC-20 (S15_D7N)
set_property PACKAGE_PIN K23 [get_ports {mipi_phy_if_data_n_3[0]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_3[0]}]
# PORTC-33 (P2C_CLKp)
set_property PACKAGE_PIN J23 [get_ports {mipi_phy_if_data_p_3[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_p_3[1]}]
# PORTC-35 (P2C_CLKn)
set_property PACKAGE_PIN J24 [get_ports {mipi_phy_if_data_n_3[1]}]
set_property IOSTANDARD MIPI_DPHY_DCI [get_ports {mipi_phy_if_data_n_3[1]}]

# PORTC-30 (S25)
set_property PACKAGE_PIN J26 [get_ports {pcam_sclk_3}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sclk_3}]
# PORTC-32 (S27)
set_property PACKAGE_PIN J25 [get_ports {pcam_sdata_3}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_sdata_3}]
# PORTC-29 (S24)
set_property PACKAGE_PIN F24 [get_ports {pcam_power_en_3}]
set_property IOSTANDARD LVCMOS12 [get_ports {pcam_power_en_3}]

# LEDS #####################################################################
set_property PACKAGE_PIN G19 [get_ports {led[0]}]
set_property PACKAGE_PIN B16 [get_ports {led[1]}]
set_property PACKAGE_PIN F22 [get_ports {led[2]}]
set_property PACKAGE_PIN E22 [get_ports {led[3]}]
set_property PACKAGE_PIN M24 [get_ports {led[4]}]
set_property PACKAGE_PIN G22 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {led[*]}]

############################################################################
## DDR4 #IOSTANDARD, OUTPUT_IMPEDANCE, SLEW, etc. are set by the MIG generated outputs. 
############################################################################
set_property PACKAGE_PIN AF18 [ get_ports "ddr4_ba[1]" ]
set_property PACKAGE_PIN AF22 [ get_ports "ddr4_cs_n[0]" ]
set_property PACKAGE_PIN AC16 [ get_ports "ddr4_addr[11]" ]
set_property PACKAGE_PIN AD16 [ get_ports "ddr4_addr[13]" ]
set_property PACKAGE_PIN AA22 [ get_ports "ddr4_dqs_t[1]" ]
set_property PACKAGE_PIN AF19 [ get_ports "ddr4_addr[15]" ]
set_property PACKAGE_PIN AF20 [ get_ports "ddr4_addr[12]" ]
set_property PACKAGE_PIN AA19 [ get_ports "ddr4_addr[14]" ]
set_property PACKAGE_PIN AC22 [ get_ports "ddr4_dq[14]" ]
set_property PACKAGE_PIN AB22 [ get_ports "ddr4_dqs_c[1]" ]
set_property PACKAGE_PIN AD24 [ get_ports "ddr4_dq[6]" ]
set_property PACKAGE_PIN AF24 [ get_ports "ddr4_dq[0]" ]
set_property PACKAGE_PIN AB25 [ get_ports "ddr4_dq[1]" ]
set_property PACKAGE_PIN AA20 [ get_ports "ddr4_cke[0]" ]
set_property PACKAGE_PIN AA18 [ get_ports "ddr4_addr[16]" ]
set_property PACKAGE_PIN Y20  [ get_ports "ddr4_ck_t[0]" ]
set_property PACKAGE_PIN AD18 [ get_ports "ddr4_addr[0]" ]
set_property PACKAGE_PIN AC21 [ get_ports "ddr4_dq[15]" ]
set_property PACKAGE_PIN AE23 [ get_ports "ddr4_dq[10]" ]
set_property PACKAGE_PIN AD23 [ get_ports "ddr4_dq[11]" ]
set_property PACKAGE_PIN AD25 [ get_ports "ddr4_dq[7]" ]
set_property PACKAGE_PIN AC26 [ get_ports "ddr4_dqs_t[0]" ]
set_property PACKAGE_PIN Y17  [ get_ports "ddr4_addr[6]" ]
set_property PACKAGE_PIN Y21  [ get_ports "ddr4_ck_c[0]" ]
set_property PACKAGE_PIN AE17 [ get_ports "ddr4_addr[1]" ]
set_property PACKAGE_PIN AC23 [ get_ports "ddr4_dq[12]" ]
set_property PACKAGE_PIN AB21 [ get_ports "ddr4_dq[8]" ]
set_property PACKAGE_PIN AF25 [ get_ports "ddr4_dq[4]" ]
set_property PACKAGE_PIN AB24 [ get_ports "ddr4_dq[5]" ]
set_property PACKAGE_PIN AD26 [ get_ports "ddr4_dqs_c[0]" ]
set_property PACKAGE_PIN AE16 [ get_ports "ddr4_addr[7]" ]
set_property PACKAGE_PIN AD19 [ get_ports "ddr4_addr[4]" ]
set_property PACKAGE_PIN AA17 [ get_ports "ddr4_addr[8]" ]
set_property PACKAGE_PIN AD21 [ get_ports "ddr4_dq[13]" ]
set_property PACKAGE_PIN AE22 [ get_ports "ddr4_dm[1]" ]
set_property PACKAGE_PIN AE21 [ get_ports "ddr4_dq[9]" ]
set_property PACKAGE_PIN AE25 [ get_ports "ddr4_dm[0]" ]
set_property PACKAGE_PIN AB20 [ get_ports "ddr4_odt[0]" ]
set_property PACKAGE_PIN AF17 [ get_ports "ddr4_addr[5]" ]
set_property PACKAGE_PIN AB17 [ get_ports "ddr4_addr[2]" ]
set_property PACKAGE_PIN AE18 [ get_ports "ddr4_addr[3]" ]
set_property PACKAGE_PIN AE26 [ get_ports "ddr4_reset_n" ]
set_property PACKAGE_PIN Y18  [ get_ports "ddr4_act_n" ]
set_property PACKAGE_PIN AB26 [ get_ports "ddr4_dq[2]" ]
set_property PACKAGE_PIN AC24 [ get_ports "ddr4_dq[3]" ]
set_property PACKAGE_PIN AC18 [ get_ports "ddr4_ba[0]" ]
set_property PACKAGE_PIN AB19 [ get_ports "ddr4_bg[0]" ]
set_property PACKAGE_PIN AC17 [ get_ports "ddr4_addr[9]" ]
set_property PACKAGE_PIN AC19 [ get_ports "ddr4_addr[10]" ]

############################################################################
## DDR4 Clock. Additional constraints are set by the MIG generated outputs.
############################################################################
set_property PACKAGE_PIN AD20 [get_ports {ddr4_clk_p}]
set_property PACKAGE_PIN AE20 [get_ports {ddr4_clk_n}]

############################################################################
## System Clock
############################################################################
set_property PACKAGE_PIN T24 [get_ports {sys_clk_p}]
set_property IOSTANDARD LVDS [get_ports {sys_clk_p}]

set_property PACKAGE_PIN U24 [get_ports {sys_clk_n}]
set_property IOSTANDARD LVDS [get_ports {sys_clk_n}]

#**************************************************************
# Asyncronous Clocks
#**************************************************************
set_clock_groups -name async-groups -asynchronous \
-group [get_clocks -include_generated_clocks okUH0] \
-group [get_clocks -include_generated_clocks ddr4_clk_p]

#*******************************************************************************
# Pblocks that constrain cells to help resolve routing
#*******************************************************************************
create_pblock pblock_okHI
add_cells_to_pblock [get_pblocks pblock_okHI] [get_cells -quiet [list okHI]]
resize_pblock [get_pblocks pblock_okHI] -add {CLOCKREGION_X0Y1:CLOCKREGION_X0Y1}

create_pblock pblock_mipi_bufs
add_cells_to_pblock [get_pblocks pblock_mipi_bufs] [get_cells -quiet [list imgif0/imgif_cam1_master_i/mipi_phy_master_i/mipi_csi2_cam1_master_i/inst/phy/inst/inst/bd_3ea4_phy_0_rx_support_i/slave_rx.rxbyteclkhs_buf]]
add_cells_to_pblock [get_pblocks pblock_mipi_bufs] [get_cells -quiet [list imgif0/imgif_cam2_slave_i/mipi_phy_slave_i/mipi_csi2_cam2_slave_i/inst/phy/inst/inst/rxbyteclkhs_buf]]
add_cells_to_pblock [get_pblocks pblock_mipi_bufs] [get_cells -quiet [list imgif0/imgif_cam3_slave_i/mipi_phy_slave_i/mipi_csi2_cam3_slave_i/inst/phy/inst/inst/rxbyteclkhs_buf]]
resize_pblock [get_pblocks pblock_mipi_bufs] -add {CLOCKREGION_X0Y2:CLOCKREGION_X0Y2}