#!/usr/bin/env python
"""Test communication with the GNSS sensor component

This demo transmits a reset UBX command to the uBlox module over UART then
reads in and displays the raw NMEA messages from the module.
"""

from __future__ import print_function
import time
import sys
import ok


def GNSSUBXTransmit(dev, message):
    # Transmit a UBX message over UART
    ck_a = 0
    ck_b = 0

    # Calculate checksum
    for i in range(0, len(message)):
        ck_a = ck_a + message[i]
        ck_b = ck_b + ck_a

    data = bytearray(len(message) + 4)

    data[0] = 0xB5  # SYNC CHAR 1
    data[1] = 0x62  # SYNC CHAR 2

    for i in range(0, len(message)):
        data[i + 2] = message[i]

    i += 3
    data[i] = ck_a
    i += 1
    data[i] = ck_b

    # Transmit message
    for i in range(0, len(data)):
        dev.SetWireInValue(0x06, data[i], 0xFF)
        dev.UpdateWireIns()

        dev.ActivateTriggerIn(0x41, 0)

        dev.UpdateWireOuts()
        while (not (dev.GetWireOutValue(0x22) & 0x1000)):
            dev.UpdateWireOuts()


def GNSSTest(dev):
    # Reset the GNSS module then display raw NMEA messages in the terminal
    reset_message = bytearray([0x06, 0x04, 0x04, 0x00, 0x00, 0x00, 0x01, 0x00])
    temp_data = bytearray(512)

    time.sleep(1)

    # Toggle reset
    dev.SetWireInValue(0x00, 0x1, 0x1)
    dev.UpdateWireIns()

    dev.SetWireInValue(0x00, 0x0, 0x1)
    dev.UpdateWireIns()

    GNSSUBXTransmit(dev, reset_message)

    while True:
        # Check for UART data in buffer
        dev.UpdateWireOuts()

        temp = dev.GetWireOutValue(0x22)
        if ((temp & 0xFFF) > 128):
            # If there's enough data in the buffer, pipe it out
            dev.ReadFromPipeOut(0xA0, temp_data)

            for i in range(0, 128):
                for j in range(4, 0, -1):
                    sys.stdout.write(str(chr(temp_data[(4*i)+(j-1)])))

        sys.stdout.flush()
