############################################################################
# XEM7010 - Xilinx constraints file
#
# Pin mappings for the XEM7010.  Use this as a template and comment out 
# the pins that are not used in your design.  (By default, map will fail
# if this file contains constraints for signals not in your design).
#
# Copyright (c) 2004-2016 Opal Kelly Incorporated
############################################################################

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

set_property PACKAGE_PIN P20 [get_ports {hi_muxsel}]
set_property IOSTANDARD LVCMOS33 [get_ports {hi_muxsel}]

############################################################################
## FrontPanel Host Interface
############################################################################
set_property PACKAGE_PIN Y18  [get_ports {hi_in[0]}]
set_property PACKAGE_PIN V17  [get_ports {hi_in[1]}]
set_property PACKAGE_PIN AA19 [get_ports {hi_in[2]}]
set_property PACKAGE_PIN V20  [get_ports {hi_in[3]}]
set_property PACKAGE_PIN W17  [get_ports {hi_in[4]}]
set_property PACKAGE_PIN AB20 [get_ports {hi_in[5]}]
set_property PACKAGE_PIN V19  [get_ports {hi_in[6]}]
set_property PACKAGE_PIN AA18 [get_ports {hi_in[7]}]

set_property SLEW FAST [get_ports {hi_in[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hi_in[*]}]

set_property PACKAGE_PIN Y21 [get_ports {hi_out[0]}]
set_property PACKAGE_PIN U20 [get_ports {hi_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hi_out[*]}]

set_property PACKAGE_PIN AB22 [get_ports {hi_inout[0]}]
set_property PACKAGE_PIN AB21 [get_ports {hi_inout[1]}]
set_property PACKAGE_PIN Y22  [get_ports {hi_inout[2]}]
set_property PACKAGE_PIN AA21 [get_ports {hi_inout[3]}]
set_property PACKAGE_PIN AA20 [get_ports {hi_inout[4]}]
set_property PACKAGE_PIN W22  [get_ports {hi_inout[5]}]
set_property PACKAGE_PIN W21  [get_ports {hi_inout[6]}]
set_property PACKAGE_PIN T20  [get_ports {hi_inout[7]}]
set_property PACKAGE_PIN R19  [get_ports {hi_inout[8]}]
set_property PACKAGE_PIN P19  [get_ports {hi_inout[9]}]
set_property PACKAGE_PIN U21  [get_ports {hi_inout[10]}]
set_property PACKAGE_PIN T21  [get_ports {hi_inout[11]}]
set_property PACKAGE_PIN R21  [get_ports {hi_inout[12]}]
set_property PACKAGE_PIN P21  [get_ports {hi_inout[13]}]
set_property PACKAGE_PIN R22  [get_ports {hi_inout[14]}]
set_property PACKAGE_PIN P22  [get_ports {hi_inout[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hi_inout[*]}]

set_property PACKAGE_PIN V22 [get_ports {hi_aa}]
set_property IOSTANDARD LVCMOS33 [get_ports {hi_aa}]


create_clock -name okHostClk -period 20.83 [get_ports {hi_in[0]}]

set_input_delay -add_delay -max -clock [get_clocks {okHostClk}]  11.000 [get_ports {hi_inout[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okHostClk}]  0.000  [get_ports {hi_inout[*]}]
set_multicycle_path -setup -from [get_ports {hi_inout[*]}] 2

set_input_delay -add_delay -max -clock [get_clocks {okHostClk}]  6.700 [get_ports {hi_in[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okHostClk}]  0.000 [get_ports {hi_in[*]}]
set_multicycle_path -setup -from [get_ports {hi_in[*]}] 2

set_output_delay -add_delay -clock [get_clocks {okHostClk}]  8.900 [get_ports {hi_out[*]}]

set_output_delay -add_delay -clock [get_clocks {okHostClk}]  9.200 [get_ports {hi_inout[*]}]

############################################################################
## System Clock
############################################################################
set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p}]
set_property PACKAGE_PIN K4 [get_ports {sys_clk_p}]

set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_n}]
set_property PACKAGE_PIN J4 [get_ports {sys_clk_n}]

# MC1-52 
set_property PACKAGE_PIN F1 [get_ports {pix_lv}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_lv}]

# MC1-54 
set_property PACKAGE_PIN F3 [get_ports {pix_fv}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_fv}]

# MC1-58 
set_property PACKAGE_PIN E3 [get_ports {pix_strobe}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_strobe}]

# MC1-60 
set_property PACKAGE_PIN C2 [get_ports {pix_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[11]}]

# MC1-62 
set_property PACKAGE_PIN B2 [get_ports {pix_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[10]}]

# MC1-63 
set_property PACKAGE_PIN E13 [get_ports {pix_sdata}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_sdata}]

# MC1-64 
set_property PACKAGE_PIN F13 [get_ports {pix_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[9]}]

# MC1-65 
set_property PACKAGE_PIN E14 [get_ports {pix_sclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_sclk}]

# MC1-66 
set_property PACKAGE_PIN F14 [get_ports {pix_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[8]}]

# MC1-67 
set_property PACKAGE_PIN C14 [get_ports {pix_trigger}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_trigger}]

# MC1-68 
set_property PACKAGE_PIN D14 [get_ports {pix_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[7]}]

# MC1-69 
set_property PACKAGE_PIN C15 [get_ports {pix_reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_reset}]

# MC1-70 
set_property PACKAGE_PIN D15 [get_ports {pix_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[6]}]

# MC1-71 
set_property PACKAGE_PIN B15 [get_ports {pix_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[2]}]

# MC1-72 
set_property PACKAGE_PIN F16 [get_ports {pix_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[5]}]

# MC1-73 
set_property PACKAGE_PIN B16 [get_ports {pix_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[1]}]

# MC1-74 
set_property PACKAGE_PIN E17 [get_ports {pix_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[4]}]

# MC1-75 
set_property PACKAGE_PIN E16 [get_ports {pix_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[0]}]

# MC1-76 
set_property PACKAGE_PIN D16 [get_ports {pix_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_data[3]}]

# MC1-77 
set_property PACKAGE_PIN H4 [get_ports {pix_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_clk}]

# MC1-79 
set_property PACKAGE_PIN G4 [get_ports {pix_extclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {pix_extclk}]

create_clock -name {pixclk} -period 13.800 -waveform { 0.000 6.900 } [get_ports {pix_clk}]
create_clock -name {virt_pixclk} -period 13.800 -waveform { 0.000 6.900 } 

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

set_input_delay -add_delay -max -clock [get_clocks {virt_pixclk}] -clock_fall   10.8 [get_ports {pix_data[*]}]
set_input_delay -add_delay -min -clock [get_clocks {virt_pixclk}] -clock_fall    6.1 [get_ports {pix_data[*]}]

set_multicycle_path -setup -from [get_ports {pix_data[*]}] 2
set_multicycle_path -setup -from [get_ports {pix_lv}] 2
set_multicycle_path -setup -from [get_ports {pix_fv}] 2


# LEDs #####################################################################
set_property PACKAGE_PIN N13 [get_ports {led[0]}]
set_property PACKAGE_PIN N14 [get_ports {led[1]}]
set_property PACKAGE_PIN P15 [get_ports {led[2]}]
set_property PACKAGE_PIN P16 [get_ports {led[3]}]
set_property PACKAGE_PIN N17 [get_ports {led[4]}]
set_property PACKAGE_PIN P17 [get_ports {led[5]}]
set_property PACKAGE_PIN R16 [get_ports {led[6]}]
set_property PACKAGE_PIN R17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# DRAM #####################################################################
#set_property PACKAGE_PIN AB1 [get_ports {ddr3_dq[0]}]
#set_property PACKAGE_PIN Y4  [get_ports {ddr3_dq[1]}]
#set_property PACKAGE_PIN AB2 [get_ports {ddr3_dq[2]}]
#set_property PACKAGE_PIN V4  [get_ports {ddr3_dq[3]}]
#set_property PACKAGE_PIN AB5 [get_ports {ddr3_dq[4]}]
#set_property PACKAGE_PIN AA5 [get_ports {ddr3_dq[5]}]
#set_property PACKAGE_PIN AB3 [get_ports {ddr3_dq[6]}]
#set_property PACKAGE_PIN AA4 [get_ports {ddr3_dq[7]}]
#set_property PACKAGE_PIN U3  [get_ports {ddr3_dq[8]}]
#set_property PACKAGE_PIN W2  [get_ports {ddr3_dq[9]}]
#set_property PACKAGE_PIN U2  [get_ports {ddr3_dq[10]}]
#set_property PACKAGE_PIN Y2  [get_ports {ddr3_dq[11]}]
#set_property PACKAGE_PIN U1  [get_ports {ddr3_dq[12]}]
#set_property PACKAGE_PIN Y1  [get_ports {ddr3_dq[13]}]
#set_property PACKAGE_PIN T1  [get_ports {ddr3_dq[14]}]
#set_property PACKAGE_PIN W1  [get_ports {ddr3_dq[15]}]
#set_property SLEW FAST [get_ports {ddr3_dq[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dq[*]}]
#
#set_property PACKAGE_PIN W6  [get_ports {ddr3_addr[0]}]
#set_property PACKAGE_PIN U7  [get_ports {ddr3_addr[1]}]
#set_property PACKAGE_PIN W7  [get_ports {ddr3_addr[2]}]
#set_property PACKAGE_PIN Y6  [get_ports {ddr3_addr[3]}]
#set_property PACKAGE_PIN U6  [get_ports {ddr3_addr[4]}]
#set_property PACKAGE_PIN AB7 [get_ports {ddr3_addr[5]}]
#set_property PACKAGE_PIN Y8  [get_ports {ddr3_addr[6]}]
#set_property PACKAGE_PIN AB8 [get_ports {ddr3_addr[7]}]
#set_property PACKAGE_PIN Y7  [get_ports {ddr3_addr[8]}]
#set_property PACKAGE_PIN AA8 [get_ports {ddr3_addr[9]}]
#set_property PACKAGE_PIN T4  [get_ports {ddr3_addr[10]}]
#set_property PACKAGE_PIN V7  [get_ports {ddr3_addr[11]}]
#set_property PACKAGE_PIN T6  [get_ports {ddr3_addr[12]}]
#set_property PACKAGE_PIN Y9  [get_ports {ddr3_addr[13]}]
#set_property PACKAGE_PIN W9  [get_ports {ddr3_addr[14]}]
#set_property SLEW FAST [get_ports {ddr3_addr[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_addr[*]}]
#
#set_property PACKAGE_PIN AB6 [get_ports {ddr3_ba[0]}]
#set_property PACKAGE_PIN R6  [get_ports {ddr3_ba[1]}]
#set_property PACKAGE_PIN AA6 [get_ports {ddr3_ba[2]}]
#set_property SLEW FAST [get_ports {ddr3_ba[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ba[*]}]
#
#set_property PACKAGE_PIN V5 [get_ports {ddr3_ras_n}]
#set_property SLEW FAST [get_ports {ddr3_ras_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_ras_n}]
#
#set_property PACKAGE_PIN U5 [get_ports {ddr3_cas_n}]
#set_property SLEW FAST [get_ports {ddr3_cas_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cas_n}]
#
#set_property PACKAGE_PIN T5 [get_ports {ddr3_we_n}]
#set_property SLEW FAST [get_ports {ddr3_we_n}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_we_n}]
#
#set_property PACKAGE_PIN T3 [get_ports {ddr3_reset_n}]
#set_property SLEW FAST [get_ports {ddr3_reset_n}]
#set_property IOSTANDARD LVCMOS15 [get_ports {ddr3_reset_n}]
#
#set_property PACKAGE_PIN R4 [get_ports {ddr3_cke}]
#set_property SLEW FAST [get_ports {ddr3_cke}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_cke}]
#
#set_property PACKAGE_PIN W5 [get_ports {ddr3_odt[0]}]
#set_property SLEW FAST [get_ports {ddr3_odt[0]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_odt[0]}]
#
#set_property PACKAGE_PIN AA1 [get_ports {ddr3_dm[0]}]
#set_property PACKAGE_PIN V2  [get_ports {ddr3_dm[1]}]
#set_property SLEW FAST [get_ports {ddr3_dm[*]}]
#set_property IOSTANDARD SSTL15 [get_ports {ddr3_dm[*]}]
#
#set_property PACKAGE_PIN Y3  [get_ports {ddr3_dqs_p[0]}]
#set_property PACKAGE_PIN AA3 [get_ports {ddr3_dqs_n[0]}]
#set_property PACKAGE_PIN R3  [get_ports {ddr3_dqs_p[1]}]
#set_property PACKAGE_PIN R2  [get_ports {ddr3_dqs_n[1]}]
#set_property SLEW FAST [get_ports {ddr3_dqs*}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_dqs*}]
#
#set_property PACKAGE_PIN V9 [get_ports {ddr3_ck_p[0]}]
#set_property PACKAGE_PIN V8 [get_ports {ddr3_ck_n[0]}]
#set_property SLEW FAST [get_ports {ddr3_ck*}]
#set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddr3_ck_*}]
#

#**************************************************************
# Asyncronous Clocks
#**************************************************************
set_clock_groups -name async-pixclk-clk_pll -asynchronous -group  {clk_pix_bufg_in virt_pixclk}  -group {clk_pll_i sys_clk_p} -group {okUH0 mmcm0_clk0}
