function okCameraFullReset(dev)
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('000f'), hex2dec('000f'));
	okFPUpdateWireIns(dev);
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0000'), hex2dec('0001'));
	okFPUpdateWireIns(dev);
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0000'), hex2dec('0002'));
	okFPUpdateWireIns(dev);
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0000'), hex2dec('0008'));
	okFPUpdateWireIns(dev);

	% REG_PLL_CONTROL = 0x0051
	okCameraI2CWrite(dev, hex2dec('10'), hex2dec('0051'));

	% For the XEM6010 / EVB1005
	N = 5;
	M = 72;
	P1 = 3;
	% REG_PLL_CONFIG1 = ((N-1)<<0) | (M<<8)
	okCameraI2CWrite(dev, hex2dec('11'), N-1 + M*256);
	% REG_PLL_CONFIG2 = (P1-1)<<0
	okCameraI2CWrite(dev, hex2dec('12'), P1-1);
	
	% Allow sensor PLL to lock
	okSleepMS(1);
	
	% REG_PLL_CONTROL = 0x0053
	okCameraI2CWrite(dev, hex2dec('10'), hex2dec('0053'));
	
	% REG_HORIZONTAL_BLANK = 0x01c2
	okCameraI2CWrite(dev, hex2dec('05'), hex2dec('01c2'));
	
	% REG_OUTPUT_CONTROL = 0x1f8e
	okCameraI2CWrite(dev, hex2dec('07'), hex2dec('1f8e'));

	% Allow FPGA DCM to lock
	okSleepMS(10);
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0000'), hex2dec('0004'));
	okFPUpdateWireIns(dev);

	okCameraLogicReset(dev);
