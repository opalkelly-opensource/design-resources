#!/usr/bin/env python
"""Test communication with the LSM9DS1 sensor component"""

from __future__ import print_function
import ok
import time
from spi_api import SPI


def twos_comp(val, bits):
    # Compute two's complement of val and return it
    if (val & (1 << (bits - 1))):
        val = val - (1 << bits)
    return val


def LSM9DS1agTest(dev):
    # Quick and dirty reading of the accelerometer and gyroscope data from
    # the LSM9DS1
    lsm9ds1_ag = SPI(dev, 0x04, 0x25, 0x42, 2)

    print("LSM9DS1_AG WHO_AM_I: ", lsm9ds1_ag.ReadByte(0x0F))

    lsm9ds1_ag.WriteByte(0x10, 0x40)

    lsm9ds1_ag.WriteByte(0x20, 0x20)

    temp_val = (lsm9ds1_ag.ReadByte(0x16) << 8) | lsm9ds1_ag.ReadByte(0x15)
    temp_val = twos_comp(temp_val, 16)
    temp_C = (float(temp_val) / 16) + 25
    print("LSM9DS1_AG Temp: ", temp_C, " C")
    while True:
        out_x_g = (lsm9ds1_ag.ReadByte(0x19) << 8) | lsm9ds1_ag.ReadByte(0x18)
        out_y_g = (lsm9ds1_ag.ReadByte(0x1B) << 8) | lsm9ds1_ag.ReadByte(0x1A)
        out_z_g = (lsm9ds1_ag.ReadByte(0x1D) << 8) | lsm9ds1_ag.ReadByte(0x1C)

        out_x_xl = (lsm9ds1_ag.ReadByte(0x29) << 8) | lsm9ds1_ag.ReadByte(0x28)
        out_y_xl = (lsm9ds1_ag.ReadByte(0x2B) << 8) | lsm9ds1_ag.ReadByte(0x2A)
        out_z_xl = (lsm9ds1_ag.ReadByte(0x2D) << 8) | lsm9ds1_ag.ReadByte(0x2C)

        print("LSM9DS1_AG out_x_g = ", hex(out_x_g),
              " out_y_g = ", hex(out_y_g), " out_z_g = ", hex(out_z_g),
              " out_x_xl = ", hex(out_x_xl), " out_y_xl = ", hex(out_y_xl),
              " out_z_xl = ", hex(out_z_xl), end='\r')

        time.sleep(0.1)


def LSM9DS1mTest(dev):
    # Quick and dirty reading of the magnetometer data from the LSM9DS1
    lsm9ds1_m = SPI(dev, 0x05, 0x26, 0x42, 3)

    print("LSM9DS1_M WHO_AM_I: " + hex(lsm9ds1_m.ReadByte(0x0F)))

    # Set magnetometer to ultra-high performancemode, 10Hz data rate,
    # self test disabled
    lsm9ds1_m.WriteByte(0x20, 0xF0)

    # Set continuous conversion mode
    lsm9ds1_m.WriteByte(0x22, 0x00)

    # Enable Z-axis
    lsm9ds1_m.WriteByte(0x23, 0x0C)

    while True:
        out_x_m = (lsm9ds1_m.ReadByte(0x29) << 8) | lsm9ds1_m.ReadByte(0x28)
        out_y_m = (lsm9ds1_m.ReadByte(0x2B) << 8) | lsm9ds1_m.ReadByte(0x2A)
        out_z_m = (lsm9ds1_m.ReadByte(0x2D) << 8) | lsm9ds1_m.ReadByte(0x2C)

        print("LSM9DS1_M out_x_m = ", hex(out_x_m),
              " out_y_m = ", hex(out_y_m), " out_z_m = ", hex(out_z_m),
              "       ", end='\r')

        time.sleep(0.1)
