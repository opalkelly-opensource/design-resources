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
start_gui
create_project szg_mipi_8320_3camera Vivado -part xcau25p-ffvb676-2-e

add_files -norecurse {\
I2CController/i2cTokenizer.v \
I2CController/mux8to1.v \
I2CController/i2cController.v \
I2CController/okDRAM64X8D.v \
host_if.v \
okcamera.v \
mipi_phy.v \
imgbuf_coordinator.v \
mem_arbiter.v \
image_if.v \
image_if_wrapper.v \
../../sync_bus.v \
../../sync_trig.v \
../../sync_reset.v}

add_files -fileset constrs_1 -norecurse xem8320.xdc

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

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_w32_2048_r128_512
set_property -dict [list \
CONFIG.Component_Name {fifo_w32_2048_r128_512} \
CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
CONFIG.asymmetric_port_width {true} \
CONFIG.Input_Data_Width {32} \
CONFIG.Input_Depth {2048} \
CONFIG.Output_Data_Width {128} \
CONFIG.Output_Depth {512} \
CONFIG.Use_Embedded_Registers {false} \
CONFIG.Reset_Type {Asynchronous_Reset} \
CONFIG.Full_Flags_Reset_Value {1} \
CONFIG.Valid_Flag {true} \
CONFIG.Data_Count_Width {11} \
CONFIG.Write_Data_Count {true} \
CONFIG.Write_Data_Count_Width {11} \
CONFIG.Read_Data_Count {true} \
CONFIG.Read_Data_Count_Width {9} \
CONFIG.Full_Threshold_Assert_Value {2045} \
CONFIG.Full_Threshold_Negate_Value {2044} \
CONFIG.Enable_Safety_Circuit {true}\
] [get_ips fifo_w32_2048_r128_512]


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

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_fabric
set_property -dict [list \
CONFIG.Component_Name {clk_wiz_fabric} \
CONFIG.PRIMITIVE {PLL} \
CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
CONFIG.PRIM_SOURCE {Global_buffer} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.000} \
CONFIG.USE_RESET {false} \
CONFIG.CLKOUT1_DRIVES {Buffer} \
CONFIG.CLKOUT2_DRIVES {Buffer} \
CONFIG.CLKOUT3_DRIVES {Buffer} \
CONFIG.CLKOUT4_DRIVES {Buffer} \
CONFIG.CLKOUT5_DRIVES {Buffer} \
CONFIG.CLKOUT6_DRIVES {Buffer} \
CONFIG.CLKOUT7_DRIVES {Buffer} \
CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
CONFIG.MMCM_CLKFBOUT_MULT_F {8} \
CONFIG.MMCM_COMPENSATION {AUTO} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {4} \
CONFIG.MMCM_CLKOUT1_DIVIDE {8} \
CONFIG.NUM_OUT_CLKS {2} \
CONFIG.CLKOUT1_JITTER {126.455} \
CONFIG.CLKOUT1_PHASE_ERROR {114.212} \
CONFIG.CLKOUT2_JITTER {144.719} \
CONFIG.CLKOUT2_PHASE_ERROR {114.212}\
] [get_ips clk_wiz_fabric]


create_ip -name mipi_csi2_rx_subsystem -vendor xilinx.com -library ip -module_name mipi_csi2_cam1_master
set_property -dict [list \
CONFIG.VFB_TU_WIDTH {2} \
CONFIG.CMN_PXL_FORMAT {RAW10} \
CONFIG.CMN_NUM_LANES {2} \
CONFIG.C_DPHY_LANES {2} \
CONFIG.CMN_NUM_PIXELS {4} \
CONFIG.C_HS_LINE_RATE {420} \
CONFIG.DPY_LINE_RATE {420} \
CONFIG.HP_IO_BANK_SELECTION {66} \
CONFIG.CLK_LANE_IO_LOC {L18} \
CONFIG.DATA_LANE0_IO_LOC {M20} \
CONFIG.DATA_LANE1_IO_LOC {J19} \
CONFIG.CLK_LANE_IO_LOC_NAME {IO_L1P_T0L_N0_DBC_66} \
CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L2P_T0L_N2_66} \
CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L3P_T0L_N4_AD15P_66} \
CONFIG.SupportLevel {1} \
CONFIG.C_HS_SETTLE_NS {158} \
CONFIG.CSI_CONTROLLER_REG_IF {false} \
CONFIG.Component_Name {mipi_csi2_cam1_master}\
] [get_ips mipi_csi2_cam1_master]

create_ip -name mipi_csi2_rx_subsystem -vendor xilinx.com -library ip -module_name mipi_csi2_cam2_slave
set_property -dict [list \
CONFIG.VFB_TU_WIDTH {2} \
CONFIG.C_EN_BG0_PIN0 {false} \
CONFIG.CMN_PXL_FORMAT {RAW10} \
CONFIG.CMN_NUM_LANES {2} \
CONFIG.C_DPHY_LANES {2} \
CONFIG.CMN_NUM_PIXELS {4} \
CONFIG.C_HS_LINE_RATE {420} \
CONFIG.DPY_LINE_RATE {420} \
CONFIG.HP_IO_BANK_SELECTION {66} \
CONFIG.CLK_LANE_IO_LOC {L22} \
CONFIG.DATA_LANE0_IO_LOC {M25} \
CONFIG.DATA_LANE1_IO_LOC {K25} \
CONFIG.CLK_LANE_IO_LOC_NAME {IO_L7P_T1L_N0_QBC_AD13P_66} \
CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L8P_T1L_N2_AD5P_66} \
CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L9P_T1L_N4_AD12P_66} \
CONFIG.C_CLK_LANE_IO_POSITION {13} \
CONFIG.C_DATA_LANE0_IO_POSITION {15} \
CONFIG.C_DATA_LANE1_IO_POSITION {17} \
CONFIG.C_HS_SETTLE_NS {158} \
CONFIG.CSI_CONTROLLER_REG_IF {false} \
CONFIG.Component_Name {mipi_csi2_cam2_slave}\
] [get_ips mipi_csi2_cam2_slave]

create_ip -name mipi_csi2_rx_subsystem -vendor xilinx.com -library ip -module_name mipi_csi2_cam3_slave
set_property -dict [list \
CONFIG.VFB_TU_WIDTH {2} \
CONFIG.C_EN_BG0_PIN6 {false} \
CONFIG.CMN_PXL_FORMAT {RAW10} \
CONFIG.CMN_NUM_LANES {2} \
CONFIG.C_DPHY_LANES {2} \
CONFIG.CMN_NUM_PIXELS {4} \
CONFIG.C_HS_LINE_RATE {420} \
CONFIG.DPY_LINE_RATE {420} \
CONFIG.HP_IO_BANK_SELECTION {66} \
CONFIG.CLK_LANE_IO_LOC {L24} \
CONFIG.DATA_LANE0_IO_LOC {K22} \
CONFIG.DATA_LANE1_IO_LOC {J23} \
CONFIG.CLK_LANE_IO_LOC_NAME {IO_L10P_T1U_N6_QBC_AD4P_66} \
CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L11P_T1U_N8_GC_66} \
CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L12P_T1U_N10_GC_66} \
CONFIG.C_CLK_LANE_IO_POSITION {19} \
CONFIG.C_DATA_LANE0_IO_POSITION {21} \
CONFIG.C_DATA_LANE1_IO_POSITION {23} \
CONFIG.C_HS_SETTLE_NS {158} \
CONFIG.CSI_CONTROLLER_REG_IF {false} \
CONFIG.Component_Name {mipi_csi2_cam3_slave}\
] [get_ips mipi_csi2_cam3_slave]
