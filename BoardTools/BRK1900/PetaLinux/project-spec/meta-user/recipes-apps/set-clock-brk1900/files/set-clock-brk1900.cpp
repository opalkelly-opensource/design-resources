#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "BRK1900-Si5338-Regs.h"


int i2cRead8 (int fd, uint8_t reg_addr, uint8_t* reg_data)
{
	uint8_t buf[34];

	// write address
	buf[0] = (reg_addr) & 0xFF;

	if (write(fd, buf, 1) != 1) {
		printf ("Error during data write: %04X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	if (read(fd, buf, 1) != 1) {
		printf ("Error during data read: %04X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	*reg_data = buf[0];

	return 0;
}


int i2cWrite8 (int fd, uint8_t reg_addr, uint8_t reg_data)
{
	uint8_t buf[34];

	// write data
	buf[0] = (reg_addr) & 0xFF;
	buf[1] = (reg_data) & 0xFF;

	if (write(fd, buf, 2) != 2) {
		printf ("Error during data write: %04X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	return 0;
}

int writechip (int i2c_fd)
{
    uint8_t addr;
	uint32_t i;
	// Juicy Bits
	printf("Writing Si5338 I2C regs...\n");

	// Read out some device info to see if we're talking to the right thing...
	uint8_t temp_val = 0;

	i2cRead8(i2c_fd, 0x00, &temp_val);
	printf("0x00 = %02X\n", temp_val);
	i2cRead8(i2c_fd, 0x02, &temp_val);
	printf("0x02 = %02X\n", temp_val);
	i2cRead8(i2c_fd, 0x03, &temp_val);
	printf("0x03 = %02X\n", temp_val);

	uint8_t mask, new_val, curr_val, check_val, mismatch;

	mismatch = 0;

	// From Si5338 Datasheet, Figure 9.
	// Disable all outputs
	i2cWrite8(i2c_fd, 230, 0x10);

	// Pause LOL
	i2cWrite8(i2c_fd, 241, 0x80 | 0x65);

	for (i = 0; i < NUM_REGS_MAX; i++) {
		mask = Reg_Store[i].Reg_Mask;
		new_val = Reg_Store[i].Reg_Val;
		addr = Reg_Store[i].Reg_Addr;

		// Ignore if register mask == 0x00
		if (mask != 0x00) {
			if (mask == 0xFF) {
				i2cWrite8(i2c_fd, addr, new_val);
			} else {
				i2cRead8(i2c_fd, addr, &curr_val);

				curr_val &= ~mask;

				new_val = (new_val & mask) | curr_val;

				i2cWrite8(i2c_fd, addr, new_val);
			}

			i2cRead8(i2c_fd, addr, &check_val);

			if (check_val != new_val) {
				printf("MISMATCH, i = %d, new_val = %d, check_val = %d\n", i, new_val, check_val);
				mismatch += 1;
			}
		}

		if (addr == 255 && mask == 0xFF && new_val == 0) {
			break;
		}
	}
	printf("Done!\n");

	if (mismatch == 0) {
		printf("There were no mismatches!\n");
	}

	for (i = 0; i < 100; i++) {
		i2cRead8(i2c_fd, 218, &check_val);

		if ((check_val & 0x04) == 0) {
			printf("Input clock valid\n");
			break;
		}
		sleep(0.001);
	}

	if (i == 100) {
		printf("ERROR: Input clock invalid\n");
		return -1;
	}

	printf("Configuring PLL for locking...\n");
	// Configure PLL for locking
	i2cRead8(i2c_fd, 49, &curr_val);
	new_val = curr_val & 0x7F; // clear bit 7
	i2cWrite8(i2c_fd, 49, new_val);

	printf("Initiate locking of PLL...\n");
	// Initiate Locking of PLL
	i2cWrite8(i2c_fd, 246, 0x02);

	sleep(0.025);

	printf("Restart LOL...\n");
	// Restart LOL
	i2cWrite8(i2c_fd, 241, 0x65);

	for (i = 0; i < 100; i++) {
		i2cRead8(i2c_fd, 218, &check_val);

		if ((check_val & 0x15) == 0) {
			printf("PLL locked\n");
			break;
		}
		sleep(0.001);
	}

	if (i == 100) {
		printf("ERROR: PLL not locked\n");
		return -1;
	}

	printf("Copy FCAL...\n");
	// Copy FCAL values
	i2cRead8(i2c_fd, 237, &new_val);
	new_val = (new_val & 0x03) | 0x14;
	i2cWrite8(i2c_fd, 47, new_val);

	i2cRead8(i2c_fd, 236, &new_val);
	i2cWrite8(i2c_fd, 46, new_val);

	i2cRead8(i2c_fd, 235, &new_val);
	i2cWrite8(i2c_fd, 45, new_val);

	printf("Set PLL to use FCAL...\n");
	// Set PLL to use FCAL values
	i2cRead8(i2c_fd, 49, &curr_val);
	new_val = curr_val | 0x80; // set bit 7
	i2cWrite8(i2c_fd, 49, new_val);

	printf("Enable outputs...\n");
	// Enable outputs
	i2cWrite8(i2c_fd, 230, 0);

	return 0;
}

int checkchip (int i2c_fd)
{
    uint8_t addr;
	uint32_t i;
	// Juicy Bits
	printf("Writing Si5338 I2C regs...\n");

	// Read out some device info to see if we're talking to the right thing...
	uint8_t temp_val = 0;

	i2cRead8(i2c_fd, 0x00, &temp_val);
	printf("0x00 = %02X\n", temp_val);
	i2cRead8(i2c_fd, 0x02, &temp_val);
	printf("0x02 = %02X\n", temp_val);
	i2cRead8(i2c_fd, 0x03, &temp_val);
	printf("0x03 = %02X\n", temp_val);

	uint8_t mask, new_val, curr_val, check_val, mismatch;

	mismatch = 0;


	for (i = 0; i < NUM_REGS_MAX; i++) {
		mask = Reg_Store[i].Reg_Mask;
		new_val = Reg_Store[i].Reg_Val;
		addr = Reg_Store[i].Reg_Addr;

		// Ignore if register mask == 0x00
		if (mask != 0x00) {

			// Applicable register values to check to see if 
			// the specific config is configured.
			if (addr >= 28 && addr <= 34)
			{

				if (mask == 0xFF) {
					
				} else {
					i2cRead8(i2c_fd, addr, &curr_val);

					curr_val &= ~mask;

					new_val = (new_val & mask) | curr_val;

					
				}

				i2cRead8(i2c_fd, addr, &check_val);

				if (check_val != new_val) {
					printf("MISMATCH, i = 0x%02X, new_val = 0x%02X, check_val = 0x%02X\n", i, new_val, check_val);
					mismatch += 1;
				}
			}
		}

		if (addr == 255 && mask == 0xFF && new_val == 1) {
			break;
		}
	}
	printf("Done!\n");

	if (mismatch == 0) {
		printf("There were no mismatches!\n");
	} else {
		printf("There were mismatches!\n");
		return -1;
	}

	return 0;
}


int main (int argc, char *argv[])
{
	int i2c_fd;
	int error = 0;
	    uint8_t addr;
	    	uint32_t i;


	char filename[20];
	char arg_w_c[20];

	if (argc != 3) {
		printf("Usage: %s [-w/-c] [i2c device]\n", argv[0]);
		exit(1);
	}

	strcpy(arg_w_c, argv[1]);
	strcpy(filename, argv[2]);

	i2c_fd = open(filename, O_RDWR);
	if (i2c_fd < 0) {
		printf("Error opening i2c device\n");
		exit(1);
	}

	addr = 0x70; // Si5338 on BRK1900

	if (ioctl(i2c_fd, I2C_SLAVE, addr) < 0) {
		printf("Error during address set\n");
		exit(1);
	}

	if (strcmp(arg_w_c, "-w") == 0) {
		error = writechip(i2c_fd);
	} else if (strcmp(arg_w_c, "-c") == 0) {
		error = checkchip(i2c_fd);
	} else {
		printf("Usage: %s [-w/-c] [i2c device]\n", argv[0]);
		error = -1;
	}



	return error;
}
