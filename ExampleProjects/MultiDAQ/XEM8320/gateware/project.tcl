#----------------------------------------------------------------------
# Assisting script for the FFT Signal Generator sample that creates the Vivado project,
# configures the required IP Cores, and calls the IPI Block Design creation script.
#
# Vivado version used to generate these commands:
# Vivado v2023.2 (64-bit)
# To run:
# 1. Copy project files into a working directory.
# 2. Open Vivado GUI and "cd" to this folder in the working directory 
#    using the TCL console.
# 3. Before proceeding, ensure the 'fpdir' variable is set using the 
#    following command in the TCL console:
#    'set fpdir <dir>'
#    This variable should indicate the directory of the FrontPanel 
#    Vivado IP Core (at least version 1.0 Rev 4).
#    If the IP Core isn't installed, gather more information at:
#    https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/
#    If 'fpdir' isn't set, the script will return an error.
# 4. Run "source project.tcl"
################################################################

if {![info exists fpdir]} {
    puts "\nError: You must set the 'fpdir' variable before running this script."
    puts "Use the command: 'set fpdir <dir>'"
    puts "This variable should point to the FrontPanel Vivado IP Core."
    puts "If it's not installed, learn more at:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/"
    return
}

create_project multidaq_ex Vivado -part xcau25p-ffvb676-2-e
start_gui

set ip_paths {}
lappend ip_paths \
[get_property $fpdir [current_fileset]] \
$fpdir

set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog -rebuild

add_files -norecurse { ./adc_controller.sv ./dac_controller.v ./dac_cordic.v \
./top.v sync_bus.v sync_reset.v}
add_files -fileset constrs_1 -norecurse ./xem8320.xdc

add_files -norecurse -scan_for_includes ./sim.v
update_compile_order -fileset sources_1
set_property used_in_synthesis false [get_files ./sim.v]
set_property used_in_implementation false [get_files ./sim.v]
update_compile_order -fileset sources_1

create_ip -name frontpanel -vendor opalkelly.com -library ip -version 1.0 -module_name frontpanel_0
set_property -dict [list \
CONFIG.BOARD {XEM8320-AU25P} \
CONFIG.WI.COUNT {9} \
CONFIG.WI.ADDR_0 {0x00} \
CONFIG.WI.ADDR_1 {0x01} \
CONFIG.WI.ADDR_2 {0x02} \
CONFIG.WI.ADDR_3 {0x03} \
CONFIG.WI.ADDR_4 {0x04} \
CONFIG.WI.ADDR_5 {0x05} \
CONFIG.WI.ADDR_6 {0x06} \
CONFIG.WI.ADDR_7 {0x07} \
CONFIG.WI.ADDR_8 {0x08} \
CONFIG.WO.COUNT {1} \
CONFIG.WO.ADDR_0 {0x28} \
CONFIG.PO.COUNT {1} \
CONFIG.PO.ADDR_0 {0xa0} \
] [get_ips frontpanel_0]

create_ip -name cordic -vendor xilinx.com -library ip -version 6.0 -module_name cordic_0
set_property -dict [list \
CONFIG.Functional_Selection {Sin_and_Cos} \
CONFIG.Phase_Format {Scaled_Radians} \
CONFIG.Input_Width {32} \
CONFIG.Output_Width {16} \
CONFIG.Round_Mode {Nearest_Even} \
CONFIG.Data_Format {SignedFraction} \
] [get_ips cordic_0]

generate_target {instantiation_template} [get_files Vivado/multidaq_ex.srcs/sources_1/ip/cordic_0/cordic_0.xci]
update_compile_order -fileset sources_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [list \
  CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} \
  CONFIG.Full_Threshold_Assert_Value {8199} \
  CONFIG.Input_Data_Width {32} \
  CONFIG.Input_Depth {16384} \
  CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
  CONFIG.Read_Clock_Frequency {101} \
  CONFIG.Write_Clock_Frequency {17} \
] [get_ips fifo_generator_0]
generate_target {instantiation_template} [get_files ./Vivado/multidaq_ex.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name adc_serial_clk
set_property -dict [list \
  CONFIG.CLKOUT1_DRIVES {Buffer} \
  CONFIG.CLKOUT1_JITTER {195.643} \
  CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {14.28571} \
  CONFIG.CLKOUT2_DRIVES {Buffer} \
  CONFIG.CLKOUT2_JITTER {173.642} \
  CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {26.31579} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_DRIVES {Buffer} \
  CONFIG.CLKOUT4_DRIVES {Buffer} \
  CONFIG.CLKOUT5_DRIVES {Buffer} \
  CONFIG.CLKOUT6_DRIVES {Buffer} \
  CONFIG.CLKOUT7_DRIVES {Buffer} \
  CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {10} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {70} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {38} \
  CONFIG.MMCM_COMPENSATION {AUTO} \
  CONFIG.NUM_OUT_CLKS {2} \
  CONFIG.PRIMITIVE {PLL} \
] [get_ips adc_serial_clk]
generate_target {instantiation_template} [get_files Vivado/multidaq_ex.srcs/sources_1/ip/adc_serial_clk/adc_serial_clk.xci]
