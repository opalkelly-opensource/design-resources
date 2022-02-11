// Audio Pipe - Transfer audio data to the XEM7320 signal generator 
// sample through a FrontPanel Pipe endpoint.
//------------------------------------------------------------------------
// Copyright (c) 2014-2018 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
//------------------------------------------------------------------------

#include <AudioPipe.h>

#include <algorithm>
#include <bitset>
#include <climits>
#include <fstream>
#include <iostream>
#include <map>
#include <getopt.h>
#include <okFrontPanelDLL.h>
#include <sndfile.h>
#include <stdint.h>
#include <math.h>

#include "AudioFile.h"

#define SINE_SAMPLE_RATE 44100 // Hz

#define FPGA_CLK_FREQ 100800000 // Hz

#define GENERAL_EP 0x00
#define FREQ_EP 0x01
#define AM_DEPTH_EP 0x02
#define MOD_TYPE_EP 0x03
#define FDEV_EP 0x04
#define RD_EN_EP 0x05

#define DEPTH_MAX 0xFF
#define FDEV_MAX 0xFFFF
#define FREQ_MAX 0x2625A00

#define FREQ_PRESCALE_CONST 1.33152507936
#define FDEV_PRESCALE_CONST ((2 - 0.9765625) * 0.5 * (FREQ_PRESCALE_CONST))

#define FIFO_EP 0x80

#define BOUND(x, max) ((x) = ((x) > (max)) ? (max) : (x))

struct Config {
uint32_t freq, depth, deviation, mod_type;
double sine_freq;
bool genSine;
std::string filename, bitfilename, mod_type_str;
};

int main(int argc, char* argv[]) {
	int r, *samplebuf;
	unsigned int *ubuf;
	Config m_config;
	SF_INFO fileInfo;
	SNDFILE *file;
	AudioFile *audioFile;
	OpalKelly::FrontPanelDevices fpDevs;
	OpalKelly::FrontPanelPtr dev;

	r = handleArgs(argc, argv, &m_config);
	if (r < 0) {
		std::cout << "Argument handling failed." << std::endl;
		return r;
	}

	if (!m_config.genSine) {
		if (m_config.filename.length() == 0) {
			std::cout << "No filename given." << std::endl;
			return -2;
		}

		audioFile = new AudioFile(m_config.filename);
		if (!audioFile->getFile()) {
			std::cout << "Couldn't read file!" << std::endl;
			return -1;
		}

		file = audioFile->getFile();
		fileInfo = audioFile->getInfo();
	}

	dev = fpDevs.Open();
	if (!dev) {
		std::cout << "Couldn't open device!" << std::endl;
		return -1;
	}

	if (m_config.bitfilename.length() != 0) {
		r = dev->ConfigureFPGA(m_config.bitfilename);
		if (r < 0) {
			std::cout << "Couldn't configure FPGA with given bitfile!" << std::endl;
			return -1;
		}
	}

	dev->LoadDefaultPLLConfiguration();

	// General
	dev->SetWireInValue(GENERAL_EP, 16);
	// Set sample rate counter max
	if (m_config.genSine) {
		dev->SetWireInValue(RD_EN_EP, static_cast<int>(FPGA_CLK_FREQ / SINE_SAMPLE_RATE));
	} else {
		dev->SetWireInValue(RD_EN_EP, static_cast<int>(FPGA_CLK_FREQ / fileInfo.samplerate));
	}
	// Modulation Type
	dev->SetWireInValue(MOD_TYPE_EP, m_config.mod_type);
	// Frequency
	dev->SetWireInValue(FREQ_EP, static_cast<int32_t>(m_config.freq * FREQ_PRESCALE_CONST + 0.5f));
	// AM Depth
	dev->SetWireInValue(AM_DEPTH_EP, m_config.depth);
	// FM Frequency Deviation
	dev->SetWireInValue(FDEV_EP, static_cast<int32_t>(m_config.deviation * FDEV_PRESCALE_CONST + 0.5f));

	dev->UpdateWireIns(); 

	std::cout << "Beginning transfer..." << std::endl;
	std::cout << "Frequency: " << m_config.freq << std::endl;
	std::cout << "Modulation type: " << m_config.mod_type_str << std::endl;

	// AM or AMFM
	if (m_config.mod_type_str.find("am") != std::string::npos) {
		std::cout << "Depth: " << m_config.depth << std::endl;
	}

	// FM or AMFM
	if (m_config.mod_type_str.find("fm") != std::string::npos) {
		std::cout << "Frequency Deviation: " << m_config.deviation << std::endl;
	}

	size_t buf_size, padded_buf_size;

	// File reading
	if (!m_config.genSine) {
		buf_size = 2 * fileInfo.frames * sizeof(int);

		// Pad to a block length
		padded_buf_size = buf_size + 1024 - (buf_size % 1024);

		samplebuf = static_cast<int*>(malloc(padded_buf_size));
		if (samplebuf == nullptr) {
			std::cout << "Failed to malloc samplebuf!" << std::endl;
			return -1;
		}
		ubuf = static_cast<unsigned int*>(malloc(padded_buf_size));
		if (ubuf == nullptr) {
			std::cout << "Failed to malloc ubuf!" << std::endl;
			return -1;
		}

		readIntoBuffer(file, samplebuf, fileInfo.frames);

		for (size_t i = 0; i < (padded_buf_size / sizeof(int)); i++) {
			// Convert samples to unsigned
			ubuf[i] = static_cast<unsigned int>(samplebuf[i]) + INT_MAX;
		}

		free(samplebuf);
	} else {
		buf_size = 2 * SINE_SAMPLE_RATE * 10 * sizeof(int);

		// Pad to a block length
		padded_buf_size = buf_size + 1024 - (buf_size % 1024);

		ubuf = static_cast<unsigned int*>(malloc(padded_buf_size));
		if (ubuf == nullptr) {
			std::cout << "Failed to malloc ubuf!" << std::endl;
			return -1;
		}

		generateSine(m_config.sine_freq, INT_MAX, 10, ubuf);
	}

	r = dev->WriteToBlockPipeIn(FIFO_EP, 1024, padded_buf_size, reinterpret_cast<uint8_t*>(ubuf));
	if (r < 0) {
		std::cout << "Pipe write failed with: " << dev->GetErrorString(r) << std::endl;
		return r;
	}

	// Cleanup //

	free(ubuf);

	for (size_t i = 0x0; i <= FDEV_EP; i++) {
		dev->SetWireInValue(i, 0x00);
	}

	dev->UpdateWireIns();
	dev->Close();

	delete audioFile;

	return 0;
}

int handleArgs(int argc, char *argv[], Config *config) {
	static struct option long_options[] = {
		{"bitfile", required_argument, 0, 'b'},
		{"sine", required_argument, 0, 's'},
		{"file", required_argument, 0, 'f'},
		{"frequency", required_argument, 0, 'h'},
		{"modulation", required_argument, 0, 'm'},
		{"depth", required_argument, 0, 'a'},
		{"deviation", required_argument, 0, 'd'},
		{0, 0, 0, 0}
	};

	std::map<std::string, int32_t> mod_type_map = {{"fm", 1}, {"am", 2}, {"amfm", 3}};
	int option_index, c;
	option_index = 0;

	while ((c = getopt_long(argc, argv, "b:s:f:h:m:a:d:", long_options, &option_index)) != -1) {
		switch (c) {
			case 'b':
				config->bitfilename = optarg;
				break;

			case 's':
				config->genSine = true;
				config->sine_freq = atof(optarg); 
				break;

			case 'f':
				config->genSine = false;
				config->filename = static_cast<std::string>(optarg);
				break;

			case 'h':
				if (allDigits(optarg)) {
					config->freq = atoi(optarg);
				} else {
					std::cout << "Frequency must be an unsigned integer." << std::endl;
					return -2;
				}
				BOUND(config->freq, FREQ_MAX);
				break;

			case 'm': {
					  config->mod_type_str = static_cast<std::string>(optarg);
					  config->mod_type = mod_type_map[optarg];

					  if (!config->mod_type) {
						  printf("Unknown option '%s' given to -m\n", optarg);
						  return -2;
					  }

					  break;
				  }

			case 'a':
				  if (allDigits(optarg)) {
					  config->depth = atoi(optarg);
				  } else {
					  std::cout << "Depth must be an unsigned integer." << std::endl;
					  return -2;
				  }
				  BOUND(config->depth, DEPTH_MAX);
				  break;

			case 'd':
				  if (allDigits(optarg)) {
					  config->deviation = atoi(optarg);
				  } else {
					  std::cout << "Deviation must be an unsigned integer." << std::endl;
					  return -2;
				  }
				  BOUND(config->deviation, FDEV_MAX);
				  break;

			case '?':
				  return -2;

			default:
				  abort();
				  break;
		}
	}

	for (option_index = optind; option_index < argc; option_index++) {
		printf("Unknown argument %s\n", argv[option_index]);
		return -2;
	}

	return 0;
}

int readIntoBuffer(SNDFILE *sndFile, int *buffer, int len) {
	int r;

	r = sf_readf_int(sndFile, buffer, static_cast<sf_count_t>(len));

	if (r != len) {
		return -1;
	} else {
		return 0;
	}
}

bool allDigits(const std::string &str) {
	return std::all_of(str.begin(), str.end(), ::isdigit);
}

void generateSine(double freq, int32_t volume, int32_t seconds, unsigned int* buffer) {
	const int32_t samples_per_second = SINE_SAMPLE_RATE;
	const uint32_t num_samples = samples_per_second * seconds * 2;

	for (uint32_t i = 0; i < num_samples; i++) {
		double t = static_cast<double>(i) / samples_per_second;

		buffer[i] = static_cast<unsigned int>(volume * sin(freq * t * M_PI) + INT_MAX);
	}
}
