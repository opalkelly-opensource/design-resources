#!/usr/bin/env python
"""FrontPanel SPI controller

This is intended to be used with the open source FrontPanel SPI Controller from
Opal Kelly.
"""

import time
import ok

SPI_TIMEOUT = 1000


class SPI:
    m_dev = None
    wireInAddr = 0x00
    wireOutAddr = 0x00
    triggerInAddr = 0x00
    startTriggerBit = 0x00

    def __init__(self, dev, wireInAddr, wireOutAddr, triggerInAddr,
                 startTriggerBit):
        self.m_dev = dev
        self.wireInAddr = wireInAddr
        self.wireOutAddr = wireOutAddr
        self.triggerInAddr = triggerInAddr
        self.startTriggerBit = startTriggerBit

    def WriteByte(self, regAddr, data):
        if (not self.m_dev.IsOpen()):
            return -1

        for i in range(0, SPI_TIMEOUT):
            self.m_dev.UpdateWireOuts()

            if (self.m_dev.GetWireOutValue(self.wireOutAddr) & 0x100):
                break

        if (i == SPI_TIMEOUT):
            return -2

        self.m_dev.SetWireInValue(self.wireInAddr, (regAddr << 8) | data)
        self.m_dev.UpdateWireIns()
        self.m_dev.ActivateTriggerIn(self.triggerInAddr, self.startTriggerBit)

        return 0

    def ReadByte(self, regAddr):
        if (not self.m_dev.IsOpen()):
            return -1

        for i in range(0, SPI_TIMEOUT):
            self.m_dev.UpdateWireOuts()

            if (self.m_dev.GetWireOutValue(self.wireOutAddr) & 0x100):
                break

        if (i == SPI_TIMEOUT):
            return -2

        self.m_dev.SetWireInValue(self.wireInAddr, 0x8000 | (regAddr << 8))
        self.m_dev.UpdateWireIns()
        self.m_dev.ActivateTriggerIn(self.triggerInAddr, self.startTriggerBit)

        for i in range(0, SPI_TIMEOUT):
            self.m_dev.UpdateWireOuts()
            ret = self.m_dev.GetWireOutValue(self.wireOutAddr)

            if (ret & 0x100):
                return ret & 0xFF

        return -2  # Timeout
