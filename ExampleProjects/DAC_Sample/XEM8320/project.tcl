#----------------------------------------------------------------------
# project.tcl will work with earlier, and later, Vivado versions then 
# the following Vivado version used to generate these commands:
# Vivado v2021.2 (64-bit)
# SW Build 3367213 on Tue Oct 19 02:48:09 MDT 2021
# IP Build 3369179 on Thu Oct 21 08:25:16 MDT 2021
# 
# To run:
# 1. Open Vivado GUI and "cd" to this directory containing project.tcl
#    using the TCL console.
# 2. Run "source project.tcl"
# 3. Import FrontPanel HDL for your product into the project. These
#    sources are located within the FrontPanel SDK installation.
# 4. Generate Bitstream.
#--------------------------------------------------------------------
start_gui
create_project SignalGenerator Vivado -part xcau25p-ffvb676-2-e
add_files {\
gateware/signal-gen-top.v \
gateware/szg-pmod-i2s2/szg-i2s2-pmod-phy.v \
gateware/szg-pmod-i2s2/szg-i2s2-pmod-top.v \
gateware/szg-dac/syzygy-dds-fp.v \
gateware/szg-dac/syzygy-dac-am.v \
gateware/szg-dac/syzygy-dac-phy.v \
gateware/szg-dac/syzygy-dac-fm.v \
gateware/szg-dac/syzygy-dac-top.v \
gateware/szg-dac/syzygy-dac-controller.v \
gateware/szg-dac/syzygy-dac-spi.v}
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse gateware/xem8320.xdc
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list CONFIG.USE_FREQ_SYNTH {false} CONFIG.USE_PHASE_ALIGNMENT {true} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.PRIM_IN_FREQ {100.8} CONFIG.CLKOUT1_REQUESTED_PHASE {90} CONFIG.CLKOUT1_DRIVES {BUFG} CONFIG.PHASESHIFT_MODE {WAVEFORM} CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} CONFIG.CLKIN1_JITTER_PS {99.2} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT7_REQUESTED_OUT_FREQ {100.8} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} CONFIG.MMCM_CLKIN1_PERIOD {9.921} CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} CONFIG.MMCM_CLKOUT0_PHASE {90.000} CONFIG.CLKOUT1_JITTER {114.875} CONFIG.CLKOUT1_PHASE_ERROR {86.652}] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files Vivado/SignalGenerator.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
update_compile_order -fileset sources_1
create_ip -name cordic -vendor xilinx.com -library ip -version 6.0 -module_name cordic_0
set_property -dict [list CONFIG.Functional_Selection {Sin_and_Cos} CONFIG.Phase_Format {Scaled_Radians} CONFIG.Input_Width {32} CONFIG.Output_Width {12} CONFIG.Round_Mode {Nearest_Even} CONFIG.Data_Format {SignedFraction}] [get_ips cordic_0]
generate_target {instantiation_template} [get_files Vivado/SignalGenerator.srcs/sources_1/ip/cordic_0/cordic_0.xci]
update_compile_order -fileset sources_1
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [list CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {32} CONFIG.Input_Depth {16384} CONFIG.Output_Data_Width {32} CONFIG.Output_Depth {16384} CONFIG.Use_Embedded_Registers {false} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {14} CONFIG.Write_Data_Count_Width {14} CONFIG.Read_Data_Count_Width {14} CONFIG.Full_Threshold_Assert_Value {16382} CONFIG.Full_Threshold_Negate_Value {16381}] [get_ips fifo_generator_0]
generate_target {instantiation_template} [get_files Vivado/SignalGenerator.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]
update_compile_order -fileset sources_1