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
create_project sensor_sample Vivado -part xcau25p-ffvb676-2-e
add_files {\
gateware/i2c/okDRAM64X8D.v \
gateware/i2c/i2cTokenizer.v \
gateware/i2c/i2cController.v \
gateware/i2c/mux8to1.v \
gateware/spi/spi_control.v \
gateware/sensor.v \
gateware/uart_rx.v \
gateware/uart_tx.v}
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse gateware/xem8320.xdc
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_w8_r32
set_property -dict [list CONFIG.Component_Name {fifo_w8_r32} CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Input_Data_Width {8} CONFIG.Input_Depth {8192} CONFIG.Output_Data_Width {8} CONFIG.Output_Depth {8192} CONFIG.Use_Embedded_Registers {false} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {13} CONFIG.Write_Data_Count_Width {13} CONFIG.Read_Data_Count_Width {13} CONFIG.Full_Threshold_Assert_Value {8190} CONFIG.Full_Threshold_Negate_Value {8189}] [get_ips fifo_w8_r32]
generate_target {instantiation_template} [get_files Vivado/sensor_sample.srcs/sources_1/ip/fifo_w8_r32/fifo_w8_r32.xci]
update_compile_order -fileset sources_1
