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
# 2. Run "source project-adc14.tcl"
# 3. Import FrontPanel HDL for your product into the project. These
#    sources are located within the FrontPanel SDK installation.
# 4. Generate Bitstream.
#--------------------------------------------------------------------
start_gui
create_project SZG-ADC Vivado -part xcau25p-ffvb676-2-e
add_files -norecurse {\
gateware/syzygy-adc-frame.v \
gateware/syzygy-adc-dco.v \
gateware/xem8320_adc.v \
gateware/bitslip_detect.v \
gateware/bitslip_shift.v \
gateware/syzygy-adc-enc.v \
gateware/syzygy-adc-phy.v \
gateware/syzygy-adc-top.v}
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse gateware/xem8320.xdc
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [\
list CONFIG.PRIM_SOURCE {Global_buffer}\
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {300} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.000} \
CONFIG.MMCM_CLKOUT1_DIVIDE {30} \
CONFIG.NUM_OUT_CLKS {2} \
CONFIG.CLKOUT1_JITTER {94.862} \
CONFIG.CLKOUT2_JITTER {139.033} \
CONFIG.CLKOUT2_PHASE_ERROR {87.180}] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files Vivado/SZG-ADC.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
update_compile_order -fileset sources_1
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [\
list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.Input_Data_Width {32} \
CONFIG.Input_Depth {2048} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {2048} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Data_Count_Width {11} \
CONFIG.Write_Data_Count_Width {11} \
CONFIG.Read_Data_Count_Width {11} \
CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
CONFIG.Full_Threshold_Assert_Value {2044} \
CONFIG.Full_Threshold_Negate_Value {2043} \
CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_generator_0]
generate_target {instantiation_template} [get_files Vivado/SZG-ADC.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]
update_compile_order -fileset sources_1
