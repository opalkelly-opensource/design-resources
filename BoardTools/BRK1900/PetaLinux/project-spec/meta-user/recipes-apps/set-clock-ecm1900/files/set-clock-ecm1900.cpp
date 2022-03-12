#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "ECM1900-Si5341-Regs.h"

/*
int i2c_read (uint16_t reg_addr, uint8_t* reg_data)
{

}
*/

int i2c_write (int fd, uint16_t reg_addr, uint8_t reg_data)
{
	uint8_t buf[34];

	// write page
	buf[0] = 0x01;
	buf[1] = (reg_addr >> 8) & 0xFF;

	if (write(fd, buf, 2) != 2) {
		printf ("Error during page set: %04X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	// write data
	buf[0] = (reg_addr) & 0xFF;
	buf[1] = (reg_data) & 0xFF;

	if (write(fd, buf, 2) != 2) {
		printf ("Error during data write: %04X, %02X\n", reg_addr, reg_data);
		exit(1);
	}

	return 0;
}

int main (int argc, char *argv[])
{
	int i2c_fd;
	int error = 0;
	uint8_t addr;
	int i;


	char filename[20];

	if (argc != 2) {
		printf("Usage: %s [i2c device]\n", argv[0]);
		exit(1);
	}

	strcpy(filename, argv[1]);

	i2c_fd = open(filename, O_RDWR);
	if (i2c_fd < 0) {
		printf("Error opening i2c device\n");
		exit(1);
	}

	addr = 0x74; // Si5341 on ECM1900

	if (ioctl(i2c_fd, I2C_SLAVE, addr) < 0) {
		printf("Error during address set\n");
		exit(1);
	}

	for (i = 0; i < SI5341_REVD_REG_CONFIG_NUM_REGS; i++) {
		i2c_write(i2c_fd, si5341_revd_registers[i].address, si5341_revd_registers[i].value);
	}

	return error;
}




