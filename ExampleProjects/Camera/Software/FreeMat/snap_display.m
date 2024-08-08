y = 2592;
z = 1944;
x = rawread('output', [1,y*z], 'uint8', 'be');
xx = double(reshape(x, y, z))';
xc = zeros(z/2, y/2, 3);
xc(:,:,1) = xx(1:2:z, 2:2:y) / 256; % RED
xc(:,:,2) = xx(1:2:z, 1:2:y) / 256; % GREEN
xc(:,:,3) = xx(2:2:z, 1:2:y) / 256; % BLUE
figure(1);image(xc);
