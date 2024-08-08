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
create_project Camera_7010 Vivado-a200t-2021 -part xc7a200tfbg484-1
add_files -norecurse {\
host_if.v \
mem_arbiter.v \
image_if.v \
okcamera.v \
clocks.v \
../imgbuf_coordinator.v \
../sync_bus.v \
../sync_reset.v \
../sync_trig.v \
Core/i2cController.ngc}
update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse {xem7010.xdc}

create_ip -name mig_7series -vendor xilinx.com -library ip -module_name ddr3_256_16
set_property -dict [list CONFIG.XML_INPUT_FILE {../../../../../mig_a200t.prj}] [get_ips ddr3_256_16]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w128_512_r16_4096
set_property -dict [list \
CONFIG.Component_Name {fifo_w128_512_r16_4096} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.Input_Data_Width {128} \
CONFIG.Input_Depth {512} \
CONFIG.Output_Data_Width {16} \
CONFIG.Output_Depth {4096} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Valid_Flag {true} \
CONFIG.Underflow_Flag {true} \
CONFIG.Data_Count_Width {9} \
CONFIG.Write_Data_Count {true} \
CONFIG.Write_Data_Count_Width {9} \
CONFIG.Read_Data_Count {true} \
CONFIG.Read_Data_Count_Width {12} \
CONFIG.Full_Threshold_Assert_Value {509} \
CONFIG.Full_Threshold_Negate_Value {508} \
CONFIG.Enable_Safety_Circuit {true}\
] [get_ips fifo_w128_512_r16_4096]
update_compile_order -fileset sources_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w64_1024_r128_512
set_property -dict [list \
CONFIG.Component_Name {fifo_w64_1024_r128_512} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.Input_Data_Width {64} \
CONFIG.Input_Depth {1024} \
CONFIG.Output_Data_Width {128} \
CONFIG.Output_Depth {512} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Valid_Flag {true} \
CONFIG.Data_Count_Width {10} \
CONFIG.Write_Data_Count {true} \
CONFIG.Write_Data_Count_Width {10} \
CONFIG.Read_Data_Count {true} \
CONFIG.Read_Data_Count_Width {9} \
CONFIG.Full_Threshold_Assert_Value {1021} \
CONFIG.Full_Threshold_Negate_Value {1020} \
CONFIG.Enable_Safety_Circuit {true}\
] [get_ips fifo_w64_1024_r128_512]
update_compile_order -fileset sources_1

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
update_compile_order -fileset sources_1

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name mig_pix_clkgen
set_property -dict [list \
CONFIG.PRIMITIVE {PLL} \
CONFIG.USE_PHASE_ALIGNMENT {false} \
CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
CONFIG.PRIM_IN_FREQ {200.000} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {20.000}] \
[get_ips mig_pix_clkgen]
