# ========================================================================
# Vivado Project Builder Script for Opal Kelly Boards with FrontPanel
# ========================================================================
# This script sets up a Vivado project for the FrontPanel to AXI-Lite controller 
# example design, and is compatible with ALL Opal Kelly USB3 FPGA modules. The board-specific 
# XDC constraints are integrated within our Vivado IP cores. If you're curious about the 
# absence of these individual XDC constraints for each board model, it's due to this 
# encapsulation in the IP cores.

# Instructions:
# -------------
# 1. Copy project files into a working directory.
# 2. Open Vivado GUI and "cd" to this folder in the working directory 
#    using the TCL console.
# 3. Before proceeding, ensure the 'fpdir' variable is set using the 
#    following command in the TCL console:
#    'set fpdir <dir>'
#    This variable should indicate the directory of the FrontPanel 
#    Vivado IP Core.
#    If the IP Core isn't installed, gather more information at:
#    https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/
#    If 'fpdir' isn't set, the script will return an error.
# 4. Set the 'board' variable to the Opal Kelly board for which you'd like
#    to generate the design. Use the command:
#    'set board {your opal kelly board}'
#    e.g., 'set board XEM8320-AU25P'
#    For a list of available boards, refer to "IP CORES` SUPPORTED OPAL KELLY BOARDS":
#    https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/technical-reference/configuration-parameters/
#    If the board specified doesn't match the available Vivado Board Files,
#    the script will return an error.
# 5. Run "source vivado_exdes_builder.tcl"
#
# Example:
# --------
# cd C:/path_to_your_working_directory/
# set fpdir C:/path_to_frontpanel_vivado_ip_core/FrontPanel-Vivado-IP-Dist-version/
# set board XEM8320-AU25P
# source vivado_exdes_builder.tcl
# ========================================================================

if {![info exists fpdir]} {
    puts "\nError: You must set the 'fpdir' variable before running this script."
    puts "Use the command: 'set fpdir <dir>'"
    puts "This variable should point to the FrontPanel Vivado IP Core."
    puts "If it's not installed, learn more at:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-ip-core/"
    return
}

if {![info exists board]} {
    puts "\nError: You must set the 'board' variable before running this script."
    puts "Use the command: 'set board <board>'"
    puts "This variable should be the full name of your Opal Kelly board."
    return
}
# Lowercase the board
set board [string tolower $board]

# Check if the board is in the list
set found 0
set foundBoard none
foreach item [split [get_board_parts] " "] {
    set parts [split $item ":"]
    if {[lindex $parts 1] eq $board} {
        set found 1
        set foundBoard $item
        break
    }
}
if {!$found} {
    puts "\nError: The board identified by the 'board' variable isn't installed."
    puts "Please install the board file. For more information see:"
    puts "https://docs.opalkelly.com/fpsdk/frontpanel-hdl/vivado-board-files/"
    return
}

create_project fp_to_axil_exdes vivado
set_property BOARD_PART $foundBoard [current_project]

set ip_paths {}
lappend ip_paths \
[get_property $fpdir [current_fileset]] \
$fpdir

set_property ip_repo_paths $ip_paths [current_project]
update_ip_catalog -rebuild

create_ip -name proc_sys_reset -vendor xilinx.com -library ip -version 5.0 -module_name proc_sys_reset_0

add_files -norecurse axi_reset_iwrap.v
add_files -norecurse fp_to_axil.v
add_files -norecurse fp_to_axil_iwrap.v

set design_name fp_to_axil_exdes

common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

create_bd_design $design_name

common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
opalkelly.com:ip:frontpanel:*\
opalkelly.com:ip:leds:*\
xilinx.com:ip:axi_gpio:*\
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


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

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
  set host_interface [ create_bd_intf_port -mode Slave -vlnv opalkelly.com:interface:host_interface_rtl:1.0 host_interface ]


  # Create ports

  # Create instance: frontpanel_0, and set properties
  set frontpanel_0 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:frontpanel frontpanel_0 ]
  set_property -dict [list \
    CONFIG.TI.ADDR_0 {0x5f} \
    CONFIG.TI.COUNT {1} \
    CONFIG.WI.ADDR_0 {0x1d} \
    CONFIG.WI.ADDR_1 {0x1e} \
    CONFIG.WI.ADDR_2 {0x1f} \
    CONFIG.WI.ADDR_3 {0x00} \
    CONFIG.WI.COUNT {4} \
    CONFIG.WO.ADDR_0 {0x3e} \
    CONFIG.WO.ADDR_1 {0x3f} \
    CONFIG.WO.COUNT {2} \
    CONFIG.host_interface_BOARD_INTERFACE {host_interface} \
  ] $frontpanel_0


  # Create instance: leds_0, and set properties
  set leds_0 [ create_bd_cell -type ip -vlnv opalkelly.com:ip:leds leds_0 ]

  set driverType [get_property CONFIG.DRIVERTYPE $leds_0]
  if {$driverType == "tristate"} {
    apply_board_connection -board_interface "board_leds" -ip_intf "leds_0/led_out_tristate" -diagram "fp_to_axil_exdes" 
  } else {
    apply_board_connection -board_interface "board_leds" -ip_intf "leds_0/led_out" -diagram "fp_to_axil_exdes" 
  }
  

  set ledWidth [get_property CONFIG.WIDTH $leds_0]

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH $ledWidth \
  ] $axi_gpio_0


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
  
  set_property CONFIG.FREQ_HZ {100800000} [get_bd_pins /fp_to_axil_iwrap_0/aclk]
  set_property CONFIG.CLK_DOMAIN fp_to_axil_exdes_frontpanel_0_0_okClk [get_bd_pins /fp_to_axil_iwrap_0/aclk]
  
  # Create instance: axi_reset_iwrap_0, and set properties
  set block_name axi_reset_iwrap
  set block_cell_name axi_reset_iwrap_0
  if { [catch {set axi_reset_iwrap_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_reset_iwrap_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net fp_to_axil_iwrap_0_m_axil [get_bd_intf_pins fp_to_axil_iwrap_0/m_axil] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net frontpanel_0_triggerin5f [get_bd_intf_pins frontpanel_0/triggerin5f] [get_bd_intf_pins fp_to_axil_iwrap_0/triggerin5f_fp_to_axil_operation]
  connect_bd_intf_net -intf_net frontpanel_0_wirein00 [get_bd_intf_pins axi_reset_iwrap_0/wirein00_axi_reset] [get_bd_intf_pins frontpanel_0/wirein00]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1d [get_bd_intf_pins frontpanel_0/wirein1d] [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1d_fp_to_axil_addr]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1e [get_bd_intf_pins frontpanel_0/wirein1e] [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1e_fp_to_axil_data]
  connect_bd_intf_net -intf_net frontpanel_0_wirein1f [get_bd_intf_pins frontpanel_0/wirein1f] [get_bd_intf_pins fp_to_axil_iwrap_0/wirein1f_fp_to_axil_timeout]
  connect_bd_intf_net -intf_net frontpanel_0_wireout3e [get_bd_intf_pins frontpanel_0/wireout3e] [get_bd_intf_pins fp_to_axil_iwrap_0/wireout3e_fp_to_axil_data]
  connect_bd_intf_net -intf_net frontpanel_0_wireout3f [get_bd_intf_pins frontpanel_0/wireout3f] [get_bd_intf_pins fp_to_axil_iwrap_0/wireout3f_fp_to_axil_status]
  connect_bd_intf_net -intf_net host_interface_1 [get_bd_intf_ports host_interface] [get_bd_intf_pins frontpanel_0/host_interface]
  connect_bd_intf_net -intf_net leds_0_led_out [get_bd_intf_ports board_leds] [get_bd_intf_pins leds_0/led_out]

  # Create port connections
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_pins leds_0/led_in]
  connect_bd_net -net frontpanel_0_okClk [get_bd_pins frontpanel_0/okClk] [get_bd_pins fp_to_axil_iwrap_0/aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_reset_iwrap_0/sync_clk]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_reset_iwrap_0/peripheral_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins fp_to_axil_iwrap_0/aresetn]

  # Create address segments
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces fp_to_axil_iwrap_0/m_axil] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force


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
set wrapperfile [make_wrapper -files [get_files fp_to_axil_exdes.bd] -top -import]
set_property top fp_to_axil_exdes_wrapper [current_fileset]
update_compile_order -fileset sources_1
