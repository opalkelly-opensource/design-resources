function okCameraInitialize(dev)
	okFPLoadDefaultPLLConfiguration(dev);
	brd = okFPGetBoardModel(dev);
	if (brd == 13)
		okFPConfigureFPGA(dev, 'evb1005-xem6010-lx45.bit');
	elseif (brd == 17)
		okFPConfigureFPGA(dev, 'evb1006-xem6006-lx16.bit');
	else
		disp('Unrecognized Opal Kelly module.');
	end

	% Reset
	okCameraFullReset(dev);
