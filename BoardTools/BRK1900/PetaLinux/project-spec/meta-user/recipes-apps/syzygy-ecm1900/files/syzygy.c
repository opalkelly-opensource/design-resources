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


#include "syzygy.h"
//#include <stdio.h>

/// Computes the CRC-16/CCITT checksum using parallel computation without tables.
/// https://en.wikipedia.org/wiki/Computation_of_cyclic_redundancy_checks
///
/// Polynomial: 0x1021 (x^16 + x^12 + x^5 + x^0)
/// Initialization: 0xFFFF
/// Data "shifted" MSB first
///
/// \returns Computed 16-bit CRC.
unsigned short
szgComputeCRC(const unsigned char *data, unsigned int length)
{
	unsigned short x, crc = 0xffff;

	while (length--){
		x = (crc >> 8) ^ *data++;
		x ^= x>>4;
		crc = (crc<<8) ^ (x<<12) ^ (x<<5) ^ (x);
		crc &= 0xffff;
	}
	return(crc);
}



/// Parses the DNA header to extract the port voltage ranges
/// and attribute information.
///
/// \returns -1 if the call failed. 0 on success.
int
szgParsePortDNA(int n, szgSmartVIOConfig *svio, unsigned char *dnaBuf, int length)
{
	int i;
	int vmin, vmax;
	unsigned int offset;


	// Bounds check for input buffer.
	if (length < SZG_DNA_HEADER_LENGTH_V1) {
		return(-1);
	}

	// Validate the DNA CRC.
	if (0 != szgComputeCRC(dnaBuf, SZG_DNA_HEADER_LENGTH_V1)) {
		return(-1);
	}

	svio->ports[n].present = 1;
	svio->ports[n].req_ver_major = dnaBuf[SZG_DNA_PTR_DNA_REQUIRED_MAJOR];
	svio->ports[n].req_ver_minor = dnaBuf[SZG_DNA_PTR_DNA_REQUIRED_MINOR];
	svio->ports[n].attr = (dnaBuf[SZG_DNA_PTR_ATTRIBUTES + 1] << 8) | (dnaBuf[SZG_DNA_PTR_ATTRIBUTES]);
	for (i=0; i<SZG_MAX_DNA_RANGES; i++) {
		vmin = (dnaBuf[SZG_DNA_MIN_VIO_RANGE0 + i*4 + 1] << 8) | (dnaBuf[SZG_DNA_MIN_VIO_RANGE0 + i*4]);
		vmax = (dnaBuf[SZG_DNA_MAX_VIO_RANGE0 + i*4 + 1] << 8) | (dnaBuf[SZG_DNA_MAX_VIO_RANGE0 + i*4]);
		if ((vmin == 0) && (vmin == 0)) {
			break;
		} else {
			svio->ports[n].ranges[i].min = vmin;
			svio->ports[n].ranges[i].max = vmax;
			svio->ports[n].range_count++;
			
			//Good for debugging:
			//printf("\nmin %d, max %d, rangecount %d\n", vmin, vmax, svio->ports[n].range_count);
		}
	}

	// If the DOUBLEWIDE attribute is set, we need to add the mating group to the dependents.
	// We also need to create the reciprocal relationship so that the mating group includes
	// the present port.
	if (svio->ports[n].attr & SZG_ATTR_DOUBLEWIDE) {
		svio->group_masks[svio->ports[n].group] |= (1 << svio->ports[n].doublewide_mate);
		svio->group_masks[svio->ports[n].doublewide_mate] |= (1 << svio->ports[n].group);
	}

	offset = SZG_DNA_HEADER_LENGTH_V1;
	svio->ports[n].mfr_offset = offset;
	svio->ports[n].mfr_length = dnaBuf[SZG_DNA_MANUFACTURER_NAME_LENGTH];

	offset += svio->ports[n].mfr_length;
	svio->ports[n].product_name_offset = offset;
	svio->ports[n].product_name_length = dnaBuf[SZG_DNA_PRODUCT_NAME_LENGTH];

	offset += svio->ports[n].product_name_length;
	svio->ports[n].product_model_offset = offset;
	svio->ports[n].product_model_length = dnaBuf[SZG_DNA_PRODUCT_MODEL_LENGTH];

	offset += svio->ports[n].product_model_length;
	svio->ports[n].product_version_offset = offset;
	svio->ports[n].product_version_length = dnaBuf[SZG_DNA_PRODUCT_VERSION_LENGTH];

	offset += svio->ports[n].product_version_length;
	svio->ports[n].serial_number_offset = offset;
	svio->ports[n].serial_number_length = dnaBuf[SZG_DNA_SERIAL_NUMBER_LENGTH];

	return(0);
}


/// Searches for a VIO solution that satisfies all present ports of
/// a group. The search inspects all combinations of voltage ranges
/// and selects the first one found.
///
/// Returns -1 if a solution was not found. Non-zero otherwise.
int
szgSolveSmartVIOGroup(szgSmartVIOPort *ports, int group_mask)
{
	int i;
	int vmin, vmax;
	int fmin, fmax;
	int rangePtrs[SVIO_NUM_PORTS];


	for (i=0; i<SVIO_NUM_PORTS; rangePtrs[i++]=0);

	while (1) {
		// Prior to each intervals test, start with the least restrictive interval.
		// As we inspect the port settings, this interval will shrink.
		fmin = 0;
		fmax = 500;

		for (i=0; i<SVIO_NUM_PORTS; i++) {
			if (0 == ports[i].present) {
				continue;
			}

			// If the port group membership belongs to the group dependents, then this port
			// must factor into our SmartVIO solution. Otherwise, we skip it.
			if (0 == (group_mask & (1 << ports[i].group)) ) {
				continue;
			}

			// Check the minimum support version of the peripheral in the target port
			if ((ports[i].req_ver_major > SVIO_IMPL_VER_MAJOR)) {
				return -1;
			} else if ((ports[i].req_ver_major == SVIO_IMPL_VER_MAJOR)
			        && (ports[i].req_ver_minor > SVIO_IMPL_VER_MINOR)) {
				return -1;
			}

			// Check if a TXR2 or TXR4 peripheral is connected to the wrong port
			if ((ports[i].port_attr ^ ports[i].attr) & SZG_ATTR_TXR4) {
				return -1;
			}

			// Check the interval pointed to by rangePtr.
			vmin = ports[i].ranges[rangePtrs[i]].min;
			vmax = ports[i].ranges[rangePtrs[i]].max;
			//Good for debugging:
			//printf("\nSolution vmin: %d, vmax %d\n", vmin, vmax);
			if ((vmin == 0) && (vmax == 0)) {
				continue;
			}

			// If the intervals overlap, constrain the solution interval [fmin,fmax].
			// Otherwise, we declare no match.
			if ((fmin <= vmax) && (vmin <= fmax)) {
				fmin = szgMAX(fmin, vmin);
				fmax = szgMIN(fmax, vmax);
			} else {
				fmin = 0;
				break;
			}
		}
		if (fmin != 0) {
			return(fmin);
		}

		// Move to the next interval combination.
		for (i=0; i<SVIO_NUM_PORTS; i++) {
			rangePtrs[i]++;
			if (rangePtrs[i] >= ports[i].range_count) {
				rangePtrs[i] = 0;
			} else {
				break;
			}
		}
		// If the loop reaches the end, we've run through all combinations.
		// And alas, we haven't found a match.
		if (SVIO_NUM_PORTS == i) {
			fmin = 0;
			break;
		}
	}
	return(-1);
}

