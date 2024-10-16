#----------------------------------------------------------------------
# project.tcl will work with earlier, and later, Vivado versions then 
# the following Vivado version used to generate these commands:
# Vivado v2022.1 (64-bit)
# SW Build 3526262 on Mon Apr 18 15:48:16 MDT 2022
# IP Build 3524634 on Mon Apr 18 20:55:01 MDT 2022
# 
# To run:
# 1. Open Vivado GUI and "cd" to this directory containing project.tcl
#    using the TCL console.
# 2. Run "source project.tcl"
# 3. Import FrontPanel HDL for your product into the project. These
#    sources are located within the FrontPanel SDK installation.
# 4. Generate Bitstream.
#--------------------------------------------------------------------
set ip_paths {}
lappend ip_paths \
[list ./HLS/ISP/hls_component/ISPPipeline_accel/hls/impl/ip]

start_gui
create_project szg_camera_8320 Vivado -part xcau25p-ffvb676-2-e
set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog
add_files -norecurse {\
I2CController/i2cTokenizer.v \
I2CController/mux8to1.v \
I2CController/i2cController.v \
I2CController/okDRAM64X8D.v \
host_if.v \
okcamera.v \
syzygy-camera-phy.v \
imgbuf_coordinator.v \
mem_arbiter.v \
image_if.v \
../../sync_bus.v \
../../sync_trig.v \
../../sync_reset.v\
}
add_files -fileset constrs_1 -norecurse xem8320.xdc
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_fabric
set_property -dict [list \
CONFIG.Component_Name {clk_wiz_fabric} \
CONFIG.PRIMITIVE {PLL} \
CONFIG.PRIM_IN_FREQ {100.000} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {24.000} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {300.000} \
] [get_ips clk_wiz_fabric]

set_property generate_synth_checkpoint false [get_files  \
Vivado/szg_camera_8320.srcs/sources_1/ip/clk_wiz_fabric/clk_wiz_fabric.xci]

create_ip -name ddr4 -vendor xilinx.com -library ip -module_name ddr4_0
set_property -dict [list \
CONFIG.C0.DDR4_InputClockPeriod {9996} \
CONFIG.C0.DDR4_TimePeriod {833} \
CONFIG.C0.DDR4_CasLatency {17} \
CONFIG.C0.DDR4_CasWriteLatency {12} \
CONFIG.C0.DDR4_MemoryPart {MT40A512M16LY-075} \
CONFIG.C0.DDR4_DataWidth {16} \
CONFIG.C0.BANK_GROUP_WIDTH {1}\
] [get_ips ddr4_0]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w128_512_r32_2048
set_property -dict [list \
CONFIG.Component_Name {fifo_w128_512_r32_2048} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.asymmetric_port_width {true} \
CONFIG.Input_Data_Width {128} \
CONFIG.Input_Depth {512} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {2048} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {0} \
CONFIG.Valid_Flag {true} \
CONFIG.Underflow_Flag {true} \
CONFIG.Data_Count_Width {9} \
CONFIG.Write_Data_Count {true} \
CONFIG.Write_Data_Count_Width {9} \
CONFIG.Read_Data_Count {true} \
CONFIG.Read_Data_Count_Width {11} \
CONFIG.Full_Threshold_Assert_Value {509} \
CONFIG.Full_Threshold_Negate_Value {508} \
CONFIG.Enable_Safety_Circuit {true}\
] [get_ips fifo_w128_512_r32_2048]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w128_8192_r128_8192
set_property -dict [list \
CONFIG.Component_Name {fifo_w128_8192_r128_8192} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.asymmetric_port_width {false} \
CONFIG.Input_Data_Width {128} \
CONFIG.Input_Depth {8192} \
CONFIG.Output_Data_Width {128} \
CONFIG.Output_Depth {8192} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Valid_Flag {true} \
CONFIG.Data_Count_Width {13} \
CONFIG.Write_Data_Count {true} \
CONFIG.Write_Data_Count_Width {13} \
CONFIG.Read_Data_Count {true} \
CONFIG.Read_Data_Count_Width {13} \
CONFIG.Full_Threshold_Assert_Value {8189} \
CONFIG.Full_Threshold_Negate_Value {8188} \
CONFIG.Enable_Safety_Circuit {true}\
] [get_ips fifo_w128_8192_r128_8192]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name buff_addr_fifo
set_property -dict [list \
CONFIG.Component_Name {buff_addr_fifo} \
CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
CONFIG.Performance_Options {First_Word_Fall_Through} \
CONFIG.Input_Data_Width {32} \
CONFIG.Output_Data_Width {32} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Use_Extra_Logic {true} \
CONFIG.Data_Count {true} \
CONFIG.Data_Count_Width {11} \
CONFIG.Write_Data_Count_Width {11} \
CONFIG.Read_Data_Count_Width {11} \
CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Input_Port} \
CONFIG.Full_Threshold_Assert_Value {1023} \
CONFIG.Full_Threshold_Negate_Value {1022} \
CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Input_Port} \
CONFIG.Empty_Threshold_Assert_Value {4} \
CONFIG.Empty_Threshold_Negate_Value {5}\
] [get_ips buff_addr_fifo]


create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name hist_fifo
set_property -dict [list \
CONFIG.Component_Name {hist_fifo} \
CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} \
CONFIG.Performance_Options {Standard_FIFO} \
CONFIG.Input_Data_Width {32} \
CONFIG.Input_Depth {512} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {512} \
CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
CONFIG.Full_Threshold_Assert_Value {256} \
CONFIG.Read_Clock_Frequency {100} \
CONFIG.Write_Clock_Frequency {48} \
] [get_ips hist_fifo]

create_ip -name v_vid_in_axi4s -vendor xilinx.com -library ip -version 5.0 -module_name v_vid_in_axi4s_0
set_property -dict [list \
  CONFIG.C_ADDR_WIDTH {13} \
  CONFIG.C_M_AXIS_VIDEO_DATA_WIDTH {8} \
  CONFIG.C_M_AXIS_VIDEO_FORMAT {12} \
  CONFIG.C_NATIVE_COMPONENT_WIDTH {8} \
  CONFIG.C_PIXELS_PER_CLOCK {4} \
] [get_ips v_vid_in_axi4s_0]

create_ip -name ISPPipeline_accel -vendor xilinx.com -library hls -version 1.0 -module_name ISPPipeline_accel_0
