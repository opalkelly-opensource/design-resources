#!/usr/bin/env python
"""Test communication with the HTS221 sensor component"""

from __future__ import print_function
import ok
from spi_api import SPI


def twos_comp(val, bits):
    # Compute two's complement of val and return it
    if (val & (1 << (bits - 1))):
        val = val - (1 << bits)
    return val


def HTS221Test(dev):
    # Quick and dirty reading of the temp and humidity form the HTS221 sensor
    hts221 = SPI(dev, 0x02, 0x23, 0x42, 0)

    print("HTS221 WHO_AM_I: ", hex(hts221.ReadByte(0x0F)))

    # Configure HTS221 for lowest temp/humidity noise
    #   (average 256 samples internally)
    hts221.WriteByte(0x10, 0x3F)

    # Power up HTS221 and constantly read Humidity/Temp data
    hts221.WriteByte(0x20, 0x83)

    # Grab Temp calibration data
    calib_T0_c = hts221.ReadByte(0x32)
    calib_T0_c = calib_T0_c | ((hts221.ReadByte(0x35) & 3) << 8)
    calib_T0_c /= 8

    calib_T1_c = hts221.ReadByte(0x33)
    calib_T1_c = calib_T1_c | ((hts221.ReadByte(0x35) & 0xC) << 6)
    calib_T1_c /= 8

    calib_T0 = hts221.ReadByte(0x3C) | (hts221.ReadByte(0x3D) << 8)
    calib_T0 = twos_comp(calib_T0, 16)
    calib_T1 = hts221.ReadByte(0x3E) | (hts221.ReadByte(0x3F) << 8)
    calib_T1 = twos_comp(calib_T1, 16)

    # Grab current temp
    temperature_val = hts221.ReadByte(0x2A) | (hts221.ReadByte(0x2B) << 8)
    temperature_val = twos_comp(temperature_val, 16)

    temp_scale = (float((calib_T1_c - calib_T0_c))
                  / float((calib_T1 - calib_T0)))
    temp_offset = float(calib_T0_c) - (temp_scale * float(calib_T0))

    temperature_c = (temperature_val * temp_scale) + temp_offset
    print("HTS221 Current Temp: ", temperature_c, " C")

    # Grab humidity calibration
    calib_H0_rH = hts221.ReadByte(0x30)
    calib_H0_rH /= 2
    calib_H1_rH = hts221.ReadByte(0x31)
    calib_H1_rH /= 2

    calib_H0 = hts221.ReadByte(0x36) | (hts221.ReadByte(0x37) << 8)
    calib_H0 = twos_comp(calib_H0, 16)

    calib_H1 = hts221.ReadByte(0x3A) | (hts221.ReadByte(0x3B) << 8)
    calib_H1 = twos_comp(calib_H1, 16)

    # Grab current humidity
    humidity_val = hts221.ReadByte(0x28) | (hts221.ReadByte(0x29) << 8)
    humidity_val = twos_comp(humidity_val, 16)

    humidity_scale = ((float(calib_H1_rH) - float(calib_H0_rH))
                      / (float(calib_H1) - float(calib_H0)))
    humidity_offset = float(calib_H0_rH) - (humidity_scale * float(calib_H0))

    humidity_rH = (humidity_val * humidity_scale) + humidity_offset
    print("HTS221 Current Humidity: ", humidity_rH, "%")
