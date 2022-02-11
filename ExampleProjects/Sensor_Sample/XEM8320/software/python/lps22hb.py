#!/usr/bin/env python
"""Test communication with the LPS22HB sensor component"""

from __future__ import print_function
import ok
from spi_api import SPI
import time


def twos_comp(val, bits):
    # Compute two's complement of val and return it
    if (val & (1 << (bits - 1))):
        val = val - (1 << bits)
    return val


def LPS22HBTest(dev):
    # Quick and dirty reading of the temp and pressure from the LPS22HB sensor
    lps22hb = SPI(dev, 0x03, 0x24, 0x42, 1)

    print("LPS22HB WHO_AM_I: ", hex(lps22hb.ReadByte(0x0F)))

    # One-shot capture
    lps22hb.WriteByte(0x11, 0x01)
    time.sleep(0.1)
    pressure_val = (lps22hb.ReadByte(0x2A) << 16) \
        | (lps22hb.ReadByte(0x29) << 8) | (lps22hb.ReadByte(0x28))
    pressure_val = twos_comp(pressure_val, 24)

    pressure_hPa = float(pressure_val) / 4096

    print("LPS22HB Pressure: ", pressure_hPa, " hPa")

    temp_val = (lps22hb.ReadByte(0x2C) << 8) | (lps22hb.ReadByte(0x2B))
    temp_val = twos_comp(temp_val, 16)

    temp_C = float(temp_val) / 100

    print("LPS22HB Temp: ", temp_C, " C")
