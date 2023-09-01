#----------------------------------------------------------------------
# project.tcl will work with earlier, and later, Vivado versions then 
# the following Vivado version used to generate these commands:
# Vivado v2023.1 (64-bit)
# 
# To run:
# 1. Open Vivado GUI and "cd" to this directory containing project.tcl
#    using the TCL console.
# 2. Run "source project-ltc2264-12.tcl"
# 3. Import FrontPanel HDL for your product into the project. These
#    sources are located within the FrontPanel SDK installation.
# 4. Generate Bitstream.
#--------------------------------------------------------------------
start_gui
create_project SZG-ADC-LTC2264-12 Vivado-LTC2264-12 -part xc7a75tfgg484-1
add_files -norecurse {\
gateware/syzygy-adc-frame.v \
gateware/syzygy-adc-dco-ltc2264-12.v \
gateware/xem7320_adc.v \
gateware/syzygy-adc-enc.v \
gateware/syzygy-adc-phy.v \
gateware/syzygy-adc-top.v}
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse gateware/xem7320-ltc2264-12.xdc

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name enc_clk
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {50.0} \
  CONFIG.CLKOUT1_DRIVES {BUFG} \
  CONFIG.CLKOUT1_JITTER {135.255} \
  CONFIG.CLKOUT1_PHASE_ERROR {89.971} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {40} \
  CONFIG.CLKOUT2_DRIVES {BUFG} \
  CONFIG.CLKOUT2_JITTER {98.146} \
  CONFIG.CLKOUT2_PHASE_ERROR {89.971} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT3_DRIVES {BUFG} \
  CONFIG.CLKOUT4_DRIVES {BUFG} \
  CONFIG.CLKOUT5_DRIVES {BUFG} \
  CONFIG.CLKOUT6_DRIVES {BUFG} \
  CONFIG.CLKOUT7_DRIVES {BUFG} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} \
  CONFIG.MMCM_CLKIN1_PERIOD {5.000} \
  CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {25.000} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {5} \
  CONFIG.NUM_OUT_CLKS {2} \
  CONFIG.PRIM_IN_FREQ {200} \
  CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
  CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
  CONFIG.USE_PHASE_ALIGNMENT {false} \
] [get_ips enc_clk]

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_generator_0
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
update_compile_order -fileset sources_1
