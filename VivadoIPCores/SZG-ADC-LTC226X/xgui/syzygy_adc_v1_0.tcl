
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/syzygy_adc_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "CTRL_INTERFACE"
  ipgui::add_param $IPINST -name "ADC_VARIANT"
  set ALIGN_MODE [ipgui::add_param $IPINST -name "ALIGN_MODE"]
  set_property tooltip {Determine whether to align with the ADC frame phase once or continually throughout the run.} ${ALIGN_MODE}
  set FIFO_DEPTH [ipgui::add_param $IPINST -name "FIFO_DEPTH" -widget comboBox]
  set_property tooltip {Sets the depth of the ADC FIFO to the host. Determines how long the host can stall before losing data.} ${FIFO_DEPTH}

}

proc update_PARAM_VALUE.ALIGN_MODE { PARAM_VALUE.ALIGN_MODE PARAM_VALUE.ADC_VARIANT } {
	# Procedure called to update ALIGN_MODE when any of the dependent parameters in the arguments change
	
	set ALIGN_MODE ${PARAM_VALUE.ALIGN_MODE}
	set ADC_VARIANT ${PARAM_VALUE.ADC_VARIANT}
	set values(ADC_VARIANT) [get_property value $ADC_VARIANT]
	if { [gen_USERPARAMETER_ALIGN_MODE_ENABLEMENT $values(ADC_VARIANT)] } {
		set_property enabled true $ALIGN_MODE
	} else {
		set_property enabled false $ALIGN_MODE
	}
}

proc validate_PARAM_VALUE.ALIGN_MODE { PARAM_VALUE.ALIGN_MODE } {
	# Procedure called to validate ALIGN_MODE
	return true
}

proc update_PARAM_VALUE.ADC_VARIANT { PARAM_VALUE.ADC_VARIANT } {
	# Procedure called to update ADC_VARIANT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_VARIANT { PARAM_VALUE.ADC_VARIANT } {
	# Procedure called to validate ADC_VARIANT
	return true
}

proc update_PARAM_VALUE.CTRL_INTERFACE { PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to update CTRL_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CTRL_INTERFACE { PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to validate CTRL_INTERFACE
	return true
}

proc update_PARAM_VALUE.C_M_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_M_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_M_AXIS_TDATA_WIDTH
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

proc update_PARAM_VALUE.szg_adc_BOARD_INTERFACE { PARAM_VALUE.szg_adc_BOARD_INTERFACE } {
	# Procedure called to update szg_adc_BOARD_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.szg_adc_BOARD_INTERFACE { PARAM_VALUE.szg_adc_BOARD_INTERFACE } {
	# Procedure called to validate szg_adc_BOARD_INTERFACE
	return true
}


proc update_MODELPARAM_VALUE.ADC_VARIANT { MODELPARAM_VALUE.ADC_VARIANT PARAM_VALUE.ADC_VARIANT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_VARIANT}] ${MODELPARAM_VALUE.ADC_VARIANT}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.C_M_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_M_AXIS_TDATA_WIDTH PARAM_VALUE.C_M_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CTRL_INTERFACE { MODELPARAM_VALUE.CTRL_INTERFACE PARAM_VALUE.CTRL_INTERFACE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CTRL_INTERFACE}] ${MODELPARAM_VALUE.CTRL_INTERFACE}
}

proc update_MODELPARAM_VALUE.ALIGN_MODE { MODELPARAM_VALUE.ALIGN_MODE PARAM_VALUE.ALIGN_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ALIGN_MODE}] ${MODELPARAM_VALUE.ALIGN_MODE}
}

