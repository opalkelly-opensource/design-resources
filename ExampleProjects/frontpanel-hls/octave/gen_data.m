% Simple example to generate data for the FIR filter HLS demo from Opal Kelly
%
% Copyright (c) 2018 Opal Kelly Incorporated

coef = [ 0.042153588198237606,
	0.09254487085124112,
	0.08627292857696542,
	-0.0066099899662500515,
	-0.09647274861311855,
	-0.03655279492291376,
	0.1889147108950072,
	0.4024647831036765,
	0.4024647831036765,
	0.1889147108950072,
	-0.03655279492291376,
	-0.09647274861311855,
	-0.0066099899662500515,
	0.08627292857696542,
	0.09254487085124112,
	0.042153588198237606
	];

SAMP_RATE_Hz = 44100;
TIME_s = 10;

SWEEP_START_Hz = 200;
SWEEP_END_Hz   = 22000;

t = 0:(SAMP_RATE_Hz*TIME_s)-1;

f = linspace(SWEEP_START_Hz, SWEEP_END_Hz, length(t));

input_waveform = (sin(pi * (f .* t) / (SAMP_RATE_Hz)));

output_waveform = filter(coef, 1, input_waveform);

%specgram(input_waveform, 256, SAMP_RATE_Hz);

input_data = input_waveform';

output_data = output_waveform';

save "input.dat" input_data;
save "output.dat" output_data;

