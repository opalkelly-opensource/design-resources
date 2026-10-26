#------------------------------------------------------------------------------
# syzygy_dac_cdc.xdc  --  scoped CDC timing exceptions for the SYZYGY DAC core
#------------------------------------------------------------------------------
# The core spans two asynchronous clock domains:
#     * aclk            AXI-Stream / CSR / SPI control + reset stretcher
#     * dac_sample_clk  DDR sample-output domain
#
# The three single-bit crossings below are synchronized in RTL, so they must be
# excluded from timing.  Without these exceptions the tool times them as related
# clocks whenever the two domains share an ancestor clock, producing failing
# setup/recovery paths in the integrating design (e.g. WNS ~ -0.6 ns on the
# reset-sync async preset).  All object queries are internal to this IP; nothing
# is assumed about the external clock names driving aclk / dac_sample_clk.
#------------------------------------------------------------------------------

# 1) Sample-domain reset synchronizer (syzygy-dac.v: samp_rst_sync).
#    core_reset (aclk domain) asynchronously asserts the flop's set pin;
#    de-assertion is re-synchronized into dac_sample_clk by the 2-FF chain.
#    The recovery/removal check on that async set/clear pin is a false path.
set_false_path -to [get_pins -of_objects \
    [get_cells -hierarchical -filter {NAME =~ *samp_rst_sync_reg*}] \
    -filter {REF_PIN_NAME == PRE || REF_PIN_NAME == CLR}]

# 2) Underflow toggle synchronizer (syzygy-dac.v: uflo_tgl -> uflo_sync).
#    Single-bit toggle crossing dac_sample_clk -> aclk; uflo_sync[0] is the
#    first-stage ASYNC_REG capture flop.  The only timing path from uflo_tgl_reg
#    into the synchronizer bank is the [0] crossing, so this targets exactly the
#    CDC and leaves the same-domain uflo_sync[1]/[2] shift paths timed.
set_false_path \
    -from [get_cells -hierarchical -filter {NAME =~ *uflo_tgl_reg}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *uflo_sync_reg*}]

# 3) Sample-format-applied synchronizer (syzygy-dac.v: fmt_applied -> fmt_sync).
#    Single-bit level crossing aclk -> dac_sample_clk. fmt_applied is sticky and
#    toggles at most once per reset, so the 2-FF synchronizer needs no timing
#    relationship to the source; fmt_sync[0] is the first-stage ASYNC_REG capture
#    flop. Targets only the crossing, leaving the same-domain fmt_sync[1] shift
#    path timed.
set_false_path \
    -from [get_cells -hierarchical -filter {NAME =~ *fmt_applied_reg}] \
    -to   [get_cells -hierarchical -filter {NAME =~ *fmt_sync_reg*}]
