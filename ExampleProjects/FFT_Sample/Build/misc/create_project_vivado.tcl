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
[list ./vitis/solution1/impl/ip]

start_gui
create_project ifft_ex ./Vivado -part xcau25p-ffvb676-2-e
set_property board_part opalkelly.com:xem8320-au25p:part0:1.2 [current_project]
set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog
update_compile_order -fileset sources_1
add_files -norecurse {../HDL/syzygy-dac-controller.v ../HDL/syzygy-dac-phy.v ../HDL/syzygy-dac-top.v \
../HDL/syzygy-dac-spi.v ../HDL/fp_slicer.v ../HDL/ifft_controller.v ../HDL/syzygy_dac_data_reg.v}
add_files -fileset constrs_1 -norecurse ../HDL/xem8320.xdc
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../HDL/ifft_tb.v ../HDL/ifft_tb_behav.wcfg
set_property top ifft_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name blk_mem_gen_0
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {32} CONFIG.Write_Width_B {64} CONFIG.Read_Width_B {64} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Use_RSTA_Pin {true} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100} CONFIG.EN_SAFETY_CKT {true}] [get_ips blk_mem_gen_0]
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name blk_mem_gen_1
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {12} CONFIG.Write_Depth_A {256} CONFIG.Read_Width_A {12} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {12} CONFIG.Read_Width_B {12} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.EN_SAFETY_CKT {true}] [get_ips blk_mem_gen_1]
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {125} CONFIG.USE_FREQ_SYNTH {false} CONFIG.USE_PHASE_ALIGNMENT {true} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.CLKOUT1_REQUESTED_PHASE {90} CONFIG.CLKOUT1_DRIVES {BUFG} CONFIG.PHASESHIFT_MODE {WAVEFORM} CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} CONFIG.CLKOUT2_DRIVES {Buffer} CONFIG.CLKOUT3_DRIVES {Buffer} CONFIG.CLKOUT4_DRIVES {Buffer} CONFIG.CLKOUT5_DRIVES {Buffer} CONFIG.CLKOUT6_DRIVES {Buffer} CONFIG.CLKOUT7_DRIVES {Buffer} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.MMCM_CLKOUT0_PHASE {90.000}] [get_ips clk_wiz_0]
update_compile_order -fileset sources_1

source misc/block_design_vivado.tcl
