#----------------------------------------------------------------------
# Assisting script for the FFT Signal Generator sample that creates the Vivado project,
# configures the required IP Cores, and calls the IPI Block Design creation script.
#
# Vivado version used to generate these commands:
# Vivado v2021.2 (64-bit)
#--------------------------------------------------------------------
set ip_paths {}
lappend ip_paths \
[list [lindex $argv 0]] \
[list ./fft/vitis/solution1/impl/ip] \
[list ./ifft/vitis/solution1/impl/ip]

start_gui
create_project dac_adc_example ./Vivado -part xcau25p-ffvb676-2-e
set_property board_part opalkelly.com:xem8320-au25p:part0:1.2 [current_project]
set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog
update_compile_order -fileset sources_1
add_files -norecurse {../HDL/dac/syzygy-dac-controller.v ../HDL/dac/syzygy-dac-phy.v ../HDL/dac/syzygy-dac-top.v \
../HDL/dac/syzygy-dac-spi.v ../HDL/fp_slicer.v ../HDL/dac/ifft_controller.v ../HDL/dac/syzygy_dac_data_reg.v \
../HDL/adc/bitslip_detect.v ../HDL/adc/bitslip_shift.v ../HDL/adc/fft_controller.v ../HDL/adc/syzygy-adc-12-dco.v \
../HDL/adc/syzygy-adc-enc.v ../HDL/adc/syzygy-adc-frame.v ../HDL/adc/syzygy-adc-phy.v ../HDL/adc/syzygy-adc-top.v ../HDL/adc/xem8320_adc.v}

add_files -fileset constrs_1 -norecurse ../HDL/xem8320-adc-12.xdc

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../HDL/testbench.sv ../HDL/testbench.wcfg
set_property top ifft_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0
set_property -dict [list \
  CONFIG.Enable_32bit_Address {false} \
  CONFIG.Memory_Type {True_Dual_Port_RAM} \
  CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
  CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
  CONFIG.Use_RSTA_Pin {true} \
  CONFIG.Use_RSTB_Pin {true} \
  CONFIG.Write_Depth_A {2048} \
  CONFIG.Write_Width_A {32} \
  CONFIG.Write_Width_B {64} \
] [get_ips blk_mem_gen_0]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name blk_mem_gen_1
set_property -dict [list \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
  CONFIG.Use_RSTA_Pin {true} \
  CONFIG.Write_Depth_A {1024} \
  CONFIG.Write_Width_A {12} \
] [get_ips blk_mem_gen_1]

update_compile_order -fileset sources_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [\
list CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.Input_Data_Width {32} \
CONFIG.Input_Depth {4096} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {4096} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
CONFIG.Full_Threshold_Assert_Value {1024} \
CONFIG.Full_Threshold_Negate_Value {1023} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_generator_0]
generate_target {instantiation_template} [get_files Vivado/adc_dac_tester.srcs/sources_1/ip/fifo_generator_0/fifo_generator_0.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_1
set_property -dict [list \
  CONFIG.Component_Name {fifo_generator_1} \
  CONFIG.Empty_Threshold_Assert_Value {1018} \
  CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} \
  CONFIG.Input_Data_Width {32} \
  CONFIG.Input_Depth {2048} \
  CONFIG.Output_Data_Width {16} \
  CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} \
  CONFIG.Read_Clock_Frequency {40} \
  CONFIG.Write_Clock_Frequency {100} \
  CONFIG.asymmetric_port_width {true} \
] [get_ips fifo_generator_1]
generate_target {instantiation_template} [get_files Vivado/adc_dac_tester.srcs/sources_1/ip/fifo_generator_1/fifo_generator_1.xci]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_2
set_property -dict [list \
  CONFIG.Component_Name {fifo_generator_2} \
  CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} \
  CONFIG.Full_Threshold_Assert_Value {1024} \
  CONFIG.Input_Data_Width {64} \
  CONFIG.Input_Depth {2048} \
  CONFIG.Output_Data_Width {32} \
  CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
  CONFIG.Read_Clock_Frequency {100} \
  CONFIG.Write_Clock_Frequency {40} \
  CONFIG.asymmetric_port_width {true} \
] [get_ips fifo_generator_2]
generate_target {instantiation_template} [get_files Vivado/adc_dac_tester.srcs/sources_1/ip/fifo_generator_2/fifo_generator_2.xci]

update_compile_order -fileset sources_1

source block_design_vivado.tcl
