// SYZYGY ECM1900 SmartVIO controller software
//
//
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

#include "json.hpp"

#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <argp.h>
#include <fcntl.h>
#include <getopt.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

#define SUPPLY_87_88 1
#define SUPPLY_68 2
#define SUPPLY_67 3
#define SUPPLY_28 4

#define PCAL_ADDR 0x20

#define PCAL_OUTPUT_PORT0_REG 0x02
#define PCAL_CONFIG_PORT0_REG 0x06


extern "C" {
#include "syzygy.h"
}

using json = nlohmann::json;

#define I2C_CHECK_COUNT 2000



szgSmartVIOConfig svio = {
	SVIO_NUM_PORTS, SVIO_NUM_GROUPS, {0,0,0,0}, {0x1, 0x2, 0x4, 0x8}, { 
		{
			// Group 1(SUPPLY_87_88)(svio1)
			0x00, // i2c_addr 
			1,    // present
			0,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			6,    // range_count
			{ {120, 120}, {125, 125}, {150,150}, {180,180}, {250, 250}, {330,330} } // ranges
		}, {
			0x30, // i2c_addr
			0,    // present
			0,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}, {
			// Group 2(SUPPLY_68)(svio2)
			0x00, // i2c_addr
			1,    // present
			1,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			4,    // range_count
			{ {120, 120}, {125,125}, {150,150}, {180,180} } // ranges
		}, {
			0x31, // i2c_addr
			0,    // present
			1,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}, {
			// Group 3(SUPPLY_67)(svio3)
			0x00, // i2c_addr
			1,    // present
			2,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			4,    // range_count
			{ {120, 120}, {125,125}, {150,150}, {180,180} } // ranges
		}, {
			0x32, // i2c_addr
			0,    // present
			2,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}, {
			0x34, // i2c_addr
			0,    // present
			2,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			SZG_ATTR_TXR4, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}, {
			// Group 4(SUPPLY_28)(svio4)
			0x00, // i2c_addr
			1,    // present
			3,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			4,    // range_count
			{ {120, 120}, {125,125}, {150,150}, {180,180} } // ranges
		}, {
			0x33, // i2c_addr
			0,    // present
			3,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			0x00, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}, {
			0x35, // i2c_addr
			0,    // present
			3,    // group
			0,    // req_ver_major
			0,    // req_ver_minor
			0x00, // attr
			SZG_ATTR_TXR4, // port_attr
			1,    // doublewide_mate
			0,    // range_count
			{ {0, 0}, {0,0}, {0,0}, {0,0} } // ranges
		}
	}
};

// Write to I2C with either a 16- or 8-bit address
int i2cWriteDNA (int i2c_file, int i2c_addr, uint16_t sub_addr,
              int sub_addr_length, int length, uint8_t data[32])
{
	uint8_t *buffer = (uint8_t *)malloc((length * sizeof(uint8_t)) + sub_addr_length);
	int i;

	memcpy(buffer + sub_addr_length, data, length * sizeof(uint8_t));

	// Set I2C address
	if (ioctl(i2c_file, I2C_SLAVE, i2c_addr) < 0) {
		return -1;
	}

	if (sub_addr_length == 2) {
		buffer[0] = (sub_addr >> 8) & 0xFF;
		buffer[1] = sub_addr & 0xFF;
	} else {
		buffer[0] = sub_addr & 0xFF;
	}

	for (i = 0; i < I2C_CHECK_COUNT; i++) {
		// The DNA Spec allows an MCU to NAK subsequent writes when multiple
		// writes are performed, keep trying for I2C_CHECK_COUNT tries before
		// giving up.
		if (write(i2c_file, buffer, sub_addr_length + length)
		      == (length + sub_addr_length)) {
			return 0;
		}
	}

	// We gave up trying to write
	return -1;
}


// Read from I2C with either a 16- or 8-bit address
int i2cReadDNA (int i2c_file, int i2c_addr, uint16_t sub_addr,
             int sub_addr_length, int length, uint8_t data[32])
{
	uint8_t temp_buf[2];

	// Set I2C address
	if (ioctl(i2c_file, I2C_SLAVE, i2c_addr) < 0) {
		return -1;
	}

	if (sub_addr_length == 2) {
		temp_buf[0] = (sub_addr >> 8) & 0xFF;
		temp_buf[1] = sub_addr & 0xFF;
	} else {
		temp_buf[0] = sub_addr & 0xFF;
	}

	if (write(i2c_file, temp_buf, sub_addr_length) != sub_addr_length) {
		return -1;
	}

	if (read(i2c_file, data, length) != length) {
		return -1;
	}

	return 0;
}

// Detect if a device is on a given I2C address, returns 0 if present
int i2cDetect (int i2c_file, int i2c_addr)
{
	uint8_t data[2];

	// Set I2C address
	if (ioctl(i2c_file, I2C_SLAVE, i2c_addr) < 0) {
		return -1;
	}

	data[0] = 0x00;
	data[1] = 0x00;

	if (write(i2c_file, data, 2) != 2) {
		return 1; // I2C device not present
	}

	return 0; // I2C device present
}


int i2c_write (int fd, uint8_t reg_addr, uint8_t reg_data)
{
	uint8_t buf[34];

	if (ioctl(fd, I2C_SLAVE, PCAL_ADDR) < 0) {
		printf("Error during I2C address set\n");
		exit(1);
	}
	
	//Good for debugging:
	//printf("Writing to %02X: %02X\n", reg_addr, reg_data);

	// write I2C register
	buf[0] = reg_addr;
	buf[1] = reg_data;

	if (write(fd, buf, 2) != 2) {
		printf ("Error during page set: %02X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	return 0;
}


int i2c_read (int fd, uint16_t reg_addr, uint8_t* reg_data)
{
	uint8_t buf[2];

	if (ioctl(fd, I2C_SLAVE, PCAL_ADDR) < 0) {
		printf("Error during I2C address set\n");
		exit(1);
	}
	
	//Good for debugging:
	//printf("Reading from %02X\n", reg_addr);

	buf[0] = reg_addr;

	if (write(fd, buf, 1) != 1) {
		printf("Error setting read address: %02X\n", reg_addr);
		exit(1);
	}

	if (read(fd, reg_data, 1) != 1) {
		printf("Error reading from I2C\n");
		exit(1);
	}

	return 0;
}
int disable_supply (int fd, int rail_index)
{
	uint8_t temp_reg;
	uint8_t pcal_port = 0;
	uint8_t en_offset = 0;

	switch(rail_index) {
		case SUPPLY_28:
			en_offset = 0;
			pcal_port = 0;
			break;
		case SUPPLY_67:
			en_offset = 4;
			pcal_port = 0;
			break;
		case SUPPLY_68:
			en_offset = 0;
			pcal_port = 1;
			break;
		case SUPPLY_87_88:
			en_offset = 4;
			pcal_port = 1;
			break;
		default:
			printf("Internal Error\n");
			exit(1);
	}

	// Read associated output port status
	i2c_read(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, &temp_reg);
	
	// Set associated output port to 0
	i2c_write(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, temp_reg & ~(0x1 << en_offset));

	// Read output port configuration
	i2c_read(fd, PCAL_CONFIG_PORT0_REG + pcal_port, &temp_reg);
	
	// Configure associated I/O direction to output
	i2c_write(fd, PCAL_CONFIG_PORT0_REG + pcal_port, temp_reg & ~(0x1 << en_offset));

	return 0;
}

int set_supply (int fd, int rail_index, uint8_t vs0, uint8_t vs1, uint8_t vs2)
{
	uint8_t temp_reg;
	uint8_t pcal_port = 0;
	uint8_t vs_offset = 0;

	switch(rail_index) {
		case SUPPLY_28:
			vs_offset = 0;
			pcal_port = 0;
			break;
		case SUPPLY_67:
			vs_offset = 4;
			pcal_port = 0;
			break;
		case SUPPLY_68:
			vs_offset = 0;
			pcal_port = 1;
			break;
		case SUPPLY_87_88:
			vs_offset = 4;
			pcal_port = 1;
			break;
		default:
			printf("Internal Error\n");
			exit(1);
	}

	// Read associated output port status
	i2c_read(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, &temp_reg);
	
	// Set associated output port to 0
	if (vs_offset == 0) {
		temp_reg = (temp_reg & (0xF << 4));
	} else {
		temp_reg = (temp_reg & (0xF << 0));
	}
	temp_reg = temp_reg | (((vs0 << 1) | (vs1 << 2) | (vs2 << 3)) << vs_offset);
	i2c_write(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, temp_reg);
	
	return 0;
}

int enable_supply (int fd, int rail_index)
{
	uint8_t temp_reg;
	uint8_t pcal_port = 0;
	uint8_t en_offset = 0;

	switch(rail_index) {
		case SUPPLY_28:
			en_offset = 0;
			pcal_port = 0;
			break;
		case SUPPLY_67:
			en_offset = 4;
			pcal_port = 0;
			break;
		case SUPPLY_68:
			en_offset = 0;
			pcal_port = 1;
			break;
		case SUPPLY_87_88:
			en_offset = 4;
			pcal_port = 1;
			break;
		default:
			printf("Internal Error\n");
			exit(1);
	}

	// Read associated output port status
	i2c_read(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, &temp_reg);
	
	// Set associated output port to 1
	i2c_write(fd, PCAL_OUTPUT_PORT0_REG + pcal_port, temp_reg | (0x1 << en_offset));

	// Read output port configuration
	i2c_read(fd, PCAL_CONFIG_PORT0_REG + pcal_port, &temp_reg);
	
	// Configure associated I/O direction to output
	i2c_write(fd, PCAL_CONFIG_PORT0_REG + pcal_port, temp_reg & ~(0xF << en_offset));

	return 0;
}
// Helper function that allows for writes > 32 bytes to a SYZYGY MCU
int writeMCU (int i2c_file, uint16_t port_addr, int sub_addr, uint8_t *data,
              int length)
{
	int temp_length, current_sub_addr;

	// Useful for debug
	//printf("Writing %d bytes to 0x%X, sub-address 0x%X\n", length, port_addr, sub_addr);

	current_sub_addr = sub_addr;

	while (length > 0) {
		temp_length = (length > 32) ? 32 : length;

		if (i2cWriteDNA(i2c_file, port_addr, current_sub_addr, 2, temp_length,
		             &data[(current_sub_addr - sub_addr)]) != 0) {
			return -1;
		}

		current_sub_addr += temp_length;
		length -= temp_length;
	}

	return 0;
}

// Helper function that allows for reads > 32 bytes from a SYZYGY MCU
int readMCU (int i2c_file, uint16_t port_addr, int sub_addr, uint8_t *data,
             int length)
{
	int current_sub_addr, temp_length;

	// Useful for debug
	//printf("Reading %d bytes from 0x%X, sub-address 0x%X\n", length, port_addr, sub_addr);

	current_sub_addr = sub_addr;

	while (length > 0) {
		temp_length = (length > 32) ? 32 : length;

		if (i2cReadDNA(i2c_file, port_addr, current_sub_addr, 2, temp_length,
		            &data[(current_sub_addr - sub_addr)]) != 0) {		
			return -1;
		}

		current_sub_addr += temp_length;
		length -= temp_length;
	}

	return 0;
}

// Helper function to dump a full DNA, determines the length of
// the DNA and returns it
int dumpDNA (int i2c_file, uint16_t port_addr, uint8_t *data)
{
	uint16_t dna_length;

	if (i2cReadDNA(i2c_file, port_addr, 0x8000, 2, 2, (uint8_t *)&dna_length) != 0) {
		return -1;
	}

	if (dna_length > 1318) {
		printf("Invalid DNA Length\n");
		exit(EXIT_FAILURE);
	}

	if (readMCU(i2c_file, port_addr, 0x8000, data, dna_length) != 0) {
		return -1;
	}

	return dna_length;
}


// Read DNA and determine a SmartVIO solution, stored in 'svio1' and 'svio2'
int readDNA (int i2c_file, uint32_t *svio1, uint32_t *svio2, uint32_t *svio3, uint32_t *svio4)
{
	uint8_t i;
	int vmin;
	uint8_t dna_buf[64];

	for (i = 0; i < SVIO_NUM_PORTS; i++) {
		// Skip ports referring to the FPGA
		if (0x00 == svio.ports[i].i2c_addr) {
			continue;
		}

		if (i2cDetect(i2c_file, svio.ports[i].i2c_addr) != 0) {
			// Device is not present
			continue;
		}
		
		//Good for debugging:
		//printf("Found device: %d\n", svio.ports[i].i2c_addr);
		
		// Read the full DNA Header
		if (readMCU(i2c_file, svio.ports[i].i2c_addr, 0x8000, dna_buf,
		            SZG_DNA_HEADER_LENGTH_V1) != 0) {
			return -1;
		}

		if (szgParsePortDNA(i, &svio, dna_buf, SZG_DNA_HEADER_LENGTH_V1) != 0) {
			return -1;
		}

		if (svio.ports[i].attr & SZG_ATTR_LVDS) {
			switch (svio.ports[i].group) {
				case 0:
					svio.ports[0].ranges[0].min = 250;
					svio.ports[0].ranges[0].max = 250;
					printf("LVDS attribute found for pod, setting voltage to 250\n");
					break;
			}
		}
	}

	// Find a solution
	for (i = 0; i < SVIO_NUM_GROUPS; i++) {
		vmin = szgSolveSmartVIOGroup(svio.ports, svio.group_masks[i]);
		if (vmin > 0) {
			svio.svio_results[i] = vmin;
		}
	}
	*svio1 = svio.svio_results[0];
	*svio2 = svio.svio_results[1];
	*svio3 = svio.svio_results[2];
	*svio4 = svio.svio_results[3];
	//Good for debugging:
	//printf("svio1: %d, svio2: %d, svio3: %d, svio4: %d\n", *svio1, *svio2, *svio3, *svio4);

	return 0;
}


// Apply SmartVIO settings to power IC
int applyVIO (int i2c_file, uint32_t svio1, uint32_t svio2, uint32_t svio3, uint32_t svio4)
{
	//uint8_t temp_data[2];
	uint8_t vs0;
	uint8_t vs1;
	uint8_t vs2;
	//The vio index is matched with the bank index, this is for use in the for loop below
	uint32_t svio_array[4];
	svio_array[0] = svio1;
	svio_array[1] = svio2;
	svio_array[2] = svio3;
	svio_array[3] = svio4;
	uint32_t bank_array[4];
	bank_array[0] = SUPPLY_87_88;
	bank_array[1] = SUPPLY_68;
	bank_array[2] = SUPPLY_67;
	bank_array[3] = SUPPLY_28;
	// Bounds check to be sure that everything is good to go
	if ((svio1 != 120) && (svio1 != 150) && (svio1 != 180) && (svio1 != 330) && (svio1 != 250) && (svio1 != 125)) {
		printf("Invalid SmartVIO1 solution. Valid solutions are:\n");
		printf("   VIO1: 120,  125,  150,  180,  250, 330 (Limited by HD bank range 1.2V to 3.3V)\n");
		exit(EXIT_FAILURE);
	}
	if ((svio2 != 120) && (svio2 != 125) && (svio2 != 150) && (svio2 != 180)) {
		printf("Invalid SmartVIO2 solution. Valid solutions are:\n");
		printf("   VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		exit(EXIT_FAILURE);
	}
	if ((svio3 != 120) && (svio3 != 125) && (svio3 != 150) && (svio3 != 180)) {
		printf("Invalid SmartVIO3 solution. Valid solutions are:\n");
		printf("   VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		exit(EXIT_FAILURE);
	}
	if ((svio4 != 120) && (svio4 != 125) && (svio4 != 150) && (svio4 != 180)) {
		printf("Invalid SmartVIO4 solution. Valid solutions are:\n");
		printf("   VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		exit(EXIT_FAILURE);
	}
	for(int i = 0; i < 4; i++){
		if (svio_array[i] == 330) {
			vs0 = 0;
			vs1 = 0;
			vs2 = 0;
		} else if (svio_array[i] == 250) {
			vs0 = 1;
			vs1 = 0;
			vs2 = 0;
		} else if (svio_array[i] == 180) {
			vs0 = 0;
			vs1 = 1;
			vs2 = 0;
		} else if (svio_array[i] == 150) {
			vs0 = 1;
			vs1 = 1;
			vs2 = 0;
		} else if (svio_array[i] == 125) {
			vs0 = 0;
			vs1 = 0;
			vs2 = 1;
		} else if (svio_array[i] == 120) {
			vs0 = 1;
			vs1 = 0;
			vs2 = 1;
		} else {
			printf("Voltage setting not supported, options are:\n");
			printf("   VIO1: 120,  125,  150,  180,  250, 330 (Limited by HD bank range 1.2V to 3.3V)\n");
			printf("   VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			printf("   VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			printf("   VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			return -1;
		}

		if(disable_supply(i2c_file, bank_array[i]) != 0){
			printf("Problem disabling bank - %d", bank_array[i]);
			return -1;
		}
		if(set_supply(i2c_file, bank_array[i], vs0, vs1, vs2) != 0){
			printf("Problem setting supply to bank - %d", bank_array[i]);
			return -1;
		}
		if(enable_supply(i2c_file, bank_array[i]) != 0){
			printf("Problem enabling bank - %d", bank_array[i]);
			return -1;
		}
		
		printf("Set VIO%d to %d (10's of mV)\n", bank_array[i], svio_array[i]);
	}
	

	
	
	return 0;
}

// Apply SmartVIO settings to power IC individually. 
int applyVIOIndividual (int i2c_fd, uint32_t svio, uint32_t voltage)
{
	int error = 0;
	uint8_t vs0, vs1, vs2;
	int i;



	if (ioctl(i2c_fd, I2C_SLAVE, PCAL_ADDR) < 0) {
		printf("Error during I2C address set\n");
		return -1;
	}

	if (voltage == 330) {
		vs0 = 0;
		vs1 = 0;
		vs2 = 0;
	} else if (voltage == 250) {
		vs0 = 1;
		vs1 = 0;
		vs2 = 0;
	} else if (voltage == 180) {
		vs0 = 0;
		vs1 = 1;
		vs2 = 0;
	} else if (voltage == 150) {
		vs0 = 1;
		vs1 = 1;
		vs2 = 0;
	} else if (voltage == 125) {
		vs0 = 0;
		vs1 = 0;
		vs2 = 1;
	} else if (voltage == 120) {
		vs0 = 1;
		vs1 = 0;
		vs2 = 1;
	} else {
		printf("Voltage setting not supported, options are:\n");
		printf("   VIO1: 120,  125,  150,  180,  250, 330 (Limited by HD bank range 1.2V to 3.3V)\n");
		printf("   VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		printf("   VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		printf("   VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
		return -1;
	}

	if (svio == 4) {
		if (vs2 == 0 && vs1 == 0) {
			printf("Voltage not supported on this rail\n");
			printf("   VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			return -1;
		}
		disable_supply(i2c_fd, SUPPLY_28);
		set_supply(i2c_fd, SUPPLY_28, vs0, vs1, vs2);
		enable_supply(i2c_fd, SUPPLY_28);
	} else if (svio == 3) {
		if (vs2 == 0 && vs1 == 0) {
			printf("Voltage not supported on this rail\n");
			printf("   VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			return -1;
		}
		disable_supply(i2c_fd, SUPPLY_67);
		set_supply(i2c_fd, SUPPLY_67, vs0, vs1, vs2);
		enable_supply(i2c_fd, SUPPLY_67);
	} else if (svio == 2) {
		if (vs2 == 0 && vs1 == 0) {
			printf("Voltage not supported on this rail\n");
			printf("   VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
			return -1;
		}
		disable_supply(i2c_fd, SUPPLY_68);
		set_supply(i2c_fd, SUPPLY_68, vs0, vs1, vs2);
		enable_supply(i2c_fd, SUPPLY_68);
	} else if (svio == 1) {
		disable_supply(i2c_fd, SUPPLY_87_88);
		set_supply(i2c_fd, SUPPLY_87_88, vs0, vs1, vs2);
		enable_supply(i2c_fd, SUPPLY_87_88);
	} else {
		printf("Error: unrecognized supply rail, options are:\n");
		printf("   1 (VCCO_87_88)\n");
		printf("   2 (VCCO_68\n");
		printf("   3 (VCCO_67\n");
		printf("   4 (VCCO_28)\n");
		return -1;
	}
	printf("Set VIO%d to %d (10's of mV)\n", svio, voltage);
	return 0;
}

// Print strings, Read DNA must have been run first to populate the svio struct
int printVIOStrings (json &json_handler, int i2c_file)
{
	uint8_t temp_string[257];
	int i;
	int j = 0;

	for (i = 0; i < SVIO_NUM_PORTS; i++) {
		if (svio.ports[i].i2c_addr == 0x00) {
			// don't print anything for FPGA "ports"
			continue;
		}

		if (svio.ports[i].present == 0) {
			if (!json_handler.is_null()) {
				json_handler["port"][j] = nullptr;
			}

			// just increment the port counter for non-present ports
			j++;
			continue;
		}

		// retrieve manufacturer
		if (readMCU(i2c_file, svio.ports[i].i2c_addr,
		        0x8000 + svio.ports[i].mfr_offset, temp_string,
		        svio.ports[i].mfr_length) != 0) {
			return -1;
		}

		temp_string[svio.ports[i].mfr_length] = '\0';

		if (!json_handler.is_null()) {
			json_handler["port"][j]["manufacturer"] = std::string((char*) temp_string);
		} else {
			printf("Port 0x%X Manufacturer: %s\n", svio.ports[i].i2c_addr, temp_string);
		}

		// retrieve product name
		if (readMCU(i2c_file, svio.ports[i].i2c_addr,
		        0x8000 + svio.ports[i].product_name_offset, temp_string,
		        svio.ports[i].product_name_length) != 0) {
			return -1;
		}

		temp_string[svio.ports[i].product_name_length] = '\0';

		if (!json_handler.is_null()) {
			json_handler["port"][j]["product_name"] = std::string((char*) temp_string);
		} else {
			printf("Product Name: %s\n", temp_string);
		}

		// retrieve product model
		if (readMCU(i2c_file, svio.ports[i].i2c_addr,
		        0x8000 + svio.ports[i].product_model_offset, temp_string,
		        svio.ports[i].product_model_length) != 0) {
			return -1;
		}

		temp_string[svio.ports[i].product_model_length] = '\0';

		if (!json_handler.is_null()) {
			json_handler["port"][j]["product_model"] = std::string((char*) temp_string);
		} else {
			printf("Product Model: %s\n", temp_string);
		}

		// retrieve product version
		if (readMCU(i2c_file, svio.ports[i].i2c_addr,
		        0x8000 + svio.ports[i].product_version_offset, temp_string,
		        svio.ports[i].product_version_length) != 0) {
			return -1;
		}

		temp_string[svio.ports[i].product_version_length] = '\0';

		if (!json_handler.is_null()) {
			json_handler["port"][j]["product_version"] = std::string((char*) temp_string);
		} else {
			printf("Version: %s\n", temp_string);
		}

		// retrieve serial
		if (readMCU(i2c_file, svio.ports[i].i2c_addr,
		        0x8000 + svio.ports[i].serial_number_offset, temp_string,
		        svio.ports[i].serial_number_length) != 0) {
			return -1;
		}

		temp_string[svio.ports[i].serial_number_length] = '\0';

		if (!json_handler.is_null()) {
			json_handler["port"][j]["serial_number"] = std::string((char*) temp_string);
		} else {
			printf("Serial: %s\n", temp_string);
		}
		j++;
	}

	return 0;
}


// Help text
void printHelp (char *progname)
{
	printf("Usage: %s [option [argument]] <i2c device>\n", progname);
	printf("  <i2c device> is required for all commands. It must contain the\n");
	printf("               path to the Linux i2c device. '/dev/i2c-0' should be used on the ECM1900\n");
	printf("\n");
	printf("  Exactly one of the following options must be specified:\n");
	printf("    -r - run smartVIO, queries attached MCU's and sets voltages accordingly\n");
	printf("    -s - set VIO voltages to the values provided by -1, -2, -3, -4 options (Can only set one at a time)\n");
	printf("    -j - print out a JSON object with DNA and SmartVIO information\n");
	printf("    -h - print this help text\n");
	printf("    -w <filename> - write a binary DNA to a peripheral, takes the DNA filename\n");
	printf("                    as an argument\n");
	printf("    -d <filename> - dump the DNA from a peripheral to a binary file, takes the\n");
	printf("                    DNA filename as an argument\n");
	printf("\n");
	printf("  The following options may be used in conjunction with the above options:\n");
	printf("    -1 <vio1> - Sets the voltage for VIO1(VCCO_87_88)\n");
	printf("    -2 <vio2> - Sets the voltage for VIO2(VCCO_68)\n");
	printf("    -3 <vio3> - Sets the voltage for VIO3(VCCO_67)\n");
	printf("    -4 <vio4> - Sets the voltage for VIO4(VCCO_28)\n");
	printf("                  *<vioX> must be specified as numbers in 10's of mV\n");
	printf("                  *You may only set one voltage at a time\n");
	printf("                  *The valid discrete voltage supplies provided by the power supply on the ECM1900 are:\n");
	printf("                  VIO1: 120,  125,  150,  180,  250, 330 (Limited by HD bank range 1.2V to 3.3V)\n");
	printf("                  VIO2: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
	printf("                  VIO3: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
	printf("                  VIO4: 120,  125,  150,  180 (Limited by HP bank range 1.0V to 1.8V)\n");
	printf("    -p <number> - Specifies the peripheral number for the -w or -d options\n");
	printf("\n");
	printf("  Examples:\n");
	printf("    Run SmartVIO sequence:\n");
	printf("      %s -r /dev/i2c-0\n", progname);
	printf("    Dump DNA from the MCU on Port 1:\n");
	printf("      %s -d dna_file.bin -p 1 /dev/i2c-0\n", progname);
	printf("    Set VIO1 to 3.3V:\n");
	printf("      %s -s -1 330 /dev/i2c-0\n", progname);
}


int main (int argc, char *argv[])
{
	// Options flags
	int rflag = 0;
	int sflag = 0;
	int jflag = 0;
	int hflag = 0;
	int wflag = 0;
	int dflag = 0;
	uint32_t svio1 = 0;
	uint32_t svio2 = 0;
	uint32_t svio3 = 0;
	uint32_t svio4 = 0;
	char i2c_filename[200];
	char dna_filename[200];
	uint8_t dna_buf[1320];
	int i2c_file;
	int dna_file;
	int dna_length = 0;
	int periph_num = 0;
	int curr_opt;
	json json_handler;
	uint16_t peripheral_address[] = {0x30, 0x31, 0x32, 0x33, 0x34, 0x35};
	bool takeOne = true;
	int rail;
	int voltage;
	// Parse args
	while ((curr_opt = getopt(argc, argv, "rsj1:2:3:4:w:d:p:h")) != -1) {
		switch(curr_opt)
		{
			case 'r':
				rflag = 1;
				break;
			case 's':
				sflag = 1;
				break;
			case 'j':
				jflag = 1;
				break;
			case '1':
				if (takeOne){
					takeOne = false;
					if (optarg){ 
						voltage = atoi(optarg);
						rail = 1;
					} else {
						printf("No argument specified for -1\n");
						exit(EXIT_FAILURE);
					}
				} else {
					printf("Can only set one VIO at a time.\n");
					exit(EXIT_FAILURE);
				}
				break;
			case '2':
				if (takeOne){
					takeOne = false;
					if (optarg){ 
						voltage = atoi(optarg);
						rail = 2;
					} else {
						printf("No argument specified for -1\n");
						exit(EXIT_FAILURE);
					}
				} else {
					printf("Can only set one VIO at a time.\n");
					exit(EXIT_FAILURE);
				}
				break;;
			case '3':
				if (takeOne){
					takeOne = false;
					if (optarg){ 
						voltage = atoi(optarg);
						rail = 3;
					} else {
						printf("No argument specified for -1\n");
						exit(EXIT_FAILURE);
					}
				} else {
					printf("Can only set one VIO at a time.\n");
					exit(EXIT_FAILURE);
				}
				break;
			case '4':
				if (takeOne){
					takeOne = false;
					if (optarg){ 
						voltage = atoi(optarg);
						rail = 4;
					} else {
						printf("No argument specified for -1\n");
						exit(EXIT_FAILURE);
					}
				} else {
					printf("Can only set one VIO at a time.\n");
					exit(EXIT_FAILURE);
				}
				break;
			case 'w':
				wflag = 1;
				if (optarg){ 
					strcpy(dna_filename, optarg);
				} else {
					printf("No argument specified for -w\n");
					exit(EXIT_FAILURE);
				}
				break;
			case 'd':
				dflag = 1;
				if (optarg){ 
					strcpy(dna_filename, optarg);
				} else {
					printf("No argument specified for -d\n");
					exit(EXIT_FAILURE);
				}
				break;
			case 'p':
				if (optarg){ 
					periph_num = strtol(optarg, NULL, 0) - 1;
				} else {
					printf("No argument specified for -p\n");
					exit(EXIT_FAILURE);
				}
				break;
			case 'h':
				hflag = 1;
				break;
			case '?':
				printHelp(argv[0]);
				exit(EXIT_FAILURE);
			default:
				printHelp(argv[0]);
				exit(EXIT_FAILURE);
		}
	}

	if ((hflag == 1) || (argc == 1)) {
		printHelp(argv[0]);
		return 0;
	}

	// Extract i2c device
	if (optind < argc) {
		strcpy(i2c_filename, argv[optind]);
	} else {
		printf("I2C Device required.\n");
		exit(EXIT_FAILURE);
	}

	// Open I2C file
	i2c_file = open(i2c_filename, O_RDWR);
	if (i2c_file < 0) {
		printf("Error opening i2c device\n");
		exit(EXIT_FAILURE);
	}

	if ((rflag + sflag + jflag + hflag + wflag + dflag) > 1) {
		printf("Invalid set of options specified.\n");
		printHelp(argv[0]);
		return 0;
	}

	if ((wflag == 1) || (dflag == 1)) {
		if (i2cDetect(i2c_file, peripheral_address[periph_num]) != 0) {
			printf("Peripheral at %X not found\n", peripheral_address[periph_num]);
			exit(EXIT_FAILURE);
		}

		dna_file = open(dna_filename, O_RDWR | O_CREAT, 0666);
		if (dna_file < 0) {
			printf("Error opening DNA file\n");
			exit(EXIT_FAILURE);
		}
	}

	if (rflag == 1) { // Run the main SmartVIO procedure
		if (readDNA(i2c_file, &svio1, &svio2, &svio3, &svio4) != 0) {
			printf("Error obtaining a SmartVIO solution\n");
			exit(EXIT_FAILURE);
		}

		if (applyVIO(i2c_file, svio1, svio2, svio3, svio4) != 0) {
			printf("Error applying SmartVIO settings to power supplies\n");
			exit(EXIT_FAILURE);
		}

		if (printVIOStrings(json_handler, i2c_file) != 0) {
			printf("Error retrieving DNA strings\n");
			exit(EXIT_FAILURE);
		}
	} else if (sflag == 1) { // Apply a user specified VIO
		if (applyVIOIndividual(i2c_file, rail, voltage) != 0) {
			printf("Error applying Individual SmartVIO settings to power supplies\n");
			exit(EXIT_FAILURE);
		}
	} else if (jflag == 1) {
		readDNA(i2c_file, &svio1, &svio2, &svio3, &svio4);

		// Bounds check on the svio ranges
		if ((svio1 < 120) || (svio1 > 330) || (svio2 < 120) || (svio2 > 180) || (svio3 < 120) || (svio3 > 180) || (svio4 < 120) || (svio4 > 180)) {
			json_handler["vio"][0] = 0;
			json_handler["vio"][1] = 0;
			json_handler["vio"][2] = 0;
			json_handler["vio"][3] = 0;
		} else {
			json_handler["vio"][0] = svio1;
			json_handler["vio"][1] = svio2;
			json_handler["vio"][2] = svio3;
			json_handler["vio"][3] = svio4;
		}

		printVIOStrings(json_handler, i2c_file);

		printf("%s\n", json_handler.dump().c_str());
		printf("\n");
	} else if (wflag == 1) { // Write DNA from a file to a peripheral
		if (read(dna_file, &dna_length, 2) != 2) {
			printf("Error reading from DNA file\n");
			exit(EXIT_FAILURE);
		}

		if (dna_length > 1318) {
			printf("Invalid DNA Length\n");
			exit(EXIT_FAILURE);
		}

		lseek(dna_file, 0, SEEK_SET);
		if (read(dna_file, dna_buf, dna_length) != dna_length) {
			printf("Error reading from DNA file\n");
			exit(EXIT_FAILURE);
		}

		if (writeMCU(i2c_file, peripheral_address[periph_num], 0x8000,
		             dna_buf, dna_length) != 0) {
			printf("Error writing to the MCU\n");
			exit(EXIT_FAILURE);
		}
	} else if (dflag == 1) { // Dump DNA from a peripheral to a file
		dna_length = dumpDNA(i2c_file, peripheral_address[periph_num], dna_buf);

		if (dna_length < 0) {
			printf("Error reading DNA from device\n");
			exit(EXIT_FAILURE);
		}
		
		if (write(dna_file, dna_buf, dna_length) != dna_length) {
			printf("Error writing to DNA file\n");
			exit(EXIT_FAILURE);
		}
	} else {
		printHelp(argv[0]);
		return 0;
	}

	return 0;
}

