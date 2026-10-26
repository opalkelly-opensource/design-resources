# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "CTRL_INTERFACE"
  ipgui::add_param $IPINST -name "DAC_SAMPLE_FORMAT"
  #Adding Group
  set Advanced [ipgui::add_group $IPINST -name "Advanced"]
  set FIFO_DEPTH [ipgui::add_param $IPINST -name "FIFO_DEPTH" -parent ${Advanced} -widget comboBox]
  set_property tooltip {Depth of the internal async FIFO crossing aclk -> dac_sample_clk. A small CDC elastic buffer only -- the waveform is stored upstream, not here. Built from distributed RAM, so deep settings cost LUTRAM: 32 is the intended value.} ${FIFO_DEPTH}
  set DAC_FSADJ_I [ipgui::add_param $IPINST -name "DAC_FSADJ_I" -parent ${Advanced}]
  set_property tooltip {AD911x channel I full-scale (IRSET)} ${DAC_FSADJ_I}
  set DAC_FSADJ_Q [ipgui::add_param $IPINST -name "DAC_FSADJ_Q" -parent ${Advanced}]
  set_property tooltip {AD911x channel Q full-scale (QRSET)} ${DAC_FSADJ_Q}
  ipgui::add_param $IPINST -name "DAC_RESET_VALUE" -parent ${Advanced}


}

proc update_PARAM_VALUE.CTRL_INTERFACE { PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to update CTRL_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CTRL_INTERFACE { PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to validate CTRL_INTERFACE
	return true
}

proc update_PARAM_VALUE.DAC_FSADJ_I { PARAM_VALUE.DAC_FSADJ_I } {
	# Procedure called to update DAC_FSADJ_I when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DAC_FSADJ_I { PARAM_VALUE.DAC_FSADJ_I } {
	# Procedure called to validate DAC_FSADJ_I
	return true
}

proc update_PARAM_VALUE.DAC_FSADJ_Q { PARAM_VALUE.DAC_FSADJ_Q } {
	# Procedure called to update DAC_FSADJ_Q when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DAC_FSADJ_Q { PARAM_VALUE.DAC_FSADJ_Q } {
	# Procedure called to validate DAC_FSADJ_Q
	return true
}

proc update_PARAM_VALUE.DAC_RESET_VALUE { PARAM_VALUE.DAC_RESET_VALUE } {
	# Procedure called to update DAC_RESET_VALUE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DAC_RESET_VALUE { PARAM_VALUE.DAC_RESET_VALUE } {
	# Procedure called to validate DAC_RESET_VALUE
	return true
}

proc update_PARAM_VALUE.DAC_SAMPLE_FORMAT { PARAM_VALUE.DAC_SAMPLE_FORMAT } {
	# Procedure called to update DAC_SAMPLE_FORMAT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DAC_SAMPLE_FORMAT { PARAM_VALUE.DAC_SAMPLE_FORMAT } {
	# Procedure called to validate DAC_SAMPLE_FORMAT
	return true
}

proc update_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to update FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to validate FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.USE_BOARD_FLOW { PARAM_VALUE.USE_BOARD_FLOW } {
	# Procedure called to update USE_BOARD_FLOW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USE_BOARD_FLOW { PARAM_VALUE.USE_BOARD_FLOW } {
	# Procedure called to validate USE_BOARD_FLOW
	return true
}

proc update_PARAM_VALUE.szg_dac_BOARD_INTERFACE { PARAM_VALUE.szg_dac_BOARD_INTERFACE } {
	# Procedure called to update szg_dac_BOARD_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.szg_dac_BOARD_INTERFACE { PARAM_VALUE.szg_dac_BOARD_INTERFACE } {
	# Procedure called to validate szg_dac_BOARD_INTERFACE
	return true
}


proc update_MODELPARAM_VALUE.DAC_FSADJ_I { MODELPARAM_VALUE.DAC_FSADJ_I PARAM_VALUE.DAC_FSADJ_I } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DAC_FSADJ_I}] ${MODELPARAM_VALUE.DAC_FSADJ_I}
}

proc update_MODELPARAM_VALUE.DAC_FSADJ_Q { MODELPARAM_VALUE.DAC_FSADJ_Q PARAM_VALUE.DAC_FSADJ_Q } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DAC_FSADJ_Q}] ${MODELPARAM_VALUE.DAC_FSADJ_Q}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.CTRL_INTERFACE { MODELPARAM_VALUE.CTRL_INTERFACE PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CTRL_INTERFACE}] ${MODELPARAM_VALUE.CTRL_INTERFACE}
}

proc update_MODELPARAM_VALUE.DAC_SAMPLE_FORMAT { MODELPARAM_VALUE.DAC_SAMPLE_FORMAT PARAM_VALUE.DAC_SAMPLE_FORMAT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DAC_SAMPLE_FORMAT}] ${MODELPARAM_VALUE.DAC_SAMPLE_FORMAT}
}

proc update_MODELPARAM_VALUE.DAC_RESET_VALUE { MODELPARAM_VALUE.DAC_RESET_VALUE PARAM_VALUE.DAC_RESET_VALUE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DAC_RESET_VALUE}] ${MODELPARAM_VALUE.DAC_RESET_VALUE}
}

