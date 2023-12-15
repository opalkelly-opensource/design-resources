# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

# ================================= XEM8320 SYZYGY PORT E ================================
# Info: The following constraints all route to SYZYGY Port E on the XEM8320. 
# From SYZYGY Port E, signals route on the SZG-DisplayPort as documented 
# in the Pinout section of https://docs.opalkelly.com/szg-displayport/.
# It's essential that the SZG-DisplayPort is connected to SYZYGY Port E for correct functionality.

# -------------------------- DISPLAYPORT RX --------------------------
set_property PACKAGE_PIN AF2 [get_ports {lnk_rx_lane_p[0]}]
set_property PACKAGE_PIN AE4 [get_ports {lnk_rx_lane_p[1]}]
set_property PACKAGE_PIN AD2 [get_ports {lnk_rx_lane_p[2]}]
set_property PACKAGE_PIN AB2 [get_ports {lnk_rx_lane_p[3]}]

set_property PACKAGE_PIN H11 [get_ports {rx_hpd[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rx_hpd[0]}]

set_property PACKAGE_PIN G9 [get_ports aux_rx_data_out_0]
set_property PACKAGE_PIN G10 [get_ports aux_rx_data_in_0]
set_property PACKAGE_PIN G11 [get_ports {aux_rx_data_en_out_n_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports aux_rx_data_out_0]
set_property IOSTANDARD LVCMOS18 [get_ports aux_rx_data_in_0]
set_property IOSTANDARD LVCMOS18 [get_ports {aux_rx_data_en_out_n_0[0]}]

# -------------------------- DISPLAYPORT TX --------------------------
set_property PACKAGE_PIN AF7 [get_ports {phy_txp_out[0]}]
set_property PACKAGE_PIN AE9 [get_ports {phy_txp_out[1]}]
set_property PACKAGE_PIN AD7 [get_ports {phy_txp_out[2]}]
set_property PACKAGE_PIN AC5 [get_ports {phy_txp_out[3]}]

set_property PACKAGE_PIN J10 [get_ports tx_hpd]
set_property IOSTANDARD LVCMOS18 [get_ports tx_hpd]

set_property PACKAGE_PIN J11 [get_ports aux_tx_data_out_0]
set_property PACKAGE_PIN K10 [get_ports aux_tx_data_in_0]
set_property PACKAGE_PIN K9 [get_ports {aux_tx_data_en_out_n_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports aux_tx_data_out_0]
set_property IOSTANDARD LVCMOS18 [get_ports aux_tx_data_in_0]
set_property IOSTANDARD LVCMOS18 [get_ports {aux_tx_data_en_out_n_0[0]}]

# ------------------- TRANSCIEVER REFERENCE CLOCKS -------------------
set_property PACKAGE_PIN AB6 [get_ports mgtrefclk0_pad_n_in]
set_property PACKAGE_PIN AB7 [get_ports mgtrefclk0_pad_p_in]

set_property PACKAGE_PIN Y6 [get_ports mgtrefclk1_pad_n_in]
set_property PACKAGE_PIN Y7 [get_ports mgtrefclk1_pad_p_in]


# -------------------------------- I2C -------------------------------
set_property PACKAGE_PIN J9 [get_ports ext_iic_0_scl_io]
set_property PACKAGE_PIN H9 [get_ports ext_iic_0_sda_io]
set_property IOSTANDARD LVCMOS18 [get_ports ext_iic_0_scl_io]
set_property IOSTANDARD LVCMOS18 [get_ports ext_iic_0_sda_io]

# =============================== XEM8320 SYZYGY PORT E End ===============================

# ------------------------------ TIMING ------------------------------
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets dpex8320_i/memory_subsystem/ddr4_0/inst/u_ddr4_infrastructure/addn_ui_clkout1]

set_property USER_CLUSTER uc_1 [get_cells dpex8320_i/DP_RX_hier/v_dp_rxss1_0/*/dp/inst/core_top_inst/dport_link_inst/displayport_v8_*_rx_link_inst/displayport_v8_*_rx_main_inst/displayport_v8_*_rx_lane0_inst]
set_property USER_CLUSTER uc_1 [get_cells dpex8320_i/DP_RX_hier/v_dp_rxss1_0/*/dp/inst/core_top_inst/dport_link_inst/displayport_v8_*_rx_link_inst/displayport_v8_*_rx_main_inst/gen_lane_gr_than_2.displayport_v8_*_rx_lane2_inst]
set_property CLOCK_DELAY_GROUP RQSGroupOptimized0 [get_nets dpex8320_i/memory_subsystem/ddr4_0/inst/u_ddr4_infrastructure/addn_ui_clkout1]
set_property CLOCK_DELAY_GROUP RQSGroupOptimized0 [get_nets dpex8320_i/memory_subsystem/ddr4_0/inst/u_ddr4_infrastructure/c0_riu_clk]
set_property CLOCK_DELAY_GROUP RQSGroupOptimized0 [get_nets dpex8320_i/memory_subsystem/ddr4_0/inst/u_ddr4_infrastructure/u_bufg_divClk_0]

# ------------------------- TIMING EXCEPTIONS ------------------------
set_false_path -from [get_pins dpex8320_i/DP_RX_hier/v_dp_rxss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_rx_link_inst/displayport_v8_1_6_rx_syncgate_inst/i_syncgate_reg/C] -to [get_pins {dpex8320_i/DP_RX_hier/v_dp_rxss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_rx_link_inst/displayport_v8_1_6_rx_aux_inst/displayport_v8_1_6_rx_apb_inst/cfg_rx_regs_reg[24]/D}]
set_false_path -from [get_pins {dpex8320_i/DP_TX_hier/v_dp_txss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_tx_link_inst/displayport_v8_1_6_tx_aux_inst/displayport_v8_1_6_tx_apb_inst/cfg_tx_regs_reg[60]/C}] -to [get_pins dpex8320_i/DP_TX_hier/v_dp_txss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_tx_link_inst/displayport_v8_1_6_tx_syncgate_inst/i_first_frame_active_reg/D]
set_false_path -from [get_pins {dpex8320_i/DP_RX_hier/v_dp_rxss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_rx_link_inst/displayport_v8_1_6_rx_aux_inst/displayport_v8_1_6_rx_apb_inst/cfg_rx_regs_reg[24]/C}] -to [get_pins dpex8320_i/DP_RX_hier/v_dp_rxss1_0/inst/dp/inst/core_top_inst/dport_link_inst/displayport_v8_1_6_rx_link_inst/displayport_v8_1_6_rx_syncgate_inst/i_first_frame_active_reg/D]
set_false_path -from [get_pins {dpex8320_i/frontpanel_0/inst/ti41/eptrig_reg[0]/C}] -to [get_pins {dpex8320_i/frontpanel_0/inst/ti41/trigff0_reg[0]/D}]
