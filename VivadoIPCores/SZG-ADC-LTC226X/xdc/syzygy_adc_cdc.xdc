#------------------------------------------------------------------------------
# syzygy_adc_cdc.xdc  --  scoped CDC timing exceptions for the SYZYGY ADC core
#------------------------------------------------------------------------------
# Scoped to each instance (SCOPED_TO_REF), processing_order = late so all clocks
# are defined before it runs.
#
# Two asynchronous clock domains:
#     * aclk          AXI-Stream / AXI4-Lite CSR / SPI control + reset stretcher
#     * adc_data_clk  DCO/4 capture domain (BUFGCE_DIV, sourced from the pod)
#
# Every crossing below is synchronized in RTL (ASYNC_REG chains, a reset
# synchronizer, or a toggle handshake). All object queries are internal to this
# IP; nothing is assumed about the external clock names.
#
# Bus crossings use set_bus_skew rather than set_max_delay -datapath_only:
# set_bus_skew is still analysed when the integrator declares the clocks
# asynchronous with set_clock_groups.
#------------------------------------------------------------------------------

# --- 1) Reset synchronizer: async assert, sync release ------------------------
# reset_async (aclk domain) asynchronously asserts the PRE/CLR pins of flops
# clocked by adc_data_clk. Release is resynchronized in RTL, so the
# recovery/removal checks on those async pins are false paths.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *reset_adc_sync_reg*}] \
    -filter {REF_PIN_NAME == PRE || REF_PIN_NAME == CLR}]

# --- 2) Capture-clock health monitor: adc_data_clk -> aclk --------------------
# dco_tgl free-runs in the capture domain; a 3-FF chain in aclk edge-detects it to
# decide whether adc_data_clk is alive (STATUS[1]). Only the [0] stage is the
# crossing. The monitor has no reset, so there is no PRE/CLR path.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *dco_tgl_sync_reg[0]}] \
    -filter {REF_PIN_NAME == D}]

# --- 3) Status levels: adc_data_clk -> aclk (2-FF synchronizers) --------------
# data_rdy / align_done / align_fail. Only the [0] stage is the crossing; the [1]
# stage is a same-domain shift and stays timed.
set_false_path -to [get_pins -of_objects [get_cells -hierarchical -filter { \
        NAME =~ *rdy_sync_reg[0]  || \
        NAME =~ *done_sync_reg[0] || \
        NAME =~ *fail_sync_reg[0]}] \
    -filter {REF_PIN_NAME == D}]

# --- 4) FIFO-overflow toggle handshake: adc_data_clk -> aclk ------------------
# ovf_tgl flips on each dropped sample; a 3-FF chain in aclk edge-detects it.
set_false_path \
    -from [get_cells -hierarchical -filter {NAME =~ *ovf_tgl_reg}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *ovf_tgl_sync_reg*}]

# --- 5) Frame-error toggle handshake: adc_data_clk -> aclk --------------------
# frame_err_tgl flips on each post-alignment frame-word mismatch; a 3-FF chain in
# aclk edge-detects it to set the sticky STATUS[7].
set_false_path \
    -from [get_cells -hierarchical -filter {NAME =~ *frame_err_tgl_reg}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *frame_err_tgl_sync_reg*}]

# --- 6) Status snapshot: adc_data_clk -> aclk ---------------------------------
# ALIGN, both live taps and the tracker telemetry cross as one 101-bit bundle:
# snap_hold is reloaded every 16 adc_data_clk cycles and snap_tgl flips; snap_tgl
# enters a 3-FF synchronizer and aclk samples snap_hold on its edge, while
# snap_hold is stable for 16 adc_data_clk cycles.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *snap_tgl_sync_reg[0]}] \
    -filter {REF_PIN_NAME == D}]
set_bus_skew \
    -from [get_cells -hierarchical -filter {NAME =~ *snap_hold_reg*}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *snap_cap_reg*}] 8.000

# --- 7) Eye map: adc_data_clk -> aclk -----------------------------------------
# Quasi-static: the sweep's per-tap map is frozen in both S_DONE and S_FAIL and
# captured in aclk while either synced flag is high.
set_bus_skew \
    -from [get_cells -hierarchical -filter {NAME =~ *adc_align_impl/good_reg*}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *eye_map_cap_reg*}] 8.000

# --- 8) Tap override ----------------------------------------------------------
# Request {en, tap}, aclk -> adc_data_clk: two synchronizer stages, then taken
# only when two consecutive samples agree. Coherent while the 10 bits arrive
# within one adc_data_clk period, so the skew is bounded well under the -14's
# 8 ns period.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *ovr_req_meta_reg*}] \
    -filter {REF_PIN_NAME == D}]
set_bus_skew \
    -from [get_cells -hierarchical -filter {NAME =~ *reg_ovr_en_reg || NAME =~ *reg_ovr_tap_reg*}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *ovr_req_meta_reg*}] 4.000

# override_active, adc_data_clk -> aclk: single-bit level, 2-FF synchronizer.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *ovr_act_sync_reg[0]}] \
    -filter {REF_PIN_NAME == D}]

# --- 9) Tracking controls -----------------------------------------------------
# TRACK_CTRL {en, deadband, offset, interval}, aclk -> adc_data_clk: double-
# sampled exactly like the override request in (8).
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *trk_req_meta_reg*}] \
    -filter {REF_PIN_NAME == D}]
set_bus_skew \
    -from [get_cells -hierarchical -filter {NAME =~ *reg_trk_en_reg || NAME =~ *reg_trk_deadband_reg* || NAME =~ *reg_trk_offset_reg* || NAME =~ *reg_trk_interval_reg*}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *trk_req_meta_reg*}] 4.000
