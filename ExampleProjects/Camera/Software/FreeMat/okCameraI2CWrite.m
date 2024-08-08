function okCameraI2CWrite(dev, addr, data)
	okFPActivateTriggerIn(dev, hex2dec('42'), 1);

	% Num of data words
	okFPSetWireInValue(dev, hex2dec('01'), hex2dec('0030'), hex2dec('00ff'));
	okFPUpdateWireIns(dev);
	okFPActivateTriggerIn(dev, hex2dec('42'), 2);

	% Device address
	okFPSetWireInValue(dev, hex2dec('01'), hex2dec('00ba'), hex2dec('00ff'));
	okFPUpdateWireIns(dev);
	okFPActivateTriggerIn(dev, hex2dec('42'), 2);

	% Register address
	okFPSetWireInValue(dev, hex2dec('01'), addr, hex2dec('00ff'));
	okFPUpdateWireIns(dev);
	okFPActivateTriggerIn(dev, hex2dec('42'), 2);

	% Data 0 MSB
	okFPSetWireInValue(dev, hex2dec('01'), floor(data/256), hex2dec('00ff'));
	okFPUpdateWireIns(dev);
	okFPActivateTriggerIn(dev, hex2dec('42'), 2);

	% Data 1 MSB
	okFPSetWireInValue(dev, hex2dec('01'), data, hex2dec('00ff'));
	okFPUpdateWireIns(dev);
	okFPActivateTriggerIn(dev, hex2dec('42'), 2);

	% Start I2C transaction
	okFPActivateTriggerIn(dev, hex2dec('42'), 0);

	okFPUpdateTriggerOuts(dev);
	while (0 == okFPIsTriggered(dev, hex2dec('61'), 1))
		okSleepMS(1);
		okFPUpdateTriggerOuts(dev);
	end
