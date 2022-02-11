#----------------------------------------------------------------------
# project.tcl will work with earlier, and later, Vivado versions then 
# the following Vivado version used to generate these commands:
# Vivado v2021.1.1 (64-bit)
# SW Build 3286242 on Wed Jul 28 13:10:47 MDT 2021
# IP Build 3279568 on Wed Jul 28 16:48:48 MDT 2021
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
create_project EthernetExampleDesign Vivado -part xcau25p-ffvb676-2-e
add_files {\
Gateware/EthernetMac_1/EthernetMac_1_basic_pat_gen.v \
Gateware/EthernetMac_1/EthernetMac_1_example_design_resets.v \
Gateware/EthernetMac_1/EthernetMac_1_syncer_level.v \
Gateware/EthernetMac_1/EthernetMac_1_example_design_clocks.v \
Gateware/EthernetMac_1/EthernetMac_1_tx_client_fifo.v \
Gateware/EthernetMac_1/EthernetMac_1_sync_block.v \
Gateware/EthernetMac_1/EthernetMac_1_ten_100_1g_eth_fifo.v \
Gateware/EthernetMac_1/EthernetMac_1_reset_sync.v \
Gateware/EthernetMac_1/EthernetMac_1_rx_client_fifo.v \
Gateware/EthernetMac_1/EthernetMac_1_axi_mux.v \
Gateware/EthernetMac_1/EthernetMac_1_axi_lite_sm.v \
Gateware/EthernetMac_1/EthernetMac_1_fifo_block.v \
Gateware/EthernetMac_1/EthernetMac_1_clk_wiz.v \
Gateware/EthernetMac_1/EthernetMac_1_bram_tdp.v \
Gateware/EthernetMac_1/EthernetMac_1_axi_pat_check.v \
Gateware/EthernetMac_1/EthernetMac_1_axi_pipe.v \
Gateware/EthernetMac_1/EthernetMac_1_example_design.v \
Gateware/EthernetMac_1/EthernetMac_1_address_swap.v \
Gateware/EthernetMac_1/EthernetMac_1_axi_pat_gen.v \
Gateware/ExtractMACAddress.v \
Gateware/FrontPanelWrapper_TriMAC.v \
Gateware/I2C/i2cController.v \
Gateware/I2C/okDRAM64X8D.v \
Gateware/I2C/mux8to1.v \
Gateware/I2C/i2cTokenizer.v}
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse Gateware/xem8320.xdc
create_ip -name tri_mode_ethernet_mac -vendor xilinx.com -library ip -version 9.0 -module_name EthernetMac_1
set_property -dict [list CONFIG.Component_Name {EthernetMac_1} CONFIG.Physical_Interface {RGMII} CONFIG.Management_Frequency {100.00} CONFIG.SupportLevel {1}] [get_ips EthernetMac_1]
generate_target {instantiation_template} [get_files Vivado/EthernetExampleDesign.srcs/sources_1/ip/EthernetMac_1/EthernetMac_1.xci]
update_compile_order -fileset sources_1
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_100Mhz
set_property -dict [list CONFIG.Component_Name {clk_wiz_100Mhz} CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} CONFIG.PRIM_SOURCE {No_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_RESET {false} CONFIG.MMCM_CLKOUT0_DIVIDE_F {6.000} CONFIG.CLKOUT1_JITTER {102.086}] [get_ips clk_wiz_100Mhz]
generate_target {instantiation_template} [get_files Vivado/EthernetExampleDesign.srcs/sources_1/ip/clk_wiz_100Mhz/clk_wiz_100Mhz.xci]
update_compile_order -fileset sources_1