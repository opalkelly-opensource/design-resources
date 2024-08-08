% Load the FreeMat okFrontPanel library
okfp

% Configure the FPGA
dev = okFPConstruct;
okFPOpenBySerialX(dev, 0);
okCameraInitialize(dev);

% Capture
x=2592;y=1944;
img = okCameraSingleCapture(dev);

% Reshape into a X:Y:3 vector for display
disp('Displaying image')
tmp = zeros(y,x);
tmp = double(reshape(img(1:x*y), x, y)).';
imgv = zeros(y/2, x/2, 3);
imgv(:,:,1) = tmp(1:2:y, 2:2:x)/256; % RED
imgv(:,:,2) = tmp(1:2:y, 1:2:x)/256; % GREEN
imgv(:,:,3) = tmp(2:2:y, 1:2:x)/256; % BLUE
figure(1);
image(imgv(:, 1:1024, :));


okFPDestruct(dev);
disp 'FrontPanel object destroyed.'
