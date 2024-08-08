function okCameraLogicReset(dev)
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0008'), hex2dec('0008'));
	okFPUpdateWireIns(dev);
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0000'), hex2dec('0008'));
