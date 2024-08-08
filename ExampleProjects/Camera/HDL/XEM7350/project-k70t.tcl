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
create_project Camera_7350 Vivado-k70t-2021 -part xc7k70tfbg676-1
add_files {\
MIG/phy/mig_7series_v2_0_ddr_phy_4lanes.v \
MIG/phy/mig_7series_v2_0_ddr_phy_prbs_rdlvl.v \
MIG/controller/mig_7series_v2_0_mc.v \
MIG/phy/mig_7series_v2_0_ddr_calib_top.v \
MIG/phy/mig_7series_v2_0_ddr_phy_dqs_found_cal.v \
MIG/ecc/mig_7series_v2_0_ecc_merge_enc.v \
MIG/ecc/mig_7series_v2_0_ecc_dec_fix.v \
MIG/phy/mig_7series_v2_0_ddr_phy_wrlvl.v \
MIG/phy/mig_7series_v2_0_ddr_phy_rdlvl.v \
MIG/phy/mig_7series_v2_0_ddr_phy_top.v \
MIG/clocking/mig_7series_v2_0_tempmon.v \
MIG/phy/mig_7series_v2_0_ddr_if_post_fifo.v \
MIG/ecc/mig_7series_v2_0_ecc_buf.v \
MIG/ip_top/mig_7series_v2_0_memc_ui_top_std.v \
MIG/ui/mig_7series_v2_0_ui_top.v \
MIG/clocking/mig_7series_v2_0_clk_ibuf.v \
MIG/controller/mig_7series_v2_0_rank_mach.v \
MIG/controller/mig_7series_v2_0_col_mach.v \
MIG/phy/mig_7series_v2_0_ddr_prbs_gen.v \
MIG/ui/mig_7series_v2_0_ui_rd_data.v \
MIG/controller/mig_7series_v2_0_arb_select.v \
MIG/controller/mig_7series_v2_0_bank_compare.v \
MIG/ecc/mig_7series_v2_0_fi_xor.v \
MIG/controller/mig_7series_v2_0_rank_cntrl.v \
MIG/phy/mig_7series_v2_0_ddr_of_pre_fifo.v \
MIG/controller/mig_7series_v2_0_bank_cntrl.v \
MIG/phy/mig_7series_v2_0_ddr_phy_tempmon.v \
MIG/controller/mig_7series_v2_0_bank_queue.v \
MIG/ui/mig_7series_v2_0_ui_wr_data.v \
MIG/ui/mig_7series_v2_0_ui_cmd.v \
MIG/controller/mig_7series_v2_0_round_robin_arb.v \
MIG/phy/mig_7series_v2_0_ddr_byte_lane.v \
MIG/ip_top/mig_7series_v2_0_mem_intfc.v \
MIG/phy/mig_7series_v2_0_ddr_mc_phy.v \
MIG/controller/mig_7series_v2_0_bank_common.v \
MIG/phy/mig_7series_v2_0_ddr_phy_init.v \
MIG/phy/mig_7series_v2_0_ddr_phy_wrcal.v \
MIG/controller/mig_7series_v2_0_bank_mach.v \
MIG/phy/mig_7series_v2_0_ddr_phy_ck_addr_cmd_delay.v \
MIG/phy/mig_7series_v2_0_ddr_phy_wrlvl_off_delay.v \
MIG/phy/mig_7series_v2_0_ddr_mc_phy_wrapper.v \
MIG/phy/mig_7series_v2_0_ddr_byte_group_io.v \
MIG/controller/mig_7series_v2_0_bank_state.v \
MIG/clocking/mig_7series_v2_0_iodelay_ctrl.v \
MIG/ecc/mig_7series_v2_0_ecc_gen.v \
MIG/controller/mig_7series_v2_0_arb_row_col.v \
MIG/controller/mig_7series_v2_0_rank_common.v \
MIG/phy/mig_7series_v2_0_ddr_phy_dqs_found_cal_hr.v \
MIG/phy/mig_7series_v2_0_ddr_phy_oclkdelay_cal.v \
MIG/controller/mig_7series_v2_0_arb_mux.v}
add_files -norecurse {\
host_if.v \
mem_arbiter.v \
image_if.v \
okcamera.v \
clocks.v \
memif.v \
../imgbuf_coordinator.v \
../sync_bus.v \
../sync_reset.v \
../sync_trig.v \
Core/i2cController.ngc}
update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse {xem7350-k70t.xdc}

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w128_512_r32_2048
set_property -dict [list \
CONFIG.Component_Name {fifo_w128_512_r32_2048} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.Input_Data_Width {128} \
CONFIG.Input_Depth {512} \
CONFIG.Output_Data_Width {32} \
CONFIG.Output_Depth {2048} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
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
