function imgdata = okCameraSingleCapture(dev)
	x = 2592;
	y = 1944;
	imglen = x * y * 1;
	imgdata = zeros(imglen, 1, 'uint8');
	
	% PingPong = 0
	okFPSetWireInValue(dev, hex2dec('00'), hex2dec('0010'), hex2dec('ffff'));
	okFPSetWireInValue(dev, hex2dec('02'), bitand(imglen, 65535), hex2dec('ffff'));
	okFPSetWireInValue(dev, hex2dec('03'), floor(imglen / 65536), hex2dec('ffff'));
	okFPSetWireInValue(dev, hex2dec('04'), 0, hex2dec('ffff'));
	okFPSetWireInValue(dev, hex2dec('05'), 0, hex2dec('ffff'));
	okFPUpdateWireIns(dev);

	okFPUpdateTriggerOuts(dev);

	% Capture trigger
	okFPActivateTriggerIn(dev, hex2dec('40'), 0);

	for i=0:100
		okSleepMS(10);
		okFPUpdateTriggerOuts(dev);
		if (1 == okFPIsTriggered(dev, hex2dec('60'), 1))
			disp('Image available')
			break;
		end
	end
	
	if (100 ~= i)
		% Readout start
		okFPActivateTriggerIn(dev, hex2dec('40'), 1);
		
		okFPReadFromPipeOut(dev, hex2dec('a0'), imglen, imgdata);
		
		% Readout done
		okFPActivateTriggerIn(dev, hex2dec('40'), 2);
	else
		disp('Image capture timeout')
	end
