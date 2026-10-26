#------------------------------------------------------------------------------
# syzygy_dac_ooc.xdc  --  out-of-context output timing for the SYZYGY DAC core
#------------------------------------------------------------------------------
# USED_IN: out_of_context (synthesis + implementation of THIS IP only).
#
# Purpose: give the source-synchronous DDR sample bus real slack in the IP's own
# OOC run so it is no longer *statically timed* (Gate G1). The DAC forwards its
# own sample clock, so both the data and its capture clock originate inside this
# IP -- the clock-to-data relationship is fully known here and can be constrained
# without any board knowledge.
#
# WHY OOC-ONLY: dac_data / dac_clk are IP output PORTS. get_ports and the
# create_generated_clock below only resolve while syzygy_dac is the top module
# (its own OOC synth/impl). Once integrated, these ports become internal nets, so
# this file must NOT apply in-context -- package it USED_IN out_of_context, never
# USED_IN synthesis/implementation of the parent. The integrating design still
# owns the real pad-level output constraints (real PACKAGE_PIN, real board skew).
#
# The interface (see syzygy-dac-phy.v):
#   * dac_sample_clk  125 MHz (FREQ_HZ in component.xml) clocks the ODDRE1s.
#   * dac_data[11:0]  DDR: D2=I latched on the rising edge, D1=Q on the falling
#                     edge of dac_sample_clk  -> a transition every ~4 ns.
#   * dac_clk         forwarded by a matched ODDRE1 (D1=1,D2=0), so its edges are
#                     EDGE-ALIGNED with the data transitions. The AD9116 recovers
#                     the data eye from this forwarded clock at the receiver.
#------------------------------------------------------------------------------

# --- Receiver / board timing parameters --------------------------------------
# AD9116 INPUT DATA setup/hold at the pins, from datasheet Rev.F Table 2, the
# DVDDIO = 1.8 V rows (the PHY drives LVCMOS18). Worst case across the two edges:
#   I ch / DCLKIO rising  : tS 0.13 ns, tH 1.1 ns
#   Q ch / DCLKIO falling : tS 0.25 ns, tH 1.2 ns   <- worst, used below
# brd_skew is the integrator's worst-case dac_clk-vs-dac_data trace skew: keep the
# dac_clk and dac_data[*] traces length-matched and retune this for the real board.
set dac_tsu   0.25
set dac_th    1.20
set brd_skew  0.20

set out_max [expr {$dac_tsu + $brd_skew}]
set out_min [expr {-1.0 * ($dac_th + $brd_skew)}]

# --- Sample clock ------------------------------------------------------------
# dac_sample_clk must already be defined when this file is read. The IP packager
# creates it from the bus-interface FREQ_HZ (125 MHz) in the real OOC run; the
# standalone check harness (scratchpad/dac_ooc_harness.xdc) creates it explicitly.
# No create_clock/`if` guard here -- Vivado forbids `if` inside an XDC, and a hard
# create_clock would collide with the packager's FREQ_HZ clock in the real run.

# --- Forwarded output clock --------------------------------------------------
# Generated clock at the dac_clk pad. Source from the dac_sample_clk PORT, NOT the
# forwarding ODDRE1's C pin: synthesis retargets ODDRE1 -> OSERDESE3 (whose clock
# pin is CLK, not C), so a primitive-pin source silently matches nothing. The
# sample clock reaches dac_clk only through that forwarding ODDR, so the port is a
# valid, transform-proof -source. -divide_by 1: dac_clk runs at the sample rate.
create_generated_clock -name dac_clk_fwd \
    -source [get_ports dac_sample_clk] \
    -divide_by 1 \
    [get_ports dac_clk]

# --- DDR data output delays --------------------------------------------------
# Both the rising and the falling capture edge are constrained (-clock_fall
# -add_delay), so each half of the DDR word is timed against the forwarded clock.
# -max models the receiver setup + skew; -min the (negative) hold + skew.
set_output_delay -clock dac_clk_fwd -max $out_max                        [get_ports {dac_data[*]}]
set_output_delay -clock dac_clk_fwd -min $out_min                        [get_ports {dac_data[*]}]
set_output_delay -clock dac_clk_fwd -max $out_max -clock_fall -add_delay [get_ports {dac_data[*]}]
set_output_delay -clock dac_clk_fwd -min $out_min -clock_fall -add_delay [get_ports {dac_data[*]}]

#------------------------------------------------------------------------------
# HOLD: setup closes in the IP's own OOC run, but hold on a source-synchronous
# output is set by dac_clk-vs-dac_data skew at the pads. It closes at INTEGRATION
# (length-matched traces + real pin placement), not in this unplaced OOC run,
# where SCD = 0 makes the hold number a non-physical artifact.
#
# The edge-aligned forwarding is correct for the AD9116 despite the near-zero tS:
# the part latches DB on the DCLKIO edge (I rising / Q falling) via an internal
# retimer + input delays (datasheet Rev.F "Digital Data Latching and Retimer",
# Fig. 94/95). No PHY change is required.
#------------------------------------------------------------------------------
