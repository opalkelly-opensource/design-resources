                        


## If the interface timing constraints cannot be met then these can be relaxed by adjusting the values in this
## xdc file which is set to be processed after all other xdc files
## this also allows for the IODELAY tap delay setting to be adjusted without needing to modify the xdc's
## provided with the core
## All commands in this file can be used directly in the tcl command window if the synthesized or implemented design is open.

# The RGMII receive interface requirement allows a 1ns setup and 1ns hold
#set_input_delay -clock [get_clocks {trimac_fifo_block/tri_mode_ethernet_mac_i/U0_rgmii_rx_clk}] -max -1 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks {trimac_fifo_block/tri_mode_ethernet_mac_i/U0_rgmii_rx_clk}] -min -3 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks {trimac_fifo_block/tri_mode_ethernet_mac_i/U0_rgmii_rx_clk}] -clock_fall -max -1 -add_delay [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
#set_input_delay -clock [get_clocks {trimac_fifo_block/tri_mode_ethernet_mac_i/U0_rgmii_rx_clk}] -clock_fall -min -3 -add_delay [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
# the following properties can be adjusted if required to adjust the 2ns skew on txc w.r.t txd
# DELAY_VALUE is the time represenatation of the desired delay in ps
#set_property DELAY_VALUE 1000 [get_cells {trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk}]
#set_property DELAY_VALUE 1000 [get_cells {trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_tx_clk_casc}]

# the following properties can be adjusted if requried to adjuct the IO timing
# the value shown is the default used by the IP
# increasing this value will improve the hold timing but will also add jitter.
#set_property DELAY_VALUE 500  [get_cells {trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/delay_rgmii_rx* trimac_fifo_block/tri_mode_ethernet_mac_i/*/tri_mode_ethernet_mac_i/rgmii_interface/rxdata_bus[*].delay_rgmii_rx*}]

