################################################################
# Assisting script to create the FFT Signal Generator sample's
# IPI Block Design in Vivado.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source ifft_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# fp_slicer, ifft_controller, syzygy_dac_top

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcau25p-ffvb676-2-e
   set_property BOARD_PART opalkelly.com:xem8320-au25p:part0:1.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name ifft

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
irfft256_i20_o12_norm,\
FrontPanel Subsystem,\
LEDs\
"
   set ips_to_check [split $list_check_ips ,]

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $ips_to_check ."

   foreach ip_vlnv $ips_to_check {
      set ip_obj [get_ipdefs -name $ip_vlnv]
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
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
fp_slicer\
ifft_controller\
syzygy_dac_top\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
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
  set board_leds [ create_bd_intf_port -mode Master -vlnv opalkelly.com:interface:led_rtl:1.0 board_leds ]

  set host_interface [ create_bd_intf_port -mode Slave -vlnv opalkelly.com:interface:host_interface_rtl:1.0 host_interface ]


  # Create ports
  set dac_clk_0 [ create_bd_port -dir O -type clk dac_clk_0 ]
  set dac_cs_n_0 [ create_bd_port -dir O dac_cs_n_0 ]
  set dac_data_o_0 [ create_bd_port -dir O -from 11 -to 0 dac_data_o_0 ]
  set dac_reset_pinmd_0 [ create_bd_port -dir O dac_reset_pinmd_0 ]
  set dac_sclk_0 [ create_bd_port -dir O dac_sclk_0 ]
  set dac_sdio_0 [ create_bd_port -dir IO dac_sdio_0 ]

  # Create instance: IFFT_1, and set properties
  set IFFT_1 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:irfft256_i20_o12_norm:1.0 IFFT_1 ]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /IFFT_1/ap_rst]

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {99.2} \
   CONFIG.CLKOUT1_JITTER {227.404} \
   CONFIG.CLKOUT1_PHASE_ERROR {388.860} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {125} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {78.125} \
   CONFIG.MMCM_CLKIN1_PERIOD {9.921} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {9.000} \
   CONFIG.MMCM_DIVCLK_DIVIDE {7} \
   CONFIG.PRIM_IN_FREQ {100.8} \
   CONFIG.RESET_PORT {reset} \
   CONFIG.RESET_TYPE {ACTIVE_HIGH} \
 ] $clk_wiz_0

  # Create instance: fp_slicer_0, and set properties
  set block_name fp_slicer
  set block_cell_name fp_slicer_0
  if { [catch {set fp_slicer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $fp_slicer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /fp_slicer_0/ti41_resets_0_clk_reset]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /fp_slicer_0/wi00_control_1_ifft_reset]

  # Create instance: frontpanel_0, and set properties
  set frontpanel_0 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:frontpanel frontpanel_0 ]
  set_property -dict [ list \
   CONFIG.RB.EN {true} \
   CONFIG.TI.ADDR_0 {0x40} \
   CONFIG.TI.ADDR_1 {0x41} \
   CONFIG.TI.COUNT {2} \
   CONFIG.WI.ADDR_0 {0x00} \
   CONFIG.WI.COUNT {1} \
   CONFIG.WO.ADDR_0 {0x20} \
   CONFIG.WO.COUNT {1} \
   CONFIG.host_interface_BOARD_INTERFACE {host_interface} \
 ] $frontpanel_0

  # Create instance: ifft_controller_0, and set properties
  set block_name ifft_controller
  set block_cell_name ifft_controller_0
  if { [catch {set ifft_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ifft_controller_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /ifft_controller_0/ifft_reset]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /ifft_controller_0/reset]

  # Create instance: leds_0, and set properties
  set leds_0 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:leds leds_0 ]
  set_property -dict [ list \
   CONFIG.IOSTANDARD {LVCMOS18} \
   CONFIG.LED_OUT_BOARD_INTERFACE {board_leds} \
 ] $leds_0

  # Create instance: syzygy_dac_top_0, and set properties
  set block_name syzygy_dac_top
  set block_cell_name syzygy_dac_top_0
  if { [catch {set syzygy_dac_top_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $syzygy_dac_top_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.PHASE {90} \
 ] [get_bd_pins /syzygy_dac_top_0/dac_clk]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /syzygy_dac_top_0/reset]

  # Create interface connections
  connect_bd_intf_net -intf_net frontpanel_0_register_bridge [get_bd_intf_pins frontpanel_0/register_bridge] [get_bd_intf_pins ifft_controller_0/register_bridge]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin40 [get_bd_intf_pins fp_slicer_0/triggerin40_resets] [get_bd_intf_pins frontpanel_0/triggerin40]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin41 [get_bd_intf_pins fp_slicer_0/triggerin41_resets] [get_bd_intf_pins frontpanel_0/triggerin41]
  connect_bd_intf_net -intf_net frontpanel_0_wirein00 [get_bd_intf_pins fp_slicer_0/wirein00] [get_bd_intf_pins frontpanel_0/wirein00]
  connect_bd_intf_net -intf_net frontpanel_0_wireout20 [get_bd_intf_pins fp_slicer_0/wireout20_status] [get_bd_intf_pins frontpanel_0/wireout20]
  connect_bd_intf_net -intf_net host_interface_1 [get_bd_intf_ports host_interface] [get_bd_intf_pins frontpanel_0/host_interface]
  connect_bd_intf_net -intf_net leds_0_led_out [get_bd_intf_ports board_leds] [get_bd_intf_pins leds_0/led_out]

  # Create port connections
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 GND
  set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {40}] [get_bd_cells GND]
  connect_bd_net [get_bd_pins GND/dout] [get_bd_pins IFFT_1/dataIn_q1]
  connect_bd_net [get_bd_pins GND/dout] [get_bd_pins IFFT_1/dataOut_q0]
  connect_bd_net [get_bd_pins GND/dout] [get_bd_pins IFFT_1/dataOut_q1]
  connect_bd_net -net IFFT_1_ap_done [get_bd_pins IFFT_1/ap_done] [get_bd_pins ifft_controller_0/ifft_done]
  connect_bd_net -net IFFT_1_ap_idle [get_bd_pins IFFT_1/ap_idle] [get_bd_pins ifft_controller_0/ifft_idle]
  connect_bd_net -net IFFT_1_ap_ready [get_bd_pins IFFT_1/ap_ready] [get_bd_pins ifft_controller_0/ifft_ready]
  connect_bd_net -net IFFT_1_dataIn_address0 [get_bd_pins IFFT_1/dataIn_address0] [get_bd_pins ifft_controller_0/ifft_address_in]
  connect_bd_net -net IFFT_1_dataIn_ce0 [get_bd_pins IFFT_1/dataIn_ce0] [get_bd_pins ifft_controller_0/ifft_ce_in]
  connect_bd_net -net IFFT_1_dataOut_address0 [get_bd_pins IFFT_1/dataOut_address0] [get_bd_pins syzygy_dac_top_0/ifft_addr]
  connect_bd_net -net IFFT_1_dataOut_ce0 [get_bd_pins IFFT_1/dataOut_ce0] [get_bd_pins syzygy_dac_top_0/ifft_ce]
  connect_bd_net -net IFFT_1_dataOut_d0 [get_bd_pins IFFT_1/dataOut_d0] [get_bd_pins syzygy_dac_top_0/dac_data_i]
  connect_bd_net -net Net [get_bd_ports dac_sdio_0] [get_bd_pins syzygy_dac_top_0/dac_sdio]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins IFFT_1/ap_clk] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins fp_slicer_0/ifft_clk] [get_bd_pins ifft_controller_0/ifft_clk] [get_bd_pins syzygy_dac_top_0/clk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins fp_slicer_0/locked] [get_bd_pins ifft_controller_0/ifft_clk_locked] [get_bd_pins leds_0/led_in]
  connect_bd_net -net fp_slicer_0_clk_reset [get_bd_pins clk_wiz_0/reset] [get_bd_pins fp_slicer_0/ti41_resets_0_clk_reset]
  connect_bd_net -net fp_slicer_0_dis_out [get_bd_pins fp_slicer_0/wi00_control_0_dis_out] [get_bd_pins syzygy_dac_top_0/dis_out]
  connect_bd_net -net fp_slicer_0_ifft_ctrl_start [get_bd_pins fp_slicer_0/ti40_resets_1_ifft_ctrl_start] [get_bd_pins ifft_controller_0/start]
  connect_bd_net -net fp_slicer_0_ifft_reset [get_bd_pins fp_slicer_0/wi00_control_1_ifft_reset] [get_bd_pins ifft_controller_0/reset] [get_bd_pins syzygy_dac_top_0/reset]
  connect_bd_net -net frontpanel_0_okClk [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins fp_slicer_0/okClk] [get_bd_pins frontpanel_0/okClk] [get_bd_pins ifft_controller_0/okClk]
  connect_bd_net -net ifft_controller_0_ifft_input_data [get_bd_pins IFFT_1/dataIn_q0] [get_bd_pins ifft_controller_0/ifft_input_data]
  connect_bd_net -net ifft_controller_0_ifft_reset [get_bd_pins IFFT_1/ap_rst] [get_bd_pins ifft_controller_0/ifft_reset]
  connect_bd_net -net ifft_controller_0_ifft_start [get_bd_pins IFFT_1/ap_start] [get_bd_pins ifft_controller_0/ifft_start]
  connect_bd_net -net syzygy_dac_top_0_dac_clk [get_bd_ports dac_clk_0] [get_bd_pins syzygy_dac_top_0/dac_clk]
  connect_bd_net -net syzygy_dac_top_0_dac_cs_n [get_bd_ports dac_cs_n_0] [get_bd_pins syzygy_dac_top_0/dac_cs_n]
  connect_bd_net -net syzygy_dac_top_0_dac_data_o [get_bd_ports dac_data_o_0] [get_bd_pins syzygy_dac_top_0/dac_data_o]
  connect_bd_net -net syzygy_dac_top_0_dac_ready [get_bd_pins fp_slicer_0/dac_ready] [get_bd_pins syzygy_dac_top_0/dac_ready]
  connect_bd_net -net syzygy_dac_top_0_dac_reset_pinmd [get_bd_ports dac_reset_pinmd_0] [get_bd_pins syzygy_dac_top_0/dac_reset_pinmd]
  connect_bd_net -net syzygy_dac_top_0_dac_sclk [get_bd_ports dac_sclk_0] [get_bd_pins syzygy_dac_top_0/dac_sclk]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  
################################################################
# Check if script is running in correct Vivado version, warn if so.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "WARNING" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. There may be out of date or incompatible IPs."}

}
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
regenerate_bd_layout

# Create Wrapper and set as top
set wrapperfile [make_wrapper -files [get_files ifft.bd] -top -import]
set_property top ifft_wrapper [current_fileset]
update_compile_order -fileset sources_1
