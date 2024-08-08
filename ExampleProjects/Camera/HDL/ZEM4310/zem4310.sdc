############################################################################
# ZEM4310 - Quartus Constraints File
#
# Timing constraints for the ZEM4310.
#
# Copyright (c) 2004-2010 Opal Kelly Incorporated
# $Rev: 584 $ $Date: 2010-10-01 11:14:42 -0500 (Fri, 01 Oct 2010) $
############################################################################


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clocks
#**************************************************************

create_clock -name {sysclk} -period 20.000 -waveform { 0.000 10.00 } [get_ports {sys_clk}]

create_clock -name {pixclk} -period 13.800 -waveform { 0.000 6.900 } [get_ports {pix_clk}]
create_clock -name {virt_pixclk} -period 13.800 -waveform { 0.000 6.900 } 

derive_pll_clocks


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

#**************************************************************
# False Paths
#**************************************************************
set_false_path -from [get_ports {pix_fv}] -to [get_registers {image_if:imgif0|regm_fv}]

#**************************************************************
# Asyncronous Clocks
#**************************************************************
set_clock_groups -asynchronous -group  [get_clocks {okHI|ok_altpll0|altpll_component|auto_generated|pll1|clk[0]}]  -group [get_clocks {memif0|ddr2_interface_inst|ddr2_interface_controller_phy_inst|ddr2_interface_phy_inst|ddr2_interface_phy_alt_mem_phy_inst|clk|pll|altpll_component|auto_generated|pll1|clk[0]}]
set_clock_groups -asynchronous -group  [get_clocks {okHI|ok_altpll0|altpll_component|auto_generated|pll1|clk[0]}]  -group [get_clocks {clkinst0|pixclkpll0|altpll_component|auto_generated|pll1|clk[0]}]
set_clock_groups -asynchronous -group  [get_clocks {clkinst0|pixclkpll0|altpll_component|auto_generated|pll1|clk[0]}]  -group [get_clocks {memif0|ddr2_interface_inst|ddr2_interface_controller_phy_inst|ddr2_interface_phy_inst|ddr2_interface_phy_alt_mem_phy_inst|clk|pll|altpll_component|auto_generated|pll1|clk[0]}]



