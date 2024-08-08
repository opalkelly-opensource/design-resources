############################################################################
# XEM7350-K70T - Xilinx constraints file for EVB1006
#
# Pin mappings for the XEM7350-K70T.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2013 Opal Kelly Incorporated
# $Rev: 962 $ $Date: 2011-08-04 11:00:03 -0500 (Thu, 04 Aug 2011) $
############################################################################

set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

############################################################################
## System Clocks                                                        
############################################################################
# PadFunction: IO_L14P_T2_SRCC_34 
set_property IOSTANDARD LVDS [get_ports {sys_clkp}]
set_property PACKAGE_PIN AC4 [get_ports {sys_clkp}]

# PadFunction: IO_L14N_T2_SRCC_34 
set_property IOSTANDARD LVDS [get_ports {sys_clkn}]
set_property PACKAGE_PIN AC3 [get_ports {sys_clkn}]

create_clock -name sys_clk -period 5 [get_ports sys_clkp]
#set_propagated_clock sys_clk_p
          
#create_clock -name clk_ref_i -period 5 [get_ports clk_ref_i]
#set_propagated_clock clk_ref_i

############################################################################
## FrontPanel Host Interface
############################################################################
set_property SLEW FAST [get_ports {okHU[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[0]}]
set_property PACKAGE_PIN F23 [get_ports {okHU[0]}]

set_property SLEW FAST [get_ports {okHU[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[1]}]
set_property PACKAGE_PIN H23 [get_ports {okHU[1]}]

set_property SLEW FAST [get_ports {okHU[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okHU[2]}]
set_property PACKAGE_PIN J25 [get_ports {okHU[2]}]


set_property IOSTANDARD LVCMOS18 [get_ports {okUH[0]}]
set_property PACKAGE_PIN F22 [get_ports {okUH[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {okUH[1]}]
set_property PACKAGE_PIN G24 [get_ports {okUH[1]}]

set_property IOSTANDARD LVCMOS18 [get_ports {okUH[2]}]
set_property PACKAGE_PIN J26 [get_ports {okUH[2]}]

set_property IOSTANDARD LVCMOS18 [get_ports {okUH[3]}]
set_property PACKAGE_PIN G26 [get_ports {okUH[3]}]

set_property IOSTANDARD LVCMOS18 [get_ports {okUH[4]}]
set_property PACKAGE_PIN C23 [get_ports {okUH[4]}]


set_property SLEW FAST [get_ports {okUHU[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[0]}]
set_property PACKAGE_PIN B21 [get_ports {okUHU[0]}]

set_property SLEW FAST [get_ports {okUHU[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[1]}]
set_property PACKAGE_PIN C21 [get_ports {okUHU[1]}]

set_property SLEW FAST [get_ports {okUHU[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[2]}]
set_property PACKAGE_PIN E22 [get_ports {okUHU[2]}]

set_property SLEW FAST [get_ports {okUHU[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[3]}]
set_property PACKAGE_PIN A20 [get_ports {okUHU[3]}]

set_property SLEW FAST [get_ports {okUHU[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[4]}]
set_property PACKAGE_PIN B20 [get_ports {okUHU[4]}]

set_property SLEW FAST [get_ports {okUHU[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[5]}]
set_property PACKAGE_PIN C22 [get_ports {okUHU[5]}]

set_property SLEW FAST [get_ports {okUHU[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[6]}]
set_property PACKAGE_PIN D21 [get_ports {okUHU[6]}]

set_property SLEW FAST [get_ports {okUHU[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[7]}]
set_property PACKAGE_PIN C24 [get_ports {okUHU[7]}]

set_property SLEW FAST [get_ports {okUHU[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[8]}]
set_property PACKAGE_PIN C26 [get_ports {okUHU[8]}]

set_property SLEW FAST [get_ports {okUHU[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[9]}]
set_property PACKAGE_PIN D26 [get_ports {okUHU[9]}]

set_property SLEW FAST [get_ports {okUHU[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[10]}]
set_property PACKAGE_PIN A24 [get_ports {okUHU[10]}]

set_property SLEW FAST [get_ports {okUHU[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[11]}]
set_property PACKAGE_PIN A23 [get_ports {okUHU[11]}]

set_property SLEW FAST [get_ports {okUHU[12]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[12]}]
set_property PACKAGE_PIN A22 [get_ports {okUHU[12]}]

set_property SLEW FAST [get_ports {okUHU[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[13]}]
set_property PACKAGE_PIN B22 [get_ports {okUHU[13]}]

set_property SLEW FAST [get_ports {okUHU[14]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[14]}]
set_property PACKAGE_PIN A25 [get_ports {okUHU[14]}]

set_property SLEW FAST [get_ports {okUHU[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[15]}]
set_property PACKAGE_PIN B24 [get_ports {okUHU[15]}]

set_property SLEW FAST [get_ports {okUHU[16]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[16]}]
set_property PACKAGE_PIN G21 [get_ports {okUHU[16]}]

set_property SLEW FAST [get_ports {okUHU[17]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[17]}]
set_property PACKAGE_PIN E23 [get_ports {okUHU[17]}]

set_property SLEW FAST [get_ports {okUHU[18]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[18]}]
set_property PACKAGE_PIN E21 [get_ports {okUHU[18]}]

set_property SLEW FAST [get_ports {okUHU[19]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[19]}]
set_property PACKAGE_PIN H22 [get_ports {okUHU[19]}]

set_property SLEW FAST [get_ports {okUHU[20]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[20]}]
set_property PACKAGE_PIN D23 [get_ports {okUHU[20]}]

set_property SLEW FAST [get_ports {okUHU[21]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[21]}]
set_property PACKAGE_PIN J21 [get_ports {okUHU[21]}]

set_property SLEW FAST [get_ports {okUHU[22]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[22]}]
set_property PACKAGE_PIN K22 [get_ports {okUHU[22]}]

set_property SLEW FAST [get_ports {okUHU[23]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[23]}]
set_property PACKAGE_PIN D24 [get_ports {okUHU[23]}]

set_property SLEW FAST [get_ports {okUHU[24]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[24]}]
set_property PACKAGE_PIN K23 [get_ports {okUHU[24]}]

set_property SLEW FAST [get_ports {okUHU[25]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[25]}]
set_property PACKAGE_PIN H24 [get_ports {okUHU[25]}]

set_property SLEW FAST [get_ports {okUHU[26]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[26]}]
set_property PACKAGE_PIN F24 [get_ports {okUHU[26]}]

set_property SLEW FAST [get_ports {okUHU[27]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[27]}]
set_property PACKAGE_PIN D25 [get_ports {okUHU[27]}]

set_property SLEW FAST [get_ports {okUHU[28]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[28]}]
set_property PACKAGE_PIN J24 [get_ports {okUHU[28]}]

set_property SLEW FAST [get_ports {okUHU[29]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[29]}]
set_property PACKAGE_PIN B26 [get_ports {okUHU[29]}]

set_property SLEW FAST [get_ports {okUHU[30]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[30]}]
set_property PACKAGE_PIN H26 [get_ports {okUHU[30]}]

set_property SLEW FAST [get_ports {okUHU[31]}]
set_property IOSTANDARD LVCMOS18 [get_ports {okUHU[31]}]
set_property PACKAGE_PIN E26 [get_ports {okUHU[31]}]


set_property IOSTANDARD LVCMOS33 [get_ports {okAA}]
set_property PACKAGE_PIN R26 [get_ports {okAA}]

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
## Expansion Connectors
############################################################################

# FMC  ###############################################################
#   IOSTANDARDS assume VADJ = VIO_B_M2C = 2.5V 
#   make adjustemts as necessary for other voltages/standards.
######################################################################

# EVB1006 Constraints ################################################
set_property IOSTANDARD LVCMOS25 [get_ports {pix_clk}]
set_property PACKAGE_PIN H17 [get_ports {pix_clk}]
#P2-G6,  LA00_P_CC

#--------------------------------------------------------------------------
# The constraints below are for a pixel clock of 72 MHz with input capture
# being performed on the falling edge of PIX_CLK.
#create_clock -name pix_clk -period 13.8 [get_ports pix_clk]

create_clock -name {pixclk} -period 13.800 -waveform { 0.000 6.900 } [get_ports {pix_clk}]
create_clock -name {virt_pixclk} -period 13.800 -waveform { 0.000 6.900 } 

set_property IOSTANDARD LVCMOS25 [get_ports {pix_extclk}]
set_property PACKAGE_PIN H18 [get_ports {pix_extclk}]
#P3-G7,  LA00_N_CC

set_property IOSTANDARD LVCMOS25 [get_ports {pix_reset}]
set_property PACKAGE_PIN G17 [get_ports {pix_reset}]
#P3-D8,  LA01_P_CC

set_property IOSTANDARD LVCMOS25 [get_ports {pix_trigger}]
set_property PACKAGE_PIN F18 [get_ports {pix_trigger}]
#P3-D9,  LA01_N_CC

set_property IOSTANDARD LVCMOS25 [get_ports {pix_strobe}]
set_property PACKAGE_PIN G19 [get_ports {pix_strobe}]
#P3-H7,  LA02_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_lv}]
set_property PACKAGE_PIN F20 [get_ports {pix_lv}]
#P3-H8,  LA02_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_fv}]
set_property PACKAGE_PIN A18 [get_ports {pix_fv}]
#P3-G9,  LA03_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_sclk}]
set_property PACKAGE_PIN A19 [get_ports {pix_sclk}]
#P3-G10, LA03_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_sdata}]
set_property PACKAGE_PIN D19 [get_ports {pix_sdata}]
#P3-H10, LA04_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[11]}]
set_property PACKAGE_PIN D20 [get_ports {pix_data[11]}]
#P3-H11, LA04_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[9]}]
set_property PACKAGE_PIN C17 [get_ports {pix_data[9]}]
#P3-D11, LA05_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[5]}]
set_property PACKAGE_PIN C18 [get_ports {pix_data[5]}]
#P3-D12, LA05_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[10]}]
set_property PACKAGE_PIN C19 [get_ports {pix_data[10]}]
#P3-C10, LA06_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[8]}]
set_property PACKAGE_PIN B19 [get_ports {pix_data[8]}]
#P3-C11, LA06_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[6]}]
set_property PACKAGE_PIN J18 [get_ports {pix_data[6]}]
#P3-H13, LA07_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[3]}]
set_property PACKAGE_PIN J19 [get_ports {pix_data[3]}]
#P3-H14, LA07_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[7]}]
set_property PACKAGE_PIN F19 [get_ports {pix_data[7]}]
#P3-G12, LA08_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[4]}]
set_property PACKAGE_PIN E20 [get_ports {pix_data[4]}]
#P3-G13, LA08_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[2]}]
set_property PACKAGE_PIN L19 [get_ports {pix_data[2]}]
#P3-D14, LA09_P

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[0]}]
set_property PACKAGE_PIN L20 [get_ports {pix_data[0]}]
#P3-D15, LA09_N

set_property IOSTANDARD LVCMOS25 [get_ports {pix_data[1]}]
set_property PACKAGE_PIN B17 [get_ports {pix_data[1]}]
#P3-C14, LA10_P

#**************************************************************
# Set Input Delay
# Input maximum delay value = maximum trace delay for data + unit interval – tSU of external device – minimum trace delay for clock
# Input minimum delay value = minimum trace delay for data + tH of external device – maximum trace delay for clock
# Ignoring trace delays
# max = unit interval – tSU
# min = tH
#**************************************************************
set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall  12.8 [get_ports {pix_lv}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall   9.1 [get_ports {pix_lv}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   12.8 [get_ports {pix_fv}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    9.3 [get_ports {pix_fv}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[0]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[0]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[1]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[1]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[2]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[2]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[3]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[3]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[4]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[4]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[5]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[5]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[6]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[6]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[7]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[7]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[8]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[8]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[9]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[9]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[10]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[10]}]

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[11]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[11]}]


############################################################################
## Peripherals
############################################################################

# LEDs #####################################################################
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN T24 [get_ports {led[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN T25 [get_ports {led[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN R25 [get_ports {led[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN P26 [get_ports {led[3]}]

# DRAM #####################################################################
# PadFunction: IO_L20P_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[0]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN AD1 [get_ports {ddr3_dq[0]}]

# PadFunction: IO_L20N_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[1]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN AE1 [get_ports {ddr3_dq[1]}]

# PadFunction: IO_L22P_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[2]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN AE3 [get_ports {ddr3_dq[2]}]

# PadFunction: IO_L22N_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[3]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN AE2 [get_ports {ddr3_dq[3]}]

# PadFunction: IO_L23P_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[4]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN AE6 [get_ports {ddr3_dq[4]}]

# PadFunction: IO_L23N_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[5]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN AE5 [get_ports {ddr3_dq[5]}]

# PadFunction: IO_L24P_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[6]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN AF3 [get_ports {ddr3_dq[6]}]

# PadFunction: IO_L24N_T3_34 
set_property SLEW FAST [get_ports {ddr3_dq[7]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN AF2 [get_ports {ddr3_dq[7]}]

# PadFunction: IO_L1N_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[8]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN W11 [get_ports {ddr3_dq[8]}]

# PadFunction: IO_L2P_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[9]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN V8 [get_ports {ddr3_dq[9]}]

# PadFunction: IO_L2N_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[10]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN V7 [get_ports {ddr3_dq[10]}]

# PadFunction: IO_L4P_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[11]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN Y8 [get_ports {ddr3_dq[11]}]

# PadFunction: IO_L4N_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[12]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN Y7 [get_ports {ddr3_dq[12]}]

# PadFunction: IO_L5P_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[13]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN Y11 [get_ports {ddr3_dq[13]}]

# PadFunction: IO_L5N_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[14]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN Y10 [get_ports {ddr3_dq[14]}]

# PadFunction: IO_L6P_T0_33 
set_property SLEW FAST [get_ports {ddr3_dq[15]}]
set_property IOSTANDARD SSTL15_T_DCI [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN V9 [get_ports {ddr3_dq[15]}]

# PadFunction: IO_L1P_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[14]}]
set_property PACKAGE_PIN U6 [get_ports {ddr3_addr[14]}]

# PadFunction: IO_L1N_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN U5 [get_ports {ddr3_addr[13]}]

# PadFunction: IO_L2P_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN U2 [get_ports {ddr3_addr[12]}]

# PadFunction: IO_L2N_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN U1 [get_ports {ddr3_addr[11]}]

# PadFunction: IO_L4P_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN V3 [get_ports {ddr3_addr[10]}]

# PadFunction: IO_L4N_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN W3 [get_ports {ddr3_addr[9]}]

# PadFunction: IO_L5P_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN U7 [get_ports {ddr3_addr[8]}]

# PadFunction: IO_L5N_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN V6 [get_ports {ddr3_addr[7]}]

# PadFunction: IO_L6P_T0_34 
set_property SLEW FAST [get_ports {ddr3_addr[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN V4 [get_ports {ddr3_addr[6]}]

# PadFunction: IO_L7P_T1_34 
set_property SLEW FAST [get_ports {ddr3_addr[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN Y3 [get_ports {ddr3_addr[5]}]

# PadFunction: IO_L7N_T1_34 
set_property SLEW FAST [get_ports {ddr3_addr[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN Y2 [get_ports {ddr3_addr[4]}]

# PadFunction: IO_L8P_T1_34 
set_property SLEW FAST [get_ports {ddr3_addr[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN V2 [get_ports {ddr3_addr[3]}]

# PadFunction: IO_L8N_T1_34 
set_property SLEW FAST [get_ports {ddr3_addr[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN V1 [get_ports {ddr3_addr[2]}]

# PadFunction: IO_L9P_T1_DQS_34 
set_property SLEW FAST [get_ports {ddr3_addr[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN AB1 [get_ports {ddr3_addr[1]}]

# PadFunction: IO_L9N_T1_DQS_34 
set_property SLEW FAST [get_ports {ddr3_addr[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN AC1 [get_ports {ddr3_addr[0]}]

# PadFunction: IO_L10P_T1_34 
set_property SLEW FAST [get_ports {ddr3_ba[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[2]}]
set_property PACKAGE_PIN W1 [get_ports {ddr3_ba[2]}]

# PadFunction: IO_L10N_T1_34 
set_property SLEW FAST [get_ports {ddr3_ba[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN Y1 [get_ports {ddr3_ba[1]}]

# PadFunction: IO_L11P_T1_SRCC_34 
set_property SLEW FAST [get_ports {ddr3_ba[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN AB2 [get_ports {ddr3_ba[0]}]

# PadFunction: IO_L11N_T1_SRCC_34 
set_property SLEW FAST [get_ports {ddr3_ras_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_ras_n}]
set_property PACKAGE_PIN AC2 [get_ports {ddr3_ras_n}]

# PadFunction: IO_L12P_T1_MRCC_34 
set_property SLEW FAST [get_ports {ddr3_cas_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cas_n}]
set_property PACKAGE_PIN AA3 [get_ports {ddr3_cas_n}]

# PadFunction: IO_L12N_T1_MRCC_34 
set_property SLEW FAST [get_ports {ddr3_we_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_we_n}]
set_property PACKAGE_PIN AA2 [get_ports {ddr3_we_n}]

# PadFunction: IO_L13P_T2_MRCC_34 
set_property SLEW FAST [get_ports {ddr3_reset_n}]
set_property IOSTANDARD LVCMOS15 [get_ports {ddr3_reset_n}]
set_property PACKAGE_PIN AA4 [get_ports {ddr3_reset_n}]

# PadFunction: IO_L15N_T2_DQS_34 
set_property SLEW FAST [get_ports {ddr3_cke[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke[0]}]
set_property PACKAGE_PIN AB5 [get_ports {ddr3_cke[0]}]

# PadFunction: IO_L16P_T2_34 
set_property SLEW FAST [get_ports {ddr3_odt[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[0]}]
set_property PACKAGE_PIN AB6 [get_ports {ddr3_odt[0]}]

# PadFunction: IO_L15P_T2_DQS_34 
set_property SLEW FAST [get_ports {ddr3_cs_n[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_cs_n[0]}]
set_property PACKAGE_PIN AA5 [get_ports {ddr3_cs_n[0]}]

# PadFunction: IO_L19P_T3_34 
set_property SLEW FAST [get_ports {ddr3_dm[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN AD4 [get_ports {ddr3_dm[0]}]

# PadFunction: IO_L1P_T0_33 
set_property SLEW FAST [get_ports {ddr3_dm[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN V11 [get_ports {ddr3_dm[1]}]

# PadFunction: IO_L21P_T3_DQS_34 
set_property SLEW FAST [get_ports {ddr3_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL15_T_DCI [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN AF5 [get_ports {ddr3_dqs_p[0]}]

# PadFunction: IO_L21N_T3_DQS_34 
set_property SLEW FAST [get_ports {ddr3_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL15_T_DCI [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN AF4 [get_ports {ddr3_dqs_n[0]}]

# PadFunction: IO_L3P_T0_DQS_33 
set_property SLEW FAST [get_ports {ddr3_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL15_T_DCI [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN W10 [get_ports {ddr3_dqs_p[1]}]

# PadFunction: IO_L3N_T0_DQS_33 
set_property SLEW FAST [get_ports {ddr3_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL15_T_DCI [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN W9 [get_ports {ddr3_dqs_n[1]}]

# PadFunction: IO_L3P_T0_DQS_34 
set_property SLEW FAST [get_ports {ddr3_ck_p[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN W6 [get_ports {ddr3_ck_p[0]}]

# PadFunction: IO_L3N_T0_DQS_34 
set_property SLEW FAST [get_ports {ddr3_ck_n[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_n[0]}]
set_property PACKAGE_PIN W5 [get_ports {ddr3_ck_n[0]}]



set_property LOC PHASER_OUT_PHY_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y7 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y6 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y5 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y4 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]

set_property LOC PHASER_IN_PHY_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in}]
## set_property LOC PHASER_IN_PHY_X1Y7 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in}]
## set_property LOC PHASER_IN_PHY_X1Y6 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in}]
## set_property LOC PHASER_IN_PHY_X1Y5 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y4 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]



set_property LOC OUT_FIFO_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y7 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y6 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y5 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y4 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]

set_property LOC IN_FIFO_X1Y3 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y4 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo}]

set_property LOC PHY_CONTROL_X1Y0 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phy_control_i}]
set_property LOC PHY_CONTROL_X1Y1 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phy_control_i}]

set_property LOC PHASER_REF_X1Y0 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phaser_ref_i}]
set_property LOC PHASER_REF_X1Y1 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phaser_ref_i}]

set_property LOC OLOGIC_X1Y43 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y57 [get_cells  -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/*slave_ts}]

set_property LOC PLLE2_ADV_X1Y1 [get_cells -hier -filter {NAME =~ */plle2_i}]
set_property LOC MMCME2_ADV_X1Y1 [get_cells -hier -filter {NAME =~ */mmcm_i}]


set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}] \
                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] \
                    -setup 6

set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}] \
                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] \
                    -hold 5

set_false_path -through [get_pins -filter {NAME =~ */DQSFOUND} -of [get_cells -hier -filter {REF_NAME == PHASER_IN_PHY}]]

set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] -setup 2 -start
set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST} -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] -hold 1 -start

set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_mig_7series_v2_0_tempmon/*}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_mig_7series_v2_0_tempmon/device_temp_sync_r1*}] 20
set_max_delay -from [get_cells -hier rstdiv0_sync_r1*] -to [get_pins -filter {NAME =~ */RESET} -of [get_cells -hier -filter {REF_NAME == PHY_CONTROL}]] -datapath_only 5
          
set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ */rstdiv0_sync_r1*}] -to [get_cells -hier -filter {NAME =~ *temp_mon_enabled.u_mig_7series_v2_0_tempmon/*rst_r1*}] 20
      
#**************************************************************
# Asyncronous Clocks
#**************************************************************
set_clock_groups -name async-pixclk-clk_pll -asynchronous -group  {clk_pix_bufg_in virt_pixclk}  -group {clk_pll_i sys_clk} -group {okUH0 mmcm0_clk0}
