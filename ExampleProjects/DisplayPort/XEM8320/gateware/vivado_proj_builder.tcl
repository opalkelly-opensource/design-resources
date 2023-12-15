################################################################
# DisplayPort Example Design Vivado Project Builder
################################################################
# Description:
# This script creates a new project and builds the IPI block 
# design for the DisplayPort example design. The base of this design 
# comes from AMD's DisplayPort Example Design. Additionally, Opal Kelly 
# has incorporated a second video feed, which overlays on the primary 
# video feed of the AMD DisplayPort Passthrough Example Design.
# Most of this Project Builder's content originates from Vivado's Export
# feature, specifically "File->Export->Export Block Design".
#
# Note: This build script doesn't enforce a specific Vivado version or IP 
# Core version in order to maintain longevity. If you encounter issues 
# while using this script, please refer to the `tested_vivado_version` 
# variable mentioned further in the script. The tested versions of each 
# Vivado IP Core used in this design can be found in the "CHECK IPs" 
# section further below. If problems persist, our suggestion is to 
# employ the Vivado version tested for this script. In that version, the 
# Vivado IP Core versions will correspond with the ones listed in the 
# "CHECK IPs" section since Vivado IP Core versions are linked to specific
# Vivado versions.
#
# Prerequisite:
# Before building this design, ensure you have obtained the "LogiCORE, 
# DisplayPort, Evaluation License" from AMD's Product Licensing Site.
#
# To run:
# 1. Copy project files into a working directory.
# 2. Open Vivado GUI and "cd" to this folder in the working directory 
#    using the TCL console.
# 3. Before proceeding, ensure the 'fpdir' variable is set using the 
#    following command in the TCL console:
#    'set fpdir <dir>'
#    This variable should indicate the directory of the FrontPanel 
#    Vivado IP Core (at least version 1.0 Rev 4).
#    If the IP Core isn't installed, gather more information at:
#    https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/
#    If 'fpdir' isn't set, the script will return an error.
# 4. Run "source vivado_proj_builder.tcl"
################################################################

if {![info exists fpdir]} {
    puts "\nError: You must set the 'fpdir' variable before running this script."
    puts "Use the command: 'set fpdir <dir>'"
    puts "This variable should point to the FrontPanel Vivado IP Core."
    puts "If it's not installed, learn more at:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/"
    return
}

################################################################
# Check if script is running in the correct Vivado version.
################################################################
set tested_vivado_version 2023.1
set running_vivado_version [version -short]

if { [string compare $tested_vivado_version $running_vivado_version] != 0 } {
   puts "\nWarning: This script was tested against Vivado <$tested_vivado_version>."
   puts "You're running it in Vivado <$running_vivado_version>. For the most part,"
   puts "everything should be fine with a different version. However, varying Vivado"
   puts "versions might have different IP Core Versions. This might introduce breaking changes."
   puts "If you face any issues, please revert to the tested version mentioned."
}

################################################################
# START
################################################################

# The design that will be created by this Tcl script contains the following 
# module references:
# btpipe2axi_video_stream

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./vivado/dpex8320.xpr> in the current working folder.

set found 0
set foundBoard none
set maxVersion "1.1" ;# start just below your threshold
foreach item [split [get_board_parts] " "] {
    set parts [split $item ":"]
    if {[lindex $parts 1] eq "xem8320-au25p"} {
        set currVersion [lindex $parts 3]
        if {$currVersion >= "1.2" && $currVersion > $maxVersion} {
            set found 1
            set foundBoard $item
            set maxVersion $currVersion
        }
    }
}
if {!$found} {
    puts "\nError: At least XEM8320-AU25P board file version 1.2 is required."
    puts "Please install the board file. For more information see:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-board-files/"
    return
}

create_project dpex8320 vivado -part xcau25p-ffvb676-2-e
set_property BOARD_PART $foundBoard [current_project]

set ip_paths {}
lappend ip_paths \
[get_property $fpdir [current_fileset]] \
$fpdir

set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog -rebuild

# Get version and revision
set version [get_property VERSION [get_ipdefs opalkelly.com:ip:frontpanel:*]]
set revision [get_property CORE_REVISION [get_ipdefs opalkelly.com:ip:frontpanel:*]]

# Break version into major and minor numbers
regexp {(\d+)\.(\d+)} $version -> major minor

# Compare
if { ($major < 1) || 
     ($major == 1 && $minor == 0 && $revision < 4) } {
    puts "Error: At least FrontPanel Subsystem Vivado IP Core Version 1.0 Rev 4 is required."
    puts "Please update your IP core. To download, go to our documentation at:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/"
    return
} else {
    puts "FrontPanel Subsystem Vivado IP Core version and revision meet the requirements."
}

add_files -norecurse ../../../HDLComponents/FrontPanelToAxiLiteBridge/gateware/fp_to_axil.v
add_files -norecurse ../../../HDLComponents/FrontPanelToAxiLiteBridge/gateware/fp_to_axil_iwrap.v
add_files -norecurse btpipe2axi_video_stream.v
add_files -fileset constrs_1 -norecurse xem8320.xdc

create_ip -name fifo_generator -vendor xilinx.com -library ip -module_name fifo_generator_frontpanel
set_property -dict [list \
  CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
  CONFIG.Input_Data_Width {48} \
  CONFIG.Input_Depth {4096} \
  CONFIG.Overflow_Flag {true} \
  CONFIG.Performance_Options {First_Word_Fall_Through} \
  CONFIG.Reset_Pin {false} \
  CONFIG.Underflow_Flag {true} \
  CONFIG.Valid_Flag {true} \
] [get_ips fifo_generator_frontpanel]
update_compile_order -fileset sources_1


set design_name dpex8320

common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

create_bd_design $design_name

common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 0
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_vdma:6.3\
xilinx.com:ip:vid_phy_controller:2.2\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:v_mix:5.2\
opalkelly.com:ip:frontpanel:1.0\
xilinx.com:ip:v_frmbuf_wr:2.4\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:ip:util_reduced_logic:2.0\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:vid_edid:1.0\
xilinx.com:ip:video_frame_crc:1.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:v_dp_rxss1:3.1\
xilinx.com:ip:av_pat_gen:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:v_dp_txss1:3.1\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:axi_timer:2.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:axi_intc:4.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# DESIGN PROCs
##################################################################

# Hierarchical cell: interconnect
proc create_hier_cell_interconnect { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_interconnect() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_edid

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vphy

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dptxss

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dprxss

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mmcm

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_gpio

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_avpatgetn

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_frameCRC_rx

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_frameCRC_tx

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_wrbuf

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vdma

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mbdebug_rtl:3.0 MBDEBUG_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mbinterrupt_rtl:1.0 interrupt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vmix

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axil_frontpanel


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst clk_100_interconnect_aresetn
  create_bd_pin -dir O -type rst Debug_SYS_Rst
  create_bd_pin -dir I -from 0 -to 0 vid_phy_irq
  create_bd_pin -dir I -from 0 -to 0 dprx_iic_irq
  create_bd_pin -dir I -from 0 -to 0 dprx_irq
  create_bd_pin -dir I -from 0 -to 0 dptx_irq
  create_bd_pin -dir I -type clk clk_270m
  create_bd_pin -dir I -type rst clk_270m_peripheral_aresetn
  create_bd_pin -dir I -type clk clk_100
  create_bd_pin -dir O -from 0 -to 0 hls_resetn
  create_bd_pin -dir I -type rst processor_rst
  create_bd_pin -dir I -from 0 -to 0 -type rst clk_100_aresetn
  create_bd_pin -dir I vidmix_irq
  create_bd_pin -dir I -type clk okClk_m_axil_aclk
  create_bd_pin -dir I -type rst m_axil_frontpanel_aresetn
  create_bd_pin -dir I -from 0 -to 0 wrbuf_irq
  create_bd_pin -dir I -from 0 -to 0 change_batch_size_irq
  create_bd_pin -dir I -from 31 -to 0 fp2mb_axigpio

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000001} \
    CONFIG.C_GPIO_WIDTH {1} \
  ] $axi_gpio_0


  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_1 ]
  set_property -dict [list \
    CONFIG.M00_HAS_REGSLICE {1} \
    CONFIG.M01_HAS_REGSLICE {1} \
    CONFIG.M02_HAS_REGSLICE {1} \
    CONFIG.M03_HAS_REGSLICE {1} \
    CONFIG.M04_HAS_REGSLICE {1} \
    CONFIG.M05_HAS_REGSLICE {1} \
    CONFIG.M06_HAS_REGSLICE {1} \
    CONFIG.M07_HAS_REGSLICE {1} \
    CONFIG.M08_HAS_REGSLICE {1} \
    CONFIG.M09_HAS_REGSLICE {1} \
    CONFIG.M10_HAS_REGSLICE {1} \
    CONFIG.M11_HAS_REGSLICE {1} \
    CONFIG.M12_HAS_REGSLICE {1} \
    CONFIG.M13_HAS_REGSLICE {1} \
    CONFIG.M14_HAS_REGSLICE {1} \
    CONFIG.M15_HAS_REGSLICE {1} \
    CONFIG.NUM_MI {16} \
    CONFIG.NUM_SI {2} \
    CONFIG.S00_HAS_REGSLICE {1} \
    CONFIG.S01_HAS_REGSLICE {1} \
  ] $axi_interconnect_1


  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]
  set_property CONFIG.C_USE_UART {1} $mdm_1


  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]
  set_property CONFIG.NUM_PORTS {8} $xlconcat_1


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.M00_HAS_REGSLICE {1} \
    CONFIG.M01_HAS_REGSLICE {1} \
    CONFIG.M02_HAS_REGSLICE {1} \
    CONFIG.M03_HAS_REGSLICE {1} \
    CONFIG.M04_HAS_REGSLICE {1} \
    CONFIG.NUM_MI {2} \
    CONFIG.S00_HAS_REGSLICE {1} \
  ] $axi_interconnect_0


  # Create instance: axi_intc_1, and set properties
  set axi_intc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_1 ]
  set_property -dict [list \
    CONFIG.C_ASYNC_INTR {0xFFFFFFFF} \
    CONFIG.C_HAS_FAST {1} \
  ] $axi_intc_1


  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  set_property CONFIG.C_ALL_INPUTS {1} $axi_gpio_1


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins m_axi_vphy] [get_bd_intf_pins axi_interconnect_1/M07_AXI]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins MBDEBUG_0] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins m_axi_dptxss] [get_bd_intf_pins axi_interconnect_1/M08_AXI]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins m_axi_dprxss] [get_bd_intf_pins axi_interconnect_1/M09_AXI]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins m_axi_frameCRC_rx] [get_bd_intf_pins axi_interconnect_1/M14_AXI]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins m_axi_mmcm] [get_bd_intf_pins axi_interconnect_1/M12_AXI]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins m_axi_gpio] [get_bd_intf_pins axi_interconnect_1/M13_AXI]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins axi_interconnect_1/S01_AXI] [get_bd_intf_pins m_axil_frontpanel]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins axi_interconnect_1/M03_AXI] [get_bd_intf_pins m_axi_vmix]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins axi_interconnect_1/M15_AXI]
  connect_bd_intf_net -intf_net axi_intc_1_interrupt [get_bd_intf_pins interrupt] [get_bd_intf_pins axi_intc_1/interrupt]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins m_axi_wrbuf] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M01_AXI [get_bd_intf_pins axi_gpio_1/S_AXI] [get_bd_intf_pins axi_interconnect_1/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M02_AXI [get_bd_intf_pins m_axi_vdma] [get_bd_intf_pins axi_interconnect_1/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M04_AXI [get_bd_intf_pins m_axi_edid] [get_bd_intf_pins axi_interconnect_1/M04_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M05_AXI [get_bd_intf_pins axi_interconnect_1/M05_AXI] [get_bd_intf_pins mdm_1/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M06_AXI [get_bd_intf_pins axi_interconnect_1/M06_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M10_AXI [get_bd_intf_pins m_axi_avpatgetn] [get_bd_intf_pins axi_interconnect_1/M10_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M11_AXI [get_bd_intf_pins m_axi_frameCRC_tx] [get_bd_intf_pins axi_interconnect_1/M11_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_m00_axi [get_bd_intf_pins axi_intc_1/s_axi] [get_bd_intf_pins axi_interconnect_1/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_1_m_axi_dp [get_bd_intf_pins S00_AXI1] [get_bd_intf_pins axi_interconnect_1/S00_AXI]

  # Create port connections
  connect_bd_net -net In0_1 [get_bd_pins vid_phy_irq] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net In1_1 [get_bd_pins dprx_iic_irq] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net In2_1 [get_bd_pins dprx_irq] [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net In3_1 [get_bd_pins dptx_irq] [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net In6_1 [get_bd_pins vidmix_irq] [get_bd_pins xlconcat_1/In5]
  connect_bd_net -net In7_1 [get_bd_pins wrbuf_irq] [get_bd_pins xlconcat_1/In6]
  connect_bd_net -net In8_0_1 [get_bd_pins change_batch_size_irq] [get_bd_pins xlconcat_1/In7]
  connect_bd_net -net M16_ACLK_1 [get_bd_pins clk_270m] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_1/M03_ACLK]
  connect_bd_net -net M16_ARESETN_1 [get_bd_pins clk_270m_peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_1/M03_ARESETN]
  connect_bd_net -net S01_ACLK_1 [get_bd_pins okClk_m_axil_aclk] [get_bd_pins axi_interconnect_1/S01_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_interconnect_1/M01_ACLK]
  connect_bd_net -net S01_ARESETN_1 [get_bd_pins m_axil_frontpanel_aresetn] [get_bd_pins axi_interconnect_1/S01_ARESETN]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins hls_resetn]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins xlconcat_1/In4]
  connect_bd_net -net gpio_io_i_1 [get_bd_pins fp2mb_axigpio] [get_bd_pins axi_gpio_1/gpio_io_i]
  connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins Debug_SYS_Rst]
  connect_bd_net -net mig_1_ui_clk [get_bd_pins clk_100] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/M02_ACLK] [get_bd_pins axi_interconnect_1/M04_ACLK] [get_bd_pins axi_interconnect_1/M05_ACLK] [get_bd_pins axi_interconnect_1/M06_ACLK] [get_bd_pins axi_interconnect_1/M07_ACLK] [get_bd_pins axi_interconnect_1/M08_ACLK] [get_bd_pins axi_interconnect_1/M09_ACLK] [get_bd_pins axi_interconnect_1/M10_ACLK] [get_bd_pins axi_interconnect_1/M11_ACLK] [get_bd_pins axi_interconnect_1/M12_ACLK] [get_bd_pins axi_interconnect_1/M13_ACLK] [get_bd_pins axi_interconnect_1/M14_ACLK] [get_bd_pins axi_interconnect_1/M15_ACLK] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins mdm_1/S_AXI_ACLK] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_intc_1/s_axi_aclk] [get_bd_pins axi_intc_1/processor_clk]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_interconnect_1/M01_ARESETN]
  connect_bd_net -net proc_sys_reset_1_interconnect_aresetn [get_bd_pins clk_100_interconnect_aresetn] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_0/ARESETN]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins clk_100_aresetn] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/M02_ARESETN] [get_bd_pins axi_interconnect_1/M04_ARESETN] [get_bd_pins axi_interconnect_1/M05_ARESETN] [get_bd_pins axi_interconnect_1/M06_ARESETN] [get_bd_pins axi_interconnect_1/M07_ARESETN] [get_bd_pins axi_interconnect_1/M08_ARESETN] [get_bd_pins axi_interconnect_1/M09_ARESETN] [get_bd_pins axi_interconnect_1/M10_ARESETN] [get_bd_pins axi_interconnect_1/M11_ARESETN] [get_bd_pins axi_interconnect_1/M12_ARESETN] [get_bd_pins axi_interconnect_1/M13_ARESETN] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins mdm_1/S_AXI_ARESETN] [get_bd_pins axi_intc_1/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins axi_interconnect_1/M14_ARESETN] [get_bd_pins axi_interconnect_1/M15_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net processor_rst_1 [get_bd_pins processor_rst] [get_bd_pins axi_intc_1/processor_rst]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins xlconcat_1/dout] [get_bd_pins axi_intc_1/intr]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins proc_sys_reset_0/dcm_locked]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: VID_CLK_RST_hier
proc create_hier_cell_VID_CLK_RST_hier { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_VID_CLK_RST_hier() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_gpio

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_mmcm


  # Create pins
  create_bd_pin -dir O -type clk clk_270_tx
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_DOUT_DEFAULT_2 {0x00000001} \
    CONFIG.C_GPIO2_WIDTH {1} \
    CONFIG.C_GPIO_WIDTH {1} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.CLKIN2_JITTER_PS {100.0} \
    CONFIG.CLKOUT1_JITTER {107.671} \
    CONFIG.CLKOUT1_PHASE_ERROR {97.646} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {270} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {60.750} \
    CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {4.500} \
    CONFIG.MMCM_DIVCLK_DIVIDE {5} \
    CONFIG.PHASESHIFT_MODE {WAVEFORM} \
    CONFIG.PRIM_SOURCE {No_buffer} \
    CONFIG.SECONDARY_IN_FREQ {100.000} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_DYN_RECONFIG {true} \
    CONFIG.USE_INCLK_SWITCHOVER {false} \
  ] $clk_wiz_0


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net processor_subsystem_M12_AXI [get_bd_intf_pins s_axi_mmcm] [get_bd_intf_pins clk_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net processor_subsystem_M13_AXI [get_bd_intf_pins s_axi_gpio] [get_bd_intf_pins axi_gpio_0/S_AXI]

  # Create port connections
  connect_bd_net -net axi_gpio_0_gpio2_io_o [get_bd_pins axi_gpio_0/gpio2_io_o] [get_bd_pins clk_wiz_0/s_axi_aresetn]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins clk_270_tx] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_pins proc_sys_reset_1/dcm_locked]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in]
  connect_bd_net -net mig_1_ui_clk [get_bd_pins s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins clk_wiz_0/s_axi_aclk] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_reset [get_bd_pins proc_sys_reset_1/peripheral_reset] [get_bd_pins peripheral_reset]
  connect_bd_net -net processor_subsystem_peripheral_aresetn1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: processor_subsystem
proc create_hier_cell_processor_subsystem { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_processor_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_wrbuf

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_avpatgetn

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dprxss

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dptxss

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_edid

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_frameCRC_rx

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_frameCRC_tx

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_gpio

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_mmcm

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vdma

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vphy

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_vmix

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axil_frontpanel


  # Create pins
  create_bd_pin -dir I -type rst clk_270m_peripheral_aresetn
  create_bd_pin -dir I clk_100
  create_bd_pin -dir I -type clk clk_270m
  create_bd_pin -dir I -from 0 -to 0 clk_locked
  create_bd_pin -dir I -type rst ddr4_reset_in
  create_bd_pin -dir I -from 0 -to 0 dprx_iic_irq
  create_bd_pin -dir I -from 0 -to 0 dprx_irq
  create_bd_pin -dir I -from 0 -to 0 dptx_irq
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -from 0 -to 0 hls_resetn
  create_bd_pin -dir O -from 0 -to 0 interconnect_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -from 0 -to 0 vid_phy_irq
  create_bd_pin -dir I vidmix_irq
  create_bd_pin -dir I -type clk okClk_m_axil_aclk
  create_bd_pin -dir I -type rst m_axil_frontpanel_aresetn
  create_bd_pin -dir O -type rst Debug_SYS_Rst
  create_bd_pin -dir I -from 0 -to 0 wrbuf_irq
  create_bd_pin -dir I -from 0 -to 0 change_batch_size_irq
  create_bd_pin -dir I -from 31 -to 0 fp2mb_axigpio

  # Create instance: interconnect
  create_hier_cell_interconnect $hier_obj interconnect

  # Create instance: microblaze_1, and set properties
  set microblaze_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_1 ]
  set_property -dict [list \
    CONFIG.C_ADDR_TAG_BITS {17} \
    CONFIG.C_CACHE_BYTE_SIZE {16384} \
    CONFIG.C_DCACHE_ADDR_TAG {17} \
    CONFIG.C_DCACHE_ALWAYS_USED {1} \
    CONFIG.C_DCACHE_BASEADDR {0x0000000080000000} \
    CONFIG.C_DCACHE_BYTE_SIZE {16384} \
    CONFIG.C_DCACHE_HIGHADDR {0x00000000FFFFFFFF} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_FREQ {100000000} \
    CONFIG.C_ICACHE_ALWAYS_USED {1} \
    CONFIG.C_ICACHE_BASEADDR {0x0000000080000000} \
    CONFIG.C_ICACHE_HIGHADDR {0x00000000FFFFFFFF} \
    CONFIG.C_M_AXI_DC_USER_SIGNALS {0} \
    CONFIG.C_M_AXI_IC_USER_SIGNALS {0} \
    CONFIG.C_USE_BARREL {1} \
    CONFIG.C_USE_DCACHE {1} \
    CONFIG.C_USE_EXT_BRK {0} \
    CONFIG.C_USE_EXT_NM_BRK {0} \
    CONFIG.C_USE_HW_MUL {1} \
    CONFIG.C_USE_ICACHE {1} \
    CONFIG.C_USE_INTERRUPT {2} \
    CONFIG.C_USE_MSR_INSTR {1} \
    CONFIG.C_USE_PCMP_INSTR {1} \
  ] $microblaze_1


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

  # Create instance: proc_sys_reset_3, and set properties
  set proc_sys_reset_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_3 ]

  # Create instance: lmb_v10_2, and set properties
  set lmb_v10_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 lmb_v10_2 ]

  # Create instance: blk_mem_gen_1, and set properties
  set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_1 ]
  set_property -dict [list \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $blk_mem_gen_1


  # Create instance: lmb_bram_if_cntlr_2, and set properties
  set lmb_bram_if_cntlr_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr lmb_bram_if_cntlr_2 ]

  # Create instance: lmb_bram_if_cntlr_1, and set properties
  set lmb_bram_if_cntlr_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr lmb_bram_if_cntlr_1 ]

  # Create instance: lmb_v10_1, and set properties
  set lmb_v10_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 lmb_v10_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins lmb_bram_if_cntlr_1/SLMB] [get_bd_intf_pins lmb_v10_1/LMB_Sl_0]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins lmb_bram_if_cntlr_2/SLMB] [get_bd_intf_pins lmb_v10_2/LMB_Sl_0]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins m_axi_vphy] [get_bd_intf_pins interconnect/m_axi_vphy]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins m_axi_dptxss] [get_bd_intf_pins interconnect/m_axi_dptxss]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins m_axi_dprxss] [get_bd_intf_pins interconnect/m_axi_dprxss]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins m_axi_frameCRC_rx] [get_bd_intf_pins interconnect/m_axi_frameCRC_rx]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins m_axi_mmcm] [get_bd_intf_pins interconnect/m_axi_mmcm]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins m_axi_edid] [get_bd_intf_pins interconnect/m_axi_edid]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins m_axi_gpio] [get_bd_intf_pins interconnect/m_axi_gpio]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins interconnect/m_axi_vmix] [get_bd_intf_pins m_axi_vmix]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins m_axi_avpatgetn] [get_bd_intf_pins interconnect/m_axi_avpatgetn]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins m_axi_vdma] [get_bd_intf_pins interconnect/m_axi_vdma]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins interconnect/m_axil_frontpanel] [get_bd_intf_pins m_axil_frontpanel]
  connect_bd_intf_net -intf_net interconnect_M15_AXI [get_bd_intf_pins m_axi_frameCRC_tx] [get_bd_intf_pins interconnect/m_axi_frameCRC_tx]
  connect_bd_intf_net -intf_net interconnect_MBDEBUG_0 [get_bd_intf_pins interconnect/MBDEBUG_0] [get_bd_intf_pins microblaze_1/DEBUG]
  connect_bd_intf_net -intf_net interconnect_VDMA_FP_AXI [get_bd_intf_pins m_axi_wrbuf] [get_bd_intf_pins interconnect/m_axi_wrbuf]
  connect_bd_intf_net -intf_net interconnect_interrupt [get_bd_intf_pins interconnect/interrupt] [get_bd_intf_pins microblaze_1/INTERRUPT]
  connect_bd_intf_net -intf_net lmb_bram_if_cntlr_1_bram_port [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTB] [get_bd_intf_pins lmb_bram_if_cntlr_1/BRAM_PORT]
  connect_bd_intf_net -intf_net lmb_bram_if_cntlr_2_bram_port [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA] [get_bd_intf_pins lmb_bram_if_cntlr_2/BRAM_PORT]
  connect_bd_intf_net -intf_net microblaze_1_M_AXI_DP [get_bd_intf_pins interconnect/S00_AXI1] [get_bd_intf_pins microblaze_1/M_AXI_DP]
  connect_bd_intf_net -intf_net microblaze_1_dlmb [get_bd_intf_pins lmb_v10_1/LMB_M] [get_bd_intf_pins microblaze_1/DLMB]
  connect_bd_intf_net -intf_net microblaze_1_ilmb [get_bd_intf_pins lmb_v10_2/LMB_M] [get_bd_intf_pins microblaze_1/ILMB]
  connect_bd_intf_net -intf_net microblaze_1_m_axi_dc [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins microblaze_1/M_AXI_DC]
  connect_bd_intf_net -intf_net microblaze_1_m_axi_ic [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins microblaze_1/M_AXI_IC]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins interconnect_aresetn] [get_bd_pins interconnect/clk_100_interconnect_aresetn]
  connect_bd_net -net In0_1 [get_bd_pins vid_phy_irq] [get_bd_pins interconnect/vid_phy_irq]
  connect_bd_net -net In1_1 [get_bd_pins dprx_iic_irq] [get_bd_pins interconnect/dprx_iic_irq]
  connect_bd_net -net In2_1 [get_bd_pins dprx_irq] [get_bd_pins interconnect/dprx_irq]
  connect_bd_net -net In4_1 [get_bd_pins dptx_irq] [get_bd_pins interconnect/dptx_irq]
  connect_bd_net -net In7_1 [get_bd_pins wrbuf_irq] [get_bd_pins interconnect/wrbuf_irq]
  connect_bd_net -net In8_0_1 [get_bd_pins change_batch_size_irq] [get_bd_pins interconnect/change_batch_size_irq]
  connect_bd_net -net M16_ACLK_1 [get_bd_pins clk_270m] [get_bd_pins interconnect/clk_270m]
  connect_bd_net -net M16_ARESETN_1 [get_bd_pins clk_270m_peripheral_aresetn] [get_bd_pins interconnect/clk_270m_peripheral_aresetn]
  connect_bd_net -net S01_ACLK_1 [get_bd_pins okClk_m_axil_aclk] [get_bd_pins interconnect/okClk_m_axil_aclk]
  connect_bd_net -net S01_ARESETN_1 [get_bd_pins m_axil_frontpanel_aresetn] [get_bd_pins interconnect/m_axil_frontpanel_aresetn]
  connect_bd_net -net dcm_locked_1 [get_bd_pins clk_locked] [get_bd_pins proc_sys_reset_1/dcm_locked] [get_bd_pins proc_sys_reset_3/dcm_locked]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins proc_sys_reset_3/ext_reset_in]
  connect_bd_net -net gpio_io_i_1 [get_bd_pins fp2mb_axigpio] [get_bd_pins interconnect/fp2mb_axigpio]
  connect_bd_net -net interconnect_gpio_io_o_0 [get_bd_pins interconnect/hls_resetn] [get_bd_pins hls_resetn]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins interconnect/Debug_SYS_Rst] [get_bd_pins proc_sys_reset_1/mb_debug_sys_rst] [get_bd_pins proc_sys_reset_3/mb_debug_sys_rst] [get_bd_pins Debug_SYS_Rst]
  connect_bd_net -net proc_sys_reset_1_bus_struct_reset [get_bd_pins proc_sys_reset_1/bus_struct_reset] [get_bd_pins lmb_bram_if_cntlr_1/LMB_Rst] [get_bd_pins lmb_bram_if_cntlr_2/LMB_Rst] [get_bd_pins lmb_v10_1/SYS_Rst] [get_bd_pins lmb_v10_2/SYS_Rst]
  connect_bd_net -net proc_sys_reset_1_mb_reset [get_bd_pins proc_sys_reset_1/mb_reset] [get_bd_pins interconnect/processor_rst] [get_bd_pins microblaze_1/Reset]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins peripheral_aresetn1] [get_bd_pins interconnect/clk_100_aresetn]
  connect_bd_net -net proc_sys_reset_1_peripheral_reset [get_bd_pins proc_sys_reset_1/peripheral_reset] [get_bd_pins peripheral_reset]
  connect_bd_net -net proc_sys_reset_3_peripheral_aresetn [get_bd_pins proc_sys_reset_3/peripheral_aresetn] [get_bd_pins peripheral_aresetn]
  connect_bd_net -net processor_clk_1 [get_bd_pins clk_100] [get_bd_pins interconnect/clk_100] [get_bd_pins microblaze_1/Clk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins proc_sys_reset_3/slowest_sync_clk] [get_bd_pins lmb_v10_2/LMB_Clk] [get_bd_pins lmb_bram_if_cntlr_2/LMB_Clk] [get_bd_pins lmb_bram_if_cntlr_1/LMB_Clk] [get_bd_pins lmb_v10_1/LMB_Clk]
  connect_bd_net -net reset_in_1 [get_bd_pins ddr4_reset_in] [get_bd_pins proc_sys_reset_1/aux_reset_in] [get_bd_pins proc_sys_reset_3/aux_reset_in]
  connect_bd_net -net vidmix_irq_1 [get_bd_pins vidmix_irq] [get_bd_pins interconnect/vidmix_irq]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: memory_subsystem
proc create_hier_cell_memory_subsystem { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_memory_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 C0_DDR4

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MM2S_VDMA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM_VDMA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_WRBUF

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_VMIX


  # Create pins
  create_bd_pin -dir I -from 0 -to 0 clk_100_interconnect_aresetn
  create_bd_pin -dir O -type clk clk_100m
  create_bd_pin -dir O -type clk clk_270
  create_bd_pin -dir O -type clk clk_40m
  create_bd_pin -dir O -from 0 -to 0 clk_locked
  create_bd_pin -dir O -type rst ddr4_reset
  create_bd_pin -dir O -from 0 -to 0 -type rst interconnect_aresetn_0
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset
  create_bd_pin -dir I -type rst sys_rst1
  create_bd_pin -dir O -type clk clk_24m

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKOUT1_DRIVES {Buffer} \
    CONFIG.CLKOUT1_JITTER {102.698} \
    CONFIG.CLKOUT1_PHASE_ERROR {92.672} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {275} \
    CONFIG.CLKOUT2_DRIVES {Buffer} \
    CONFIG.CLKOUT3_DRIVES {Buffer} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {11} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {4} \
    CONFIG.MMCM_COMPENSATION {AUTO} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.PHASESHIFT_MODE {LATENCY} \
    CONFIG.PRIMITIVE {PLL} \
    CONFIG.PRIM_SOURCE {No_buffer} \
  ] $clk_wiz_0


  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0 ]
  set_property -dict [list \
    CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
    CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {39} \
    CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ {39} \
    CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {24} \
    CONFIG.C0.BANK_GROUP_WIDTH {1} \
    CONFIG.C0.DDR4_AxiAddressWidth {30} \
    CONFIG.C0_CLOCK_BOARD_INTERFACE {fixed_ddr4_100mhz} \
    CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
  ] $ddr4_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]

  # Create instance: proc_sys_reset_2, and set properties
  set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_2 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {3} \
    CONFIG.NUM_SI {6} \
  ] $smartconnect_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins C0_SYS_CLK] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins C0_DDR4] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins smartconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins smartconnect_0/S03_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins M_AXI_MM2S_VDMA] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins M_AXI_S2MM_VDMA] [get_bd_intf_pins smartconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins M_AXI_WRBUF] [get_bd_intf_pins smartconnect_0/S04_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins M_AXI_VMIX] [get_bd_intf_pins smartconnect_0/S05_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]

  # Create port connections
  connect_bd_net -net S02_ARESETN_1 [get_bd_pins clk_100_interconnect_aresetn] [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins clk_270] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins proc_sys_reset_2/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk1]
  connect_bd_net -net ddr4_0_addn_ui_clkout1 [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins clk_100m] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins smartconnect_0/aclk]
  connect_bd_net -net ddr4_0_addn_ui_clkout3 [get_bd_pins ddr4_0/addn_ui_clkout3] [get_bd_pins clk_40m]
  connect_bd_net -net ddr4_0_addn_ui_clkout4 [get_bd_pins ddr4_0/addn_ui_clkout4] [get_bd_pins clk_24m]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins ddr4_reset] [get_bd_pins clk_wiz_0/reset]
  connect_bd_net -net mig_1_ui_clk [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk2]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins peripheral_reset]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins ddr4_0/c0_ddr4_aresetn]
  connect_bd_net -net proc_sys_reset_2_interconnect_aresetn [get_bd_pins proc_sys_reset_2/interconnect_aresetn] [get_bd_pins interconnect_aresetn_0]
  connect_bd_net -net sys_rst1_1 [get_bd_pins sys_rst1] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins proc_sys_reset_2/ext_reset_in] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins clk_locked] [get_bd_pins proc_sys_reset_0/dcm_locked]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DP_TX_hier
proc create_hier_cell_DP_TX_hier { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DP_TX_hier() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_lnk_tx_lane0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_lnk_tx_lane1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_lnk_tx_lane2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_lnk_tx_lane3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_avpatgen

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_dptxss

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_frameCRC

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_gpio

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_mmcm

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_audio

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_phy_tx_sb_status

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_video


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 aux_tx_data_en_out_n_0
  create_bd_pin -dir I aux_tx_data_in_0
  create_bd_pin -dir O aux_tx_data_out_0
  create_bd_pin -dir O dptxss_dp_irq
  create_bd_pin -dir I -type rst hls_rst_n
  create_bd_pin -dir I -type rst resetn_270
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axis_aclk
  create_bd_pin -dir I -type rst system_rst
  create_bd_pin -dir I -type data tx_hpd
  create_bd_pin -dir I -type clk tx_lnk_clk
  create_bd_pin -dir I clk_24m

  # Create instance: VID_CLK_RST_hier
  create_hier_cell_VID_CLK_RST_hier $hier_obj VID_CLK_RST_hier

  # Create instance: av_pat_gen_0, and set properties
  set av_pat_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:av_pat_gen av_pat_gen_0 ]
  set_property CONFIG.BPC {8} $av_pat_gen_0


  # Create instance: axis_data_fifo_1, and set properties
  set axis_data_fifo_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo axis_data_fifo_1 ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {256} \
    CONFIG.IS_ACLK_ASYNC {1} \
  ] $axis_data_fifo_1


  # Create instance: proc_sys_reset_2, and set properties
  set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_2 ]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: video_frame_crc_tx, and set properties
  set video_frame_crc_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:video_frame_crc video_frame_crc_tx ]
  set_property CONFIG.BPC {8} $video_frame_crc_tx


  # Create instance: v_dp_txss1_0, and set properties
  set v_dp_txss1_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_dp_txss1 v_dp_txss1_0 ]
  set_property -dict [list \
    CONFIG.AUDIO_ENABLE {1} \
    CONFIG.AUX_IO_LOC {1} \
    CONFIG.HDCP_ENABLE {0} \
  ] $v_dp_txss1_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins s_axi_avpatgen] [get_bd_intf_pins av_pat_gen_0/av_axi]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_frameCRC] [get_bd_intf_pins video_frame_crc_tx/S_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins s_axis_audio] [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins s_axi_gpio] [get_bd_intf_pins VID_CLK_RST_hier/s_axi_gpio]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins s_axi_mmcm] [get_bd_intf_pins VID_CLK_RST_hier/s_axi_mmcm]
  connect_bd_intf_net -intf_net av_pat_gen_0_vid_out_axi4s [get_bd_intf_pins av_pat_gen_0/vid_out_axi4s] [get_bd_intf_pins video_frame_crc_tx/Vid_In_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS [get_bd_intf_pins av_pat_gen_0/aud_in_axi4s] [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
  connect_bd_intf_net -intf_net s_axi1_1 [get_bd_intf_pins s_axi_dptxss] [get_bd_intf_pins v_dp_txss1_0/s_axi]
  connect_bd_intf_net -intf_net s_axis_phy_tx_sb_status_1 [get_bd_intf_pins s_axis_phy_tx_sb_status] [get_bd_intf_pins v_dp_txss1_0/s_axis_phy_tx_sb_status]
  connect_bd_intf_net -intf_net s_axis_video_1 [get_bd_intf_pins s_axis_video] [get_bd_intf_pins av_pat_gen_0/vid_in_axi4s]
  connect_bd_intf_net -intf_net v_dp_txss1_0_m_axis_lnk_tx_lane0 [get_bd_intf_pins m_axis_lnk_tx_lane0] [get_bd_intf_pins v_dp_txss1_0/m_axis_lnk_tx_lane0]
  connect_bd_intf_net -intf_net v_dp_txss1_0_m_axis_lnk_tx_lane1 [get_bd_intf_pins m_axis_lnk_tx_lane1] [get_bd_intf_pins v_dp_txss1_0/m_axis_lnk_tx_lane1]
  connect_bd_intf_net -intf_net v_dp_txss1_0_m_axis_lnk_tx_lane2 [get_bd_intf_pins m_axis_lnk_tx_lane2] [get_bd_intf_pins v_dp_txss1_0/m_axis_lnk_tx_lane2]
  connect_bd_intf_net -intf_net v_dp_txss1_0_m_axis_lnk_tx_lane3 [get_bd_intf_pins m_axis_lnk_tx_lane3] [get_bd_intf_pins v_dp_txss1_0/m_axis_lnk_tx_lane3]
  connect_bd_intf_net -intf_net video_frame_crc_tx_Vid_Out_AXIS [get_bd_intf_pins v_dp_txss1_0/s_axis_video_stream1] [get_bd_intf_pins video_frame_crc_tx/Vid_Out_AXIS]

  # Create port connections
  connect_bd_net -net ARESETN1_1 [get_bd_pins s_axi_aresetn] [get_bd_pins VID_CLK_RST_hier/s_axi_aresetn] [get_bd_pins av_pat_gen_0/av_axi_aresetn] [get_bd_pins axis_data_fifo_1/s_axis_aresetn] [get_bd_pins video_frame_crc_tx/s_axi_aresetn] [get_bd_pins v_dp_txss1_0/s_axi_aresetn]
  connect_bd_net -net VID_CLK_RST_hier_peripheral_reset [get_bd_pins VID_CLK_RST_hier/peripheral_reset] [get_bd_pins v_dp_txss1_0/tx_vid_rst_stream1]
  connect_bd_net -net aux_tx_data_in_0_1 [get_bd_pins aux_tx_data_in_0] [get_bd_pins v_dp_txss1_0/aux_tx_data_in]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins VID_CLK_RST_hier/clk_270_tx] [get_bd_pins v_dp_txss1_0/tx_vid_clk_stream1]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins system_rst] [get_bd_pins VID_CLK_RST_hier/ext_reset_in] [get_bd_pins proc_sys_reset_2/ext_reset_in]
  connect_bd_net -net mig_1_ui_clk [get_bd_pins s_axi_aclk] [get_bd_pins VID_CLK_RST_hier/s_axi_aclk] [get_bd_pins av_pat_gen_0/av_axi_aclk] [get_bd_pins axis_data_fifo_1/s_axis_aclk] [get_bd_pins video_frame_crc_tx/s_axi_aclk] [get_bd_pins v_dp_txss1_0/s_axi_aclk]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins av_pat_gen_0/aud_out_axi4s_aresetn] [get_bd_pins v_dp_txss1_0/s_axis_audio_ingress_aresetn]
  connect_bd_net -net proc_sys_reset_2_peripheral_reset [get_bd_pins proc_sys_reset_2/peripheral_reset] [get_bd_pins v_dp_txss1_0/aud_rst]
  connect_bd_net -net s_axis_aclk_1 [get_bd_pins s_axis_aclk] [get_bd_pins av_pat_gen_0/vid_out_axi4s_aclk] [get_bd_pins video_frame_crc_tx/vid_in_axis_aclk] [get_bd_pins v_dp_txss1_0/s_axis_aclk_stream1]
  connect_bd_net -net s_axis_aresetn_1 [get_bd_pins resetn_270] [get_bd_pins av_pat_gen_0/vid_out_axi4s_aresetn] [get_bd_pins video_frame_crc_tx/vid_in_axis_aresetn] [get_bd_pins v_dp_txss1_0/s_axis_aresetn_stream1]
  connect_bd_net -net tx_hpd_1 [get_bd_pins tx_hpd] [get_bd_pins v_dp_txss1_0/tx_hpd]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins clk_24m] [get_bd_pins av_pat_gen_0/aud_out_axi4s_aclk] [get_bd_pins av_pat_gen_0/aud_clk] [get_bd_pins axis_data_fifo_1/m_axis_aclk] [get_bd_pins proc_sys_reset_2/slowest_sync_clk] [get_bd_pins v_dp_txss1_0/aud_clk] [get_bd_pins v_dp_txss1_0/s_axis_audio_ingress_aclk]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins aux_tx_data_en_out_n_0]
  connect_bd_net -net v_dp_txss1_0_aux_tx_data_en_out_n [get_bd_pins v_dp_txss1_0/aux_tx_data_en_out_n] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net v_dp_txss1_0_aux_tx_data_out [get_bd_pins v_dp_txss1_0/aux_tx_data_out] [get_bd_pins aux_tx_data_out_0]
  connect_bd_net -net v_dp_txss1_0_dptxss_dp_irq [get_bd_pins v_dp_txss1_0/dptxss_dp_irq] [get_bd_pins dptxss_dp_irq]
  connect_bd_net -net vid_phy_controller_0_txoutclk [get_bd_pins tx_lnk_clk] [get_bd_pins v_dp_txss1_0/tx_lnk_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: DP_RX_hier
proc create_hier_cell_DP_RX_hier { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_DP_RX_hier() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 aud_axi_egress

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_phy_rx_sb_control

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_video

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_dprxss

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_edid

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_frameCRC

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_lnk_rx_lane0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_lnk_rx_lane1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_lnk_rx_lane2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_lnk_rx_lane3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_phy_rx_sb_status

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 ext_iic_0


  # Create pins
  create_bd_pin -dir O -from 0 -to 0 aux_rx_data_en_out_n_0
  create_bd_pin -dir I aux_rx_data_in_0
  create_bd_pin -dir O aux_rx_data_out_0
  create_bd_pin -dir I -from 0 -to 0 -type clk clk_100m
  create_bd_pin -dir I -from 0 -to 0 -type rst ctl_reset
  create_bd_pin -dir O dprxss_dp_irq
  create_bd_pin -dir O dprxss_iic_irq
  create_bd_pin -dir I -from 0 -to 0 -type rst m_aud_axis_aresetn
  create_bd_pin -dir I -type clk m_axis_aclk_stream1
  create_bd_pin -dir I -type rst resetn_270
  create_bd_pin -dir O -from 0 -to 0 -type data rx_hpd
  create_bd_pin -dir I -type clk rx_lnk_clk
  create_bd_pin -dir I -from 0 -to 0 -type rst rx_vid_rst
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn

  # Create instance: util_reduced_logic_0, and set properties
  set util_reduced_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_0 ]
  set_property CONFIG.C_SIZE {2} $util_reduced_logic_0


  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic util_vector_logic_1 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_1


  # Create instance: vid_edid_0, and set properties
  set vid_edid_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vid_edid vid_edid_0 ]

  # Create instance: video_frame_crc_rx, and set properties
  set video_frame_crc_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:video_frame_crc video_frame_crc_rx ]
  set_property CONFIG.BPC {8} $video_frame_crc_rx


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: v_dp_rxss1_0, and set properties
  set v_dp_rxss1_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_dp_rxss1 v_dp_rxss1_0 ]
  set_property -dict [list \
    CONFIG.AUDIO_ENABLE {1} \
    CONFIG.AUX_IO_LOC {1} \
  ] $v_dp_rxss1_0


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins v_dp_rxss1_0/ext_iic] [get_bd_intf_pins ext_iic_0]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins s_axi_frameCRC] [get_bd_intf_pins video_frame_crc_rx/S_AXI]
  connect_bd_intf_net -intf_net processor_subsystem_M07_AXI [get_bd_intf_pins s_axi_edid] [get_bd_intf_pins vid_edid_0/s_axi]
  connect_bd_intf_net -intf_net s_axi2_1 [get_bd_intf_pins s_axi_dprxss] [get_bd_intf_pins v_dp_rxss1_0/s_axi]
  connect_bd_intf_net -intf_net s_axis_lnk_rx_lane0_1 [get_bd_intf_pins s_axis_lnk_rx_lane0] [get_bd_intf_pins v_dp_rxss1_0/s_axis_lnk_rx_lane0]
  connect_bd_intf_net -intf_net s_axis_lnk_rx_lane1_1 [get_bd_intf_pins s_axis_lnk_rx_lane1] [get_bd_intf_pins v_dp_rxss1_0/s_axis_lnk_rx_lane1]
  connect_bd_intf_net -intf_net s_axis_lnk_rx_lane2_1 [get_bd_intf_pins s_axis_lnk_rx_lane2] [get_bd_intf_pins v_dp_rxss1_0/s_axis_lnk_rx_lane2]
  connect_bd_intf_net -intf_net s_axis_lnk_rx_lane3_1 [get_bd_intf_pins s_axis_lnk_rx_lane3] [get_bd_intf_pins v_dp_rxss1_0/s_axis_lnk_rx_lane3]
  connect_bd_intf_net -intf_net s_axis_phy_rx_sb_status_1 [get_bd_intf_pins s_axis_phy_rx_sb_status] [get_bd_intf_pins v_dp_rxss1_0/s_axis_phy_rx_sb_status]
  connect_bd_intf_net -intf_net v_dp_rxss1_0_aud_axi_egress [get_bd_intf_pins aud_axi_egress] [get_bd_intf_pins v_dp_rxss1_0/aud_axi_egress]
  connect_bd_intf_net -intf_net v_dp_rxss1_0_m_axis_phy_rx_sb_control [get_bd_intf_pins m_axis_phy_rx_sb_control] [get_bd_intf_pins v_dp_rxss1_0/m_axis_phy_rx_sb_control]
  connect_bd_intf_net -intf_net v_dp_rxss1_0_m_axis_video_stream1 [get_bd_intf_pins v_dp_rxss1_0/m_axis_video_stream1] [get_bd_intf_pins video_frame_crc_rx/Vid_In_AXIS]
  connect_bd_intf_net -intf_net video_frame_crc_rx_Vid_Out_AXIS [get_bd_intf_pins m_axis_video] [get_bd_intf_pins video_frame_crc_rx/Vid_Out_AXIS]

  # Create port connections
  connect_bd_net -net ARESETN1_1 [get_bd_pins s_axi_aresetn] [get_bd_pins vid_edid_0/s_axi_aresetn] [get_bd_pins v_dp_rxss1_0/s_axi_aresetn]
  connect_bd_net -net Net4 [get_bd_pins v_dp_rxss1_0/edid_iic_scl_t] [get_bd_pins vid_edid_0/iic_scl_in] [get_bd_pins v_dp_rxss1_0/edid_iic_scl_i]
  connect_bd_net -net aux_rx_data_in_0_1 [get_bd_pins aux_rx_data_in_0] [get_bd_pins v_dp_rxss1_0/aux_rx_data_in]
  connect_bd_net -net dp_rx_subsystem_0_edid_i2c_sda_en_i [get_bd_pins v_dp_rxss1_0/edid_iic_sda_t] [get_bd_pins vid_edid_0/iic_sda_in] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net memory_subsystem_clk_200 [get_bd_pins m_axis_aclk_stream1] [get_bd_pins video_frame_crc_rx/vid_in_axis_aclk] [get_bd_pins v_dp_rxss1_0/rx_vid_clk] [get_bd_pins v_dp_rxss1_0/m_axis_aclk_stream1]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins rx_vid_rst] [get_bd_pins v_dp_rxss1_0/rx_vid_rst]
  connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins m_aud_axis_aresetn] [get_bd_pins video_frame_crc_rx/s_axi_aresetn] [get_bd_pins v_dp_rxss1_0/m_aud_axis_aresetn]
  connect_bd_net -net processor_subsystem_peripheral_reset [get_bd_pins ctl_reset] [get_bd_pins vid_edid_0/ctl_reset]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins clk_100m] [get_bd_pins vid_edid_0/s_axi_aclk] [get_bd_pins vid_edid_0/ctl_clk] [get_bd_pins video_frame_crc_rx/s_axi_aclk] [get_bd_pins v_dp_rxss1_0/s_axi_aclk] [get_bd_pins v_dp_rxss1_0/m_aud_axis_aclk]
  connect_bd_net -net util_reduced_logic_0_Res [get_bd_pins util_reduced_logic_0/Res] [get_bd_pins v_dp_rxss1_0/edid_iic_sda_i]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins aux_rx_data_en_out_n_0]
  connect_bd_net -net v_dp_rxss1_0_aux_rx_data_en_out_n [get_bd_pins v_dp_rxss1_0/aux_rx_data_en_out_n] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net v_dp_rxss1_0_aux_rx_data_out [get_bd_pins v_dp_rxss1_0/aux_rx_data_out] [get_bd_pins aux_rx_data_out_0]
  connect_bd_net -net v_dp_rxss1_0_dprxss_dp_irq [get_bd_pins v_dp_rxss1_0/dprxss_dp_irq] [get_bd_pins dprxss_dp_irq]
  connect_bd_net -net v_dp_rxss1_0_dprxss_iic_irq [get_bd_pins v_dp_rxss1_0/dprxss_iic_irq] [get_bd_pins dprxss_iic_irq]
  connect_bd_net -net v_dp_rxss1_0_rx_hpd [get_bd_pins v_dp_rxss1_0/rx_hpd] [get_bd_pins rx_hpd]
  connect_bd_net -net vid_edid_0_iic_sda_out [get_bd_pins vid_edid_0/iic_sda_out] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net vid_in_axis_aresetn_1 [get_bd_pins resetn_270] [get_bd_pins video_frame_crc_rx/vid_in_axis_aresetn]
  connect_bd_net -net vid_phy_controller_0_rxoutclk [get_bd_pins rx_lnk_clk] [get_bd_pins v_dp_rxss1_0/rx_lnk_clk]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins xlconcat_0/dout] [get_bd_pins util_reduced_logic_0/Op1]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set C0_DDR4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 C0_DDR4 ]

  set C0_SYS_CLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $C0_SYS_CLK

  set ext_iic_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 ext_iic_0 ]

  set host_interface [ create_bd_intf_port -mode Slave -vlnv opalkelly.com:interface:host_interface_rtl:1.0 host_interface ]


  # Create ports
  set aux_rx_data_en_out_n_0 [ create_bd_port -dir O -from 0 -to 0 aux_rx_data_en_out_n_0 ]
  set aux_rx_data_in_0 [ create_bd_port -dir I aux_rx_data_in_0 ]
  set aux_rx_data_out_0 [ create_bd_port -dir O aux_rx_data_out_0 ]
  set aux_tx_data_en_out_n_0 [ create_bd_port -dir O -from 0 -to 0 aux_tx_data_en_out_n_0 ]
  set aux_tx_data_in_0 [ create_bd_port -dir I aux_tx_data_in_0 ]
  set aux_tx_data_out_0 [ create_bd_port -dir O aux_tx_data_out_0 ]
  set lnk_rx_lane_n [ create_bd_port -dir I -from 3 -to 0 lnk_rx_lane_n ]
  set lnk_rx_lane_p [ create_bd_port -dir I -from 3 -to 0 lnk_rx_lane_p ]
  set mgtrefclk0_pad_n_in [ create_bd_port -dir I mgtrefclk0_pad_n_in ]
  set mgtrefclk0_pad_p_in [ create_bd_port -dir I mgtrefclk0_pad_p_in ]
  set mgtrefclk1_pad_n_in [ create_bd_port -dir I mgtrefclk1_pad_n_in ]
  set mgtrefclk1_pad_p_in [ create_bd_port -dir I mgtrefclk1_pad_p_in ]
  set phy_txn_out [ create_bd_port -dir O -from 3 -to 0 phy_txn_out ]
  set phy_txp_out [ create_bd_port -dir O -from 3 -to 0 phy_txp_out ]
  set rx_hpd [ create_bd_port -dir O -from 0 -to 0 rx_hpd ]
  set tx_hpd [ create_bd_port -dir I -type data tx_hpd ]

  # Create instance: DP_RX_hier
  create_hier_cell_DP_RX_hier [current_bd_instance .] DP_RX_hier

  # Create instance: DP_TX_hier
  create_hier_cell_DP_TX_hier [current_bd_instance .] DP_TX_hier

  # Create instance: memory_subsystem
  create_hier_cell_memory_subsystem [current_bd_instance .] memory_subsystem

  # Create instance: processor_subsystem
  create_hier_cell_processor_subsystem [current_bd_instance .] processor_subsystem

  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_0 ]
  set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width {512} \
    CONFIG.c_m_axi_s2mm_data_width {512} \
    CONFIG.c_m_axis_mm2s_tdata_width {96} \
    CONFIG.c_mm2s_genlock_mode {3} \
    CONFIG.c_mm2s_linebuffer_depth {512} \
    CONFIG.c_mm2s_max_burst_length {64} \
    CONFIG.c_num_fstores {3} \
    CONFIG.c_s2mm_genlock_mode {2} \
    CONFIG.c_s2mm_linebuffer_depth {4096} \
    CONFIG.c_s2mm_max_burst_length {64} \
    CONFIG.c_use_mm2s_fsync {0} \
    CONFIG.c_use_s2mm_fsync {2} \
  ] $axi_vdma_0


  # Create instance: vid_phy_controller_0, and set properties
  set vid_phy_controller_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vid_phy_controller vid_phy_controller_0 ]
  set_property -dict [list \
    CONFIG.CHANNEL_SITE {X0Y0} \
    CONFIG.C_RX_REFCLK_SEL {0} \
    CONFIG.C_TX_REFCLK_SEL {0} \
    CONFIG.Rx_Max_GT_Line_Rate {8.1} \
    CONFIG.Transceiver {GTYE4} \
    CONFIG.Transceiver_Width {2} \
    CONFIG.Tx_Buffer_Bypass {true} \
    CONFIG.Tx_Max_GT_Line_Rate {8.1} \
  ] $vid_phy_controller_0


  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]

  # Create instance: v_mix_0, and set properties
  set v_mix_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_mix v_mix_0 ]
  set_property -dict [list \
    CONFIG.AXIMM_ADDR_WIDTH {32} \
    CONFIG.LAYER1_INTF_TYPE {0} \
    CONFIG.LAYER1_VIDEO_FORMAT {20} \
    CONFIG.MAX_COLS {8192} \
    CONFIG.MAX_ROWS {4320} \
    CONFIG.NR_LAYERS {2} \
    CONFIG.SAMPLES_PER_CLOCK {4} \
  ] $v_mix_0


  # Create instance: frontpanel_0, and set properties
  set frontpanel_0 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:frontpanel frontpanel_0 ]
  set_property -dict [list \
    CONFIG.BTPI.ADDR_0 {0x80} \
    CONFIG.BTPI.COUNT {1} \
    CONFIG.PI.COUNT {0} \
    CONFIG.TI.ADDR_0 {0x40} \
    CONFIG.TI.ADDR_1 {0x41} \
    CONFIG.TI.ADDR_2 {0x5f} \
    CONFIG.TI.COUNT {3} \
    CONFIG.WI.ADDR_0 {0x10} \
    CONFIG.WI.ADDR_1 {0x11} \
    CONFIG.WI.ADDR_2 {0x12} \
    CONFIG.WI.ADDR_3 {0x1d} \
    CONFIG.WI.ADDR_4 {0x1e} \
    CONFIG.WI.ADDR_5 {0x1f} \
    CONFIG.WI.COUNT {6} \
    CONFIG.WO.ADDR_0 {0x30} \
    CONFIG.WO.ADDR_1 {0x3e} \
    CONFIG.WO.ADDR_2 {0x3f} \
    CONFIG.WO.ADDR_3 {0xff} \
    CONFIG.WO.COUNT {3} \
    CONFIG.host_interface_BOARD_INTERFACE {host_interface} \
  ] $frontpanel_0


  # Create instance: v_frmbuf_wr_0, and set properties
  set v_frmbuf_wr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_frmbuf_wr v_frmbuf_wr_0 ]

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo axis_data_fifo_0 ]
  set_property -dict [list \
    CONFIG.FIFO_DEPTH {8192} \
    CONFIG.IS_ACLK_ASYNC {1} \
  ] $axis_data_fifo_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  
  # Create instance: fp_to_axil_iwrap_0, and set properties
  set block_name fp_to_axil_iwrap
  set block_cell_name fp_to_axil_iwrap_0
  if { [catch {set fp_to_axil_iwrap_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fp_to_axil_iwrap_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: btpipe2axi_video_str_0, and set properties
  set block_name btpipe2axi_video_stream
  set block_cell_name btpipe2axi_video_str_0
  if { [catch {set btpipe2axi_video_str_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $btpipe2axi_video_str_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_ports C0_SYS_CLK] [get_bd_intf_pins memory_subsystem/C0_SYS_CLK]
  connect_bd_intf_net -intf_net DP_RX_hier_aud_axi_egress [get_bd_intf_pins DP_RX_hier/aud_axi_egress] [get_bd_intf_pins DP_TX_hier/s_axis_audio]
  connect_bd_intf_net -intf_net DP_RX_hier_ext_iic_0 [get_bd_intf_ports ext_iic_0] [get_bd_intf_pins DP_RX_hier/ext_iic_0]
  connect_bd_intf_net -intf_net DP_RX_hier_m_axis_video [get_bd_intf_pins DP_RX_hier/m_axis_video] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net S01_AXI_0_1 [get_bd_intf_pins processor_subsystem/m_axil_frontpanel] [get_bd_intf_pins fp_to_axil_iwrap_0/m_axil]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins v_mix_0/s_axis_video] [get_bd_intf_pins axi_vdma_0/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins axi_vdma_0/M_AXI_MM2S] [get_bd_intf_pins memory_subsystem/M_AXI_MM2S_VDMA]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins memory_subsystem/M_AXI_S2MM_VDMA]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins v_frmbuf_wr_0/s_axis_video]
  connect_bd_intf_net -intf_net btpipe2axi_video_str_0_m_rgb_axis [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins btpipe2axi_video_str_0/m_rgb_axis]
  connect_bd_intf_net -intf_net dp_rx_subsystem_0_m_axis_phy_rx_sb_control [get_bd_intf_pins DP_RX_hier/m_axis_phy_rx_sb_control] [get_bd_intf_pins vid_phy_controller_0/vid_phy_control_sb_rx]
  connect_bd_intf_net -intf_net dp_tx_subsystem_0_m_axis_lnk_tx_lane0 [get_bd_intf_pins DP_TX_hier/m_axis_lnk_tx_lane0] [get_bd_intf_pins vid_phy_controller_0/vid_phy_tx_axi4s_ch0]
  connect_bd_intf_net -intf_net dp_tx_subsystem_0_m_axis_lnk_tx_lane1 [get_bd_intf_pins DP_TX_hier/m_axis_lnk_tx_lane1] [get_bd_intf_pins vid_phy_controller_0/vid_phy_tx_axi4s_ch1]
  connect_bd_intf_net -intf_net dp_tx_subsystem_0_m_axis_lnk_tx_lane2 [get_bd_intf_pins DP_TX_hier/m_axis_lnk_tx_lane2] [get_bd_intf_pins vid_phy_controller_0/vid_phy_tx_axi4s_ch2]
  connect_bd_intf_net -intf_net dp_tx_subsystem_0_m_axis_lnk_tx_lane3 [get_bd_intf_pins DP_TX_hier/m_axis_lnk_tx_lane3] [get_bd_intf_pins vid_phy_controller_0/vid_phy_tx_axi4s_ch3]
  connect_bd_intf_net -intf_net frontpanel_0_btpipein80 [get_bd_intf_pins frontpanel_0/btpipein80] [get_bd_intf_pins btpipe2axi_video_str_0/btpipein80_rgb_data]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin41 [get_bd_intf_pins frontpanel_0/triggerin40] [get_bd_intf_pins btpipe2axi_video_str_0/triggerin40_video_control]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin42 [get_bd_intf_pins frontpanel_0/triggerin41] [get_bd_intf_pins btpipe2axi_video_str_0/triggerin41_microblaze_domain]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin5f [get_bd_intf_pins fp_to_axil_iwrap_0/triggerin5f_fp_to_axil_operation] [get_bd_intf_pins frontpanel_0/triggerin5f]
  connect_bd_intf_net -intf_net frontpanel_0_wirein10 [get_bd_intf_pins frontpanel_0/wirein10] [get_bd_intf_pins btpipe2axi_video_str_0/wirein10_transfers_in_line]
  connect_bd_intf_net -intf_net frontpanel_0_wirein11 [get_bd_intf_pins frontpanel_0/wirein11] [get_bd_intf_pins btpipe2axi_video_str_0/wirein11_transfers_in_frame]
  connect_bd_intf_net -intf_net frontpanel_0_wirein12 [get_bd_intf_pins frontpanel_0/wirein12] [get_bd_intf_pins btpipe2axi_video_str_0/wirein12_frames_in_batch]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1d [get_bd_intf_pins frontpanel_0/wirein1d] [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1d_fp_to_axil_addr]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1e [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1e_fp_to_axil_data] [get_bd_intf_pins frontpanel_0/wirein1e]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1f [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1f_fp_to_axil_timeout] [get_bd_intf_pins frontpanel_0/wirein1f]
  connect_bd_intf_net -intf_net frontpanel_0_wireout30 [get_bd_intf_pins frontpanel_0/wireout30] [get_bd_intf_pins btpipe2axi_video_str_0/wireout30_frame_status]
  connect_bd_intf_net -intf_net frontpanel_0_wireout3e [get_bd_intf_pins fp_to_axil_iwrap_0/wireout3e_fp_to_axil_data] [get_bd_intf_pins frontpanel_0/wireout3e]
  connect_bd_intf_net -intf_net frontpanel_0_wireout3f [get_bd_intf_pins fp_to_axil_iwrap_0/wireout3f_fp_to_axil_status] [get_bd_intf_pins frontpanel_0/wireout3f]
  connect_bd_intf_net -intf_net host_interface_1 [get_bd_intf_ports host_interface] [get_bd_intf_pins frontpanel_0/host_interface]
  connect_bd_intf_net -intf_net memory_subsystem_C0_DDR4 [get_bd_intf_ports C0_DDR4] [get_bd_intf_pins memory_subsystem/C0_DDR4]
  connect_bd_intf_net -intf_net proc_M_AXI_DC [get_bd_intf_pins memory_subsystem/M_AXI_DC] [get_bd_intf_pins processor_subsystem/M_AXI_DC]
  connect_bd_intf_net -intf_net proc_M_AXI_IC [get_bd_intf_pins memory_subsystem/M_AXI_IC] [get_bd_intf_pins processor_subsystem/M_AXI_IC]
  connect_bd_intf_net -intf_net processor_subsystem_M03_AXI [get_bd_intf_pins v_mix_0/s_axi_CTRL] [get_bd_intf_pins processor_subsystem/m_axi_vmix]
  connect_bd_intf_net -intf_net processor_subsystem_M07_AXI [get_bd_intf_pins DP_RX_hier/s_axi_edid] [get_bd_intf_pins processor_subsystem/m_axi_edid]
  connect_bd_intf_net -intf_net processor_subsystem_M07_AXI1 [get_bd_intf_pins processor_subsystem/m_axi_vphy] [get_bd_intf_pins vid_phy_controller_0/vid_phy_axi4lite]
  connect_bd_intf_net -intf_net processor_subsystem_M08_AXI [get_bd_intf_pins DP_TX_hier/s_axi_dptxss] [get_bd_intf_pins processor_subsystem/m_axi_dptxss]
  connect_bd_intf_net -intf_net processor_subsystem_M09_AXI [get_bd_intf_pins DP_RX_hier/s_axi_dprxss] [get_bd_intf_pins processor_subsystem/m_axi_dprxss]
  connect_bd_intf_net -intf_net processor_subsystem_M12_AXI [get_bd_intf_pins DP_TX_hier/s_axi_mmcm] [get_bd_intf_pins processor_subsystem/m_axi_mmcm]
  connect_bd_intf_net -intf_net processor_subsystem_M13_AXI [get_bd_intf_pins DP_TX_hier/s_axi_gpio] [get_bd_intf_pins processor_subsystem/m_axi_gpio]
  connect_bd_intf_net -intf_net processor_subsystem_M14_AXI [get_bd_intf_pins DP_TX_hier/s_axi_avpatgen] [get_bd_intf_pins processor_subsystem/m_axi_avpatgetn]
  connect_bd_intf_net -intf_net processor_subsystem_M14_AXI1 [get_bd_intf_pins DP_RX_hier/s_axi_frameCRC] [get_bd_intf_pins processor_subsystem/m_axi_frameCRC_rx]
  connect_bd_intf_net -intf_net processor_subsystem_M15_AXI1 [get_bd_intf_pins DP_TX_hier/s_axi_frameCRC] [get_bd_intf_pins processor_subsystem/m_axi_frameCRC_tx]
  connect_bd_intf_net -intf_net processor_subsystem_M18_AXI [get_bd_intf_pins axi_vdma_0/S_AXI_LITE] [get_bd_intf_pins processor_subsystem/m_axi_vdma]
  connect_bd_intf_net -intf_net processor_subsystem_VDMA_FP_AXI [get_bd_intf_pins processor_subsystem/m_axi_wrbuf] [get_bd_intf_pins v_frmbuf_wr_0/s_axi_CTRL]
  connect_bd_intf_net -intf_net s_axis_video_1 [get_bd_intf_pins DP_TX_hier/s_axis_video] [get_bd_intf_pins v_mix_0/m_axis_video]
  connect_bd_intf_net -intf_net v_frmbuf_wr_0_m_axi_mm_video [get_bd_intf_pins v_frmbuf_wr_0/m_axi_mm_video] [get_bd_intf_pins memory_subsystem/M_AXI_WRBUF]
  connect_bd_intf_net -intf_net v_mix_0_m_axi_mm_video1 [get_bd_intf_pins v_mix_0/m_axi_mm_video1] [get_bd_intf_pins memory_subsystem/M_AXI_VMIX]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_rx_axi4s_ch0 [get_bd_intf_pins DP_RX_hier/s_axis_lnk_rx_lane0] [get_bd_intf_pins vid_phy_controller_0/vid_phy_rx_axi4s_ch0]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_rx_axi4s_ch1 [get_bd_intf_pins DP_RX_hier/s_axis_lnk_rx_lane1] [get_bd_intf_pins vid_phy_controller_0/vid_phy_rx_axi4s_ch1]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_rx_axi4s_ch2 [get_bd_intf_pins DP_RX_hier/s_axis_lnk_rx_lane2] [get_bd_intf_pins vid_phy_controller_0/vid_phy_rx_axi4s_ch2]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_rx_axi4s_ch3 [get_bd_intf_pins DP_RX_hier/s_axis_lnk_rx_lane3] [get_bd_intf_pins vid_phy_controller_0/vid_phy_rx_axi4s_ch3]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_status_sb_rx [get_bd_intf_pins DP_RX_hier/s_axis_phy_rx_sb_status] [get_bd_intf_pins vid_phy_controller_0/vid_phy_status_sb_rx]
  connect_bd_intf_net -intf_net vid_phy_controller_0_vid_phy_status_sb_tx [get_bd_intf_pins DP_TX_hier/s_axis_phy_tx_sb_status] [get_bd_intf_pins vid_phy_controller_0/vid_phy_status_sb_tx]

  # Create port connections
  connect_bd_net -net DP_RX_hier_aux_rx_data_en_out_n_0 [get_bd_pins DP_RX_hier/aux_rx_data_en_out_n_0] [get_bd_ports aux_rx_data_en_out_n_0]
  connect_bd_net -net DP_RX_hier_aux_rx_data_out_0 [get_bd_pins DP_RX_hier/aux_rx_data_out_0] [get_bd_ports aux_rx_data_out_0]
  connect_bd_net -net DP_TX_hier_aux_tx_data_en_out_n_0 [get_bd_pins DP_TX_hier/aux_tx_data_en_out_n_0] [get_bd_ports aux_tx_data_en_out_n_0]
  connect_bd_net -net DP_TX_hier_aux_tx_data_out_0 [get_bd_pins DP_TX_hier/aux_tx_data_out_0] [get_bd_ports aux_tx_data_out_0]
  connect_bd_net -net In8_0_1 [get_bd_pins btpipe2axi_video_str_0/fp2mb_int_change_batch_size] [get_bd_pins processor_subsystem/change_batch_size_irq]
  connect_bd_net -net aux_rx_data_in_0_1 [get_bd_ports aux_rx_data_in_0] [get_bd_pins DP_RX_hier/aux_rx_data_in_0]
  connect_bd_net -net aux_tx_data_in_0_1 [get_bd_ports aux_tx_data_in_0] [get_bd_pins DP_TX_hier/aux_tx_data_in_0]
  connect_bd_net -net dcm_locked_2 [get_bd_pins memory_subsystem/clk_locked] [get_bd_pins processor_subsystem/clk_locked]
  connect_bd_net -net dp_rx_subsystem_0_dprxss_dp_irq [get_bd_pins DP_RX_hier/dprxss_dp_irq] [get_bd_pins processor_subsystem/dprx_irq]
  connect_bd_net -net dp_rx_subsystem_0_dprxss_iic_irq [get_bd_pins DP_RX_hier/dprxss_iic_irq] [get_bd_pins processor_subsystem/dprx_iic_irq]
  connect_bd_net -net dp_rx_subsystem_0_rx_hpd [get_bd_pins DP_RX_hier/rx_hpd] [get_bd_ports rx_hpd]
  connect_bd_net -net dp_tx_subsystem_0_dptxss_dp_irq [get_bd_pins DP_TX_hier/dptxss_dp_irq] [get_bd_pins processor_subsystem/dptx_irq]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins memory_subsystem/ddr4_reset] [get_bd_pins processor_subsystem/ddr4_reset_in]
  connect_bd_net -net frontpanel_0_okClk [get_bd_pins frontpanel_0/okClk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins btpipe2axi_video_str_0/aclk] [get_bd_pins fp_to_axil_iwrap_0/aclk] [get_bd_pins processor_subsystem/okClk_m_axil_aclk]
  connect_bd_net -net gpio_io_i_1 [get_bd_pins btpipe2axi_video_str_0/fp2mb_batch_size] [get_bd_pins processor_subsystem/fp2mb_axigpio]
  connect_bd_net -net lnk_rx_lane_n_1 [get_bd_ports lnk_rx_lane_n] [get_bd_pins vid_phy_controller_0/phy_rxn_in]
  connect_bd_net -net lnk_rx_lane_p_1 [get_bd_ports lnk_rx_lane_p] [get_bd_pins vid_phy_controller_0/phy_rxp_in]
  connect_bd_net -net memory_subsystem_addn_ui_clkout1 [get_bd_pins memory_subsystem/clk_100m] [get_bd_pins DP_RX_hier/clk_100m] [get_bd_pins DP_TX_hier/s_axi_aclk] [get_bd_pins processor_subsystem/clk_100] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins vid_phy_controller_0/vid_phy_sb_aclk] [get_bd_pins vid_phy_controller_0/vid_phy_axi4lite_aclk] [get_bd_pins btpipe2axi_video_str_0/microblaze_aclk]
  connect_bd_net -net memory_subsystem_addn_ui_clkout3 [get_bd_pins memory_subsystem/clk_40m] [get_bd_pins vid_phy_controller_0/drpclk]
  connect_bd_net -net memory_subsystem_clk_201 [get_bd_pins memory_subsystem/clk_270] [get_bd_pins DP_RX_hier/m_axis_aclk_stream1] [get_bd_pins DP_TX_hier/s_axis_aclk] [get_bd_pins processor_subsystem/clk_270m] [get_bd_pins axi_vdma_0/m_axi_mm2s_aclk] [get_bd_pins axi_vdma_0/m_axis_mm2s_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins v_mix_0/ap_clk] [get_bd_pins axis_data_fifo_0/m_axis_aclk] [get_bd_pins v_frmbuf_wr_0/ap_clk]
  connect_bd_net -net memory_subsystem_clk_24m [get_bd_pins memory_subsystem/clk_24m] [get_bd_pins DP_TX_hier/clk_24m]
  connect_bd_net -net memory_subsystem_interconnect_aresetn_0 [get_bd_pins memory_subsystem/interconnect_aresetn_0] [get_bd_pins DP_RX_hier/resetn_270] [get_bd_pins DP_TX_hier/resetn_270]
  connect_bd_net -net memory_subsystem_peripheral_aresetn [get_bd_pins memory_subsystem/peripheral_aresetn] [get_bd_pins processor_subsystem/clk_270m_peripheral_aresetn] [get_bd_pins v_mix_0/ap_rst_n] [get_bd_pins v_frmbuf_wr_0/ap_rst_n]
  connect_bd_net -net mgtrefclk0_pad_n_in_1 [get_bd_ports mgtrefclk0_pad_n_in] [get_bd_pins vid_phy_controller_0/mgtrefclk0_pad_n_in]
  connect_bd_net -net mgtrefclk0_pad_p_in_1 [get_bd_ports mgtrefclk0_pad_p_in] [get_bd_pins vid_phy_controller_0/mgtrefclk0_pad_p_in]
  connect_bd_net -net mgtrefclk1_pad_n_in_1 [get_bd_ports mgtrefclk1_pad_n_in] [get_bd_pins vid_phy_controller_0/mgtrefclk1_pad_n_in]
  connect_bd_net -net mgtrefclk1_pad_p_in_1 [get_bd_ports mgtrefclk1_pad_p_in] [get_bd_pins vid_phy_controller_0/mgtrefclk1_pad_p_in]
  connect_bd_net -net processor_subsystem_gpio_io_o_0 [get_bd_pins processor_subsystem/hls_resetn] [get_bd_pins DP_TX_hier/hls_rst_n]
  connect_bd_net -net processor_subsystem_interconnect_aresetn [get_bd_pins processor_subsystem/interconnect_aresetn] [get_bd_pins memory_subsystem/clk_100_interconnect_aresetn]
  connect_bd_net -net processor_subsystem_peripheral_aresetn [get_bd_pins processor_subsystem/peripheral_aresetn] [get_bd_pins vid_phy_controller_0/vid_phy_sb_aresetn] [get_bd_pins vid_phy_controller_0/vid_phy_axi4lite_aresetn]
  connect_bd_net -net processor_subsystem_peripheral_aresetn1 [get_bd_pins processor_subsystem/peripheral_aresetn1] [get_bd_pins DP_RX_hier/m_aud_axis_aresetn] [get_bd_pins DP_RX_hier/s_axi_aresetn] [get_bd_pins DP_TX_hier/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn]
  connect_bd_net -net processor_subsystem_peripheral_reset [get_bd_pins processor_subsystem/peripheral_reset] [get_bd_pins DP_RX_hier/ctl_reset]
  connect_bd_net -net rx_vid_rst_1 [get_bd_pins memory_subsystem/peripheral_reset] [get_bd_pins DP_RX_hier/rx_vid_rst]
  connect_bd_net -net sys_rst_1_1 [get_bd_pins xlconstant_0/dout] [get_bd_pins DP_TX_hier/system_rst] [get_bd_pins memory_subsystem/sys_rst1] [get_bd_pins btpipe2axi_video_str_0/aresetn] [get_bd_pins fp_to_axil_iwrap_0/aresetn] [get_bd_pins processor_subsystem/m_axil_frontpanel_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins processor_subsystem/ext_reset_in]
  connect_bd_net -net tx_hpd_1 [get_bd_ports tx_hpd] [get_bd_pins DP_TX_hier/tx_hpd]
  connect_bd_net -net v_frmbuf_wr_0_interrupt [get_bd_pins v_frmbuf_wr_0/interrupt] [get_bd_pins processor_subsystem/wrbuf_irq]
  connect_bd_net -net v_mix_0_interrupt [get_bd_pins v_mix_0/interrupt] [get_bd_pins processor_subsystem/vidmix_irq]
  connect_bd_net -net vid_phy_controller_0_irq [get_bd_pins vid_phy_controller_0/irq] [get_bd_pins processor_subsystem/vid_phy_irq]
  connect_bd_net -net vid_phy_controller_0_phy_txn_out [get_bd_pins vid_phy_controller_0/phy_txn_out] [get_bd_ports phy_txn_out]
  connect_bd_net -net vid_phy_controller_0_phy_txp_out [get_bd_pins vid_phy_controller_0/phy_txp_out] [get_bd_ports phy_txp_out]
  connect_bd_net -net vid_phy_controller_0_rxoutclk [get_bd_pins vid_phy_controller_0/rxoutclk] [get_bd_pins DP_RX_hier/rx_lnk_clk] [get_bd_pins vid_phy_controller_0/vid_phy_rx_axi4s_aclk]
  connect_bd_net -net vid_phy_controller_0_txoutclk [get_bd_pins vid_phy_controller_0/txoutclk] [get_bd_pins DP_TX_hier/tx_lnk_clk] [get_bd_pins vid_phy_controller_0/vid_phy_tx_axi4s_aclk]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins xlconstant_1/dout] [get_bd_pins vid_phy_controller_0/vid_phy_tx_axi4s_aresetn] [get_bd_pins vid_phy_controller_0/vid_phy_rx_axi4s_aresetn]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_MM2S] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces v_mix_0/Data_m_axi_mm_video1] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces v_frmbuf_wr_0/Data_m_axi_mm_video] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_TX_hier/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_TX_hier/VID_CLK_RST_hier/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs processor_subsystem/interconnect/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs processor_subsystem/interconnect/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs processor_subsystem/interconnect/axi_intc_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x41C10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs processor_subsystem/interconnect/axi_timer_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_TX_hier/VID_CLK_RST_hier/clk_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x41400000 -range 0x00001000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs processor_subsystem/interconnect/mdm_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x44B80000 -range 0x00040000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_RX_hier/v_dp_rxss1_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A80000 -range 0x00040000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_TX_hier/v_dp_txss1_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs v_mix_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_RX_hier/vid_edid_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs vid_phy_controller_0/vid_phy_axi4lite/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_RX_hier/video_frame_crc_rx/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs DP_TX_hier/video_frame_crc_tx/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_TX_hier/av_pat_gen_0/av_axi/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_TX_hier/VID_CLK_RST_hier/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/interconnect/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/interconnect/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/interconnect/axi_intc_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x41C10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/interconnect/axi_timer_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_TX_hier/VID_CLK_RST_hier/clk_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/lmb_bram_if_cntlr_1/SLMB/Mem] -force
  assign_bd_address -offset 0x41400000 -range 0x00001000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs processor_subsystem/interconnect/mdm_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x44B80000 -range 0x00040000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_RX_hier/v_dp_rxss1_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A80000 -range 0x00040000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_TX_hier/v_dp_txss1_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs v_frmbuf_wr_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs v_mix_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_RX_hier/vid_edid_0/s_axi/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs vid_phy_controller_0/vid_phy_axi4lite/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_RX_hier/video_frame_crc_rx/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Data] [get_bd_addr_segs DP_TX_hier/video_frame_crc_tx/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Instruction] [get_bd_addr_segs memory_subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces processor_subsystem/microblaze_1/Instruction] [get_bd_addr_segs processor_subsystem/lmb_bram_if_cntlr_2/SLMB/Mem] -force


  # Restore current instance
  current_bd_instance $oldCurInst
  
  regenerate_bd_layout

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

# Create Wrapper and set as top
set wrapperfile [make_wrapper -files [get_files [set design_name].bd] -top -import]
set_property top [set design_name]_wrapper [current_fileset]
update_compile_order -fileset sources_1
