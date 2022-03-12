// SYZYGY Library
//
// Includes SmartVIO helper routines.
//
//------------------------------------------------------------------------
// Copyright (c) 2014-2019 Opal Kelly Incorporated
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


// LIBRARY PARAMETERS
// Constraints that apply to this library itself

// SmartVIO version implemented and supported by this library
#define SVIO_IMPL_VER_MAJOR (1)
#define SVIO_IMPL_VER_MINOR (1)

// CARRIER-SPECIFIC PARAMETERS
// Complete these constant definitions with those appropriate to your carrier.
// Number of ports on the most populous SmartVIO group, including FPGA constraints.

// Total number of SmartVIO groups. This corresponds to the number of unique
// SmartVIO voltages provided by the carrier.
#define SVIO_NUM_GROUPS             (4)

// Maximum number of SYZYGY ports on a single SmartVIO group for the system.
// The FPGA side of a SYZYGY connection counts as a port here.
#define SVIO_MAX_PORTS              (3)

// Total number of SmartVIO ports in the system.
// The FPGA side of a SYZYGY connection counts as a port here.
#define SVIO_NUM_PORTS              (10)

// Maximum number of SmartVIO ranges definable in the DNA.
#define SZG_ATTR_LVDS                       (0x0001)
#define SZG_ATTR_DOUBLEWIDE                 (0x0002)
#define SZG_ATTR_TXR4                       (0x0004)

// Maximum number of SmartVIO ranges defined in the DNA header.
#define SZG_MAX_DNA_RANGES                  (4)

// Maximum number of SmartVIO ranges to search in manually defined FPGA port.
#define SZG_MAX_FPGA_RANGES                  (6)

// Maximum length of an I2C read supported by the DNA firmware.
#define SZG_MAX_DNA_I2C_READ_LENGTH         (32)
#define SZG_DNA_HEADER_LENGTH_V1            (40)

#define SZG_DNA_PTR_FULL_LENGTH             (0)
#define SZG_DNA_PTR_HEADER_LENGTH           (2)
#define SZG_DNA_PTR_DNA_MAJOR               (4)
#define SZG_DNA_PTR_DNA_MINOR               (5)
#define SZG_DNA_PTR_DNA_REQUIRED_MAJOR      (6)
#define SZG_DNA_PTR_DNA_REQUIRED_MINOR      (7)
#define SZG_DNA_PTR_MAX_5V_LOAD             (8)
#define SZG_DNA_PTR_MAX_33V_LOAD            (10)
#define SZG_DNA_PTR_MAX_VIO_LOAD            (12)
#define SZG_DNA_PTR_ATTRIBUTES              (14)
#define SZG_DNA_MIN_VIO_RANGE0              (16)
#define SZG_DNA_MAX_VIO_RANGE0              (18)
#define SZG_DNA_MIN_VIO_RANGE1              (20)
#define SZG_DNA_MAX_VIO_RANGE1              (22)
#define SZG_DNA_MIN_VIO_RANGE2              (24)
#define SZG_DNA_MAX_VIO_RANGE2              (26)
#define SZG_DNA_MIN_VIO_RANGE3              (28)
#define SZG_DNA_MAX_VIO_RANGE3              (30)
#define SZG_DNA_MANUFACTURER_NAME_LENGTH    (32)
#define SZG_DNA_PRODUCT_NAME_LENGTH         (33)
#define SZG_DNA_PRODUCT_MODEL_LENGTH        (34)
#define SZG_DNA_PRODUCT_VERSION_LENGTH      (35)
#define SZG_DNA_SERIAL_NUMBER_LENGTH        (36)
#define SZG_DNA_CRC16_HIGH                  (38)
#define SZG_DNA_CRC16_LOW                   (39)


typedef struct {
	int      min;
	int      max;
} szgSmartVIORange;
typedef struct {
	int                i2c_addr; // 0x00 to refer to the host, otherwise it's a port
	int                present;
	int                group; // used to store which VIO group a port is on
	unsigned int       req_ver_major; // Required major version support
	unsigned int       req_ver_minor; // Required minor version support
	int                attr; // used to store peripheral attributes, currently doublewide, LVDS, and TXR4
	int                port_attr; // used to store port-side attributes, currently only TXR4
	// For a double-wide set of ports spanning two groups, the doublewide mate
	// must point to the "other" group that a port will be mated with when a
	// doublewide peripheral is connected
	int                doublewide_mate;
	int                range_count;
	szgSmartVIORange   ranges[SZG_MAX_FPGA_RANGES];
	unsigned int       mfr_offset;
	unsigned int       mfr_length;
	unsigned int       product_name_offset;
	unsigned int       product_name_length;
	unsigned int       product_model_offset;
	unsigned int       product_model_length;
	unsigned int       product_version_offset;
	unsigned int       product_version_length;
	unsigned int       serial_number_offset;
	unsigned int       serial_number_length;
} szgSmartVIOPort;
typedef struct {
	int                 num_ports;
	int                 num_groups;
	int                 svio_results[SVIO_NUM_GROUPS];
	// The group masks are used to identify if a port belongs to a specific
	// group. This mask must be a single bit in a 32-bit range for each group.
	int                 group_masks[SVIO_NUM_GROUPS];
	szgSmartVIOPort     ports[SVIO_NUM_PORTS];
} szgSmartVIOConfig;

#define szgMAX(a,b)  ((a)>(b) ? (a) : (b))
#define szgMIN(a,b)  ((a)<(b) ? (a) : (b))


int szgParsePortDNA(int n, szgSmartVIOConfig *svio, unsigned char *dnaBuf, int length);

int szgSolveSmartVIOGroup(szgSmartVIOPort *ports, int group_mask);

unsigned short szgComputeCRC(const unsigned char *data, unsigned int length);

