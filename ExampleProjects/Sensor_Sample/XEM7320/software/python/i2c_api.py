#!/usr/bin/env python
"""FrontPanel I2C controller

Port of the I2C controller class from C++. This is intended to be used with
the open source FrontPanel I2C Controller from Opal Kelly.
"""

from __future__ import print_function
import ok
import time


MaxBufferLength = 64

I2C_TRIGIN = 0x40
I2C_TRIGOUT = 0x60
I2C_WIREIN_DATA = 0x01
I2C_WIREOUT_DATA = 0x20

I2C_TRIGIN_GO = 0
I2C_TRIGIN_MEM_RESET = 1
I2C_TRIGIN_MEM_WRITE = 2
I2C_TRIGIN_MEM_READ = 3
I2C_TRIGOUT_DONE = 0

I2C_MAX_TIMEOUT_MS = 250


class I2C:

    m_pBuf = bytearray(MaxBufferLength)
    m_nDataStart = 0
    m_dev = None

    def __init__(self, dev):
        self.m_dev = dev

    def Configure(self, starts, stops, preamble):
        """ Setup the I2C hardware for a transaction

        STARTS - Defines the preamble bytes after which a start bit is
             transmitted. For example, if STARTS=0x04, a start bit is
             transmitted after the 3rd preamble byte.
        STOPS - Defines the preamble bytes after which a stop bit is
             transmitted. For example, if STOPS=0x04, a stop bit is
             transmitted after the 3rd preamble byte.
        LENGTH - Length of the preamble in bytes.

        Note: If there is a one in the same position for both STARTS and STOPS,
              the stop takes precedence.

        Returns 0 on success, -1 on error.
        """
        if (not self.m_dev.IsOpen()):
            return -1
        if (len(preamble) > 7):
            return -1

        self.m_pBuf[0] = len(preamble)
        self.m_pBuf[1] = starts
        self.m_pBuf[2] = stops
        self.m_pBuf[3] = 0

        for i in range(0, len(preamble)):
            self.m_pBuf[4+i] = preamble[i]

        i += 1
        self.m_nDataStart = 4+i

        return 0

    def Transmit(self, data):
        """ Transmit data over I2C

        Transmits bytes stored in byte array `data` over the I2C interface.

        Returns 0 on success, -1 on error.
        """
        if (not self.m_dev.IsOpen()):
            return -1
        if (0 == len(data)):
            return -1
        if ((self.m_nDataStart + len(data)) >= MaxBufferLength):
            return -1

        self.m_pBuf[3] = len(data)

        for i in range(0, len(data)):
            self.m_pBuf[self.m_nDataStart + i] = data[i]

        self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET)

        for i in range(0, len(data) + self.m_nDataStart):
            self.m_dev.SetWireInValue(I2C_WIREIN_DATA, self.m_pBuf[i], 0x00FF)
            self.m_dev.UpdateWireIns()
            self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_WRITE)

        self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_GO)

        # Wait for transaction to finish
        for i in range(0, I2C_MAX_TIMEOUT_MS//10):
            self.m_dev.UpdateTriggerOuts()
            if (self.m_dev.IsTriggered(I2C_TRIGOUT, (1 << I2C_TRIGOUT_DONE))):
                return

            time.sleep(0.01)

        return -1

    def Receive(self, data):
        """ Receive data over I2C

        Instructs the I2C core to read data over the I2C interface. The number
        of bytes read is derived from the size of byte array `data`

        Returns 0 on success, -1 on error.
        """
        if (not self.m_dev.IsOpen()):
            return -1
        if (0 == len(data)):
            return -1
        if ((self.m_nDataStart + len(data)) >= MaxBufferLength):
            return -1

        self.m_pBuf[0] |= 0x80
        self.m_pBuf[3] = len(data)

        # Transfer preamble buffer
        self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET)

        for i in range(0, self.m_nDataStart):
            self.m_dev.SetWireInValue(I2C_WIREIN_DATA, self.m_pBuf[i], 0x00FF)
            self.m_dev.UpdateWireIns()
            self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_WRITE)

        # Start I2C Transaction
        self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_GO)

        # Wait for transaction to finish
        for i in range(0, I2C_MAX_TIMEOUT_MS//10):
            self.m_dev.UpdateTriggerOuts()
            if (self.m_dev.IsTriggered(I2C_TRIGOUT, (1 << I2C_TRIGOUT_DONE))
                  is False):
                self.m_dev.ActivateTriggerIn(I2C_TRIGIN, I2C_TRIGIN_MEM_RESET)

                for i in range(0, len(data)):
                    self.m_dev.UpdateWireOuts()
                    data[i] = self.m_dev.GetWireOutValue(I2C_WIREOUT_DATA)
                    self.m_dev.ActivateTriggerIn(I2C_TRIGIN,
                                                 I2C_TRIGIN_MEM_READ)

                return

            time.sleep(0.01)

        return -1
