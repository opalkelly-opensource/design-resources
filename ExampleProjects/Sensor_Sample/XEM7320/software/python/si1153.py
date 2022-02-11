#!/usr/bin/env python
"""Test communication with the Si1153 sensor component

This demo configures the Si1153 to drive a series of IR LEDs in bursts and
then reads from the internal ambient light sensor to get a proximity sense
reading.
"""

from __future__ import print_function
import ok
import time
from i2c_api import I2C


def i2cReadByte(i2c_dev, i2c_addr, i2c_reg):
    # Helper function to read a single byte over I2C
    preamble = bytearray([i2c_addr, i2c_reg, i2c_addr + 1])

    starts = 0x02
    stops = 0x00

    i2c_dev.Configure(starts, stops, preamble)

    data = bytearray(1)  # Receive 2 bytes
    i2c_dev.Receive(data)

    return data[0]


def i2cWriteByte(i2c_dev, i2c_addr, i2c_reg, data):
    # Helper function to write a single byte over I2C
    preamble = bytearray([i2c_addr, i2c_reg])

    starts = 0x00
    stops = 0x00

    i2c_dev.Configure(starts, stops, preamble)
    temp_data = bytearray(1)
    temp_data[0] = data
    i2c_dev.Transmit(temp_data)


def Si1153ParamSet(i2c_dev, param_addr, data):
    # Helper function for writing to the Si1153 parameter space
    i2cWriteByte(i2c_dev, 0xA6, 0x0A, data)  # Write data to HOSTIN0

    # Write PARAM_SET command with parameter address
    i2cWriteByte(i2c_dev, 0xA6, 0x0B, 0x80 | param_addr)

    ret = i2cReadByte(i2c_dev, 0xA6, 0x11)
    if ((ret & 0x10) != 0x00):  # If bit 5 is set an error has occurred
        return ret

    return 0


def Si1153Test(dev):
    # Simple test of the Si1153 Proximity sensing functionality.
    i2c_dev = I2C(dev)

    print("Si1153 PART_ID: ", hex(i2cReadByte(i2c_dev, 0xA6, 0x00)))

    # Set Si1153 to use LED1
    ret = Si1153ParamSet(i2c_dev, 0x1F, 0x23)
    if (ret != 0):
        print("Error setting Si1153 LED1: ", ret)

    # Set Si1153 to use LED2
    ret = Si1153ParamSet(i2c_dev, 0x21, 0x23)
    if (ret != 0):
        print("Error setting Si1153 LED2: ", ret)

    # Set Si1153 to use LED3
    ret = Si1153ParamSet(i2c_dev, 0x23, 0x23)
    if (ret != 0):
        print("Error setting Si1153 LED3: ", ret)

    # Set Si1153 CHAN_LIST for channel 0 only
    ret = Si1153ParamSet(i2c_dev, 0x01, 0x01)
    if (ret != 0):
        print("Error setting Si1153 CHAN_LIST: ", ret)

    # Set Si1153 ADCCONFIG
    ret = Si1153ParamSet(i2c_dev, 0x02, 0x60)
    if (ret != 0):
        print("Error setting Si1153 ADCCONFIG0: ", ret)

    # Set Si1153 ADCSENS0
    ret = Si1153ParamSet(i2c_dev, 0x03, 0x06)
    if (ret != 0):
        print("Error setting Si1153 ADCSENS0: ", ret)

    # Set Si1153 MEASCONFIG0
    ret = Si1153ParamSet(i2c_dev, 0x05, 0x47)
    if (ret != 0):
        print("Error setting Si1153 MEASCONFIG0: ", ret)

    # Set Si1153 MEASRATE_L
    ret = Si1153ParamSet(i2c_dev, 0x1B, 0x7D)
    if (ret != 0):
        print("Error setting Si1153 MEASRATE_L: ", ret)

    # Enable Si1153
    i2cWriteByte(i2c_dev, 0xA6, 0x0B, 0x13)

    ret = i2cReadByte(i2c_dev, 0xA6, 0x11)

    if ((ret & 0x10) != 0):
        print("Error starting Si1153: ", ret)

    while True:
        als_val = (i2cReadByte(i2c_dev, 0xA6, 0x13) << 8) \
            | i2cReadByte(i2c_dev, 0xA6, 0x14)

        print("Ambient light sensor reading =", hex(als_val), end='\r')
        time.sleep(0.1)
