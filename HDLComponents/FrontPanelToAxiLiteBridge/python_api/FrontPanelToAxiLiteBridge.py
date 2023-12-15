# ----------------------------------------------------------------------------------------
# Copyright (c) 2023 Opal Kelly Incorporated
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# ----------------------------------------------------------------------------------------

import time
import ok
from dataclasses import dataclass

class FrontPanelToAxiLiteBridge:
    """
    Implements a simple Read/Write API for AXI-Lite Transactions.

    This class provides an API for executing read and write transactions on an AXI-Lite bus.
    It serves as a bridge between FrontPanel endpoints and the gateware controller, which
    provides an AXI-Lite master interface.

    Constants:
        NS_PER_FRONTPANEL_CLOCK_PERIOD (float): Nanoseconds per clock period in the FrontPanel clock domain.
        MS_TO_NS (float): Constant to convert milliseconds to nanoseconds.
        STATUS_CHECK_INTERVAL_MS (int): Interval in milliseconds to check the status in operations.
        GATEWARE_HANDSHAKE_DELAY_MS (int): Total milliseconds for gateware command transmission and response.
            Specifies the combined duration in milliseconds accounting for both the time taken for the 
            command to reach the gateware and the additional wait time post `hardware_timeout_ms` for 
            a response. This period is crucial for ensuring gateware has enough time to process and 
            respond, particularly when a `0b100` code, indicating a hardware timeout event, is expected.
            Absence of a response within this extended timeframe suggests a system fault. Default wait 
            is set to 1000 ms. If `hardware_timeout_ms` is zero, the system waits indefinitely.
    """
    NS_PER_FRONTPANEL_CLOCK_PERIOD = 9.920
    MS_TO_NS = 1e6
    STATUS_CHECK_INTERVAL_MS = 10 
    GATEWARE_HANDSHAKE_DELAY_MS = 1000 

    class HardwareTimeoutException(Exception):
        """
        Occurs when a hardware timeout is encountered in the loop in the gateware,
        typically due to a non-responsive slave. This can lead to a system-wide hang
        in the AXI system.

        Handling Instructions
        ---------------------
        On catching this exception, reset the entire AXI system to resolve the hang
        and restore normal operation.
        """
        def __init__(self):
            super().__init__("Hardware timeout in gateware due to non-responsive slave. Reset AXI system to resolve.")

    class ResponseException(Exception):
        """
        Exception for handling gateware response errors.

        This exception is thrown in two main scenarios:
        1. If the software does not receive the expected `0b100` hardware timeout code from the gateware
           within the total duration combining `hardware_timeout_ms` and `GATEWARE_HANDSHAKE_DELAY_MS`.
           `GATEWARE_HANDSHAKE_DELAY_MS` accounts for both the time taken for a command to reach the gateware
           and the subsequent response time.
        2. If the gateware responds back to the software with an unknown error code.

        Handling Instructions
        ---------------------
        This exception generally indicates a need to review and verify system configurations,
        especially endpoint addresses. It's not intended for run-time resolution but rather for
        identifying and correcting setup mismatches or errors.
        """
        def __init__(self):
            super().__init__("Gateware response error: Can indicate a configuration issue. Review system endpoint addresses. Not intended for runtime recovery.")

    class Response:
        """
        Enumeration of possible AXI bus responses.

        These responses are part of the AXI specification, representing various types of errors
        encountered during data transactions on the AXI bus.

        Attributes:
            OKAY (int): Access was successful.
            SLVERR (int): Slave error. Access reached the slave successfully, but the slave returned an error.
            DECERR (int): Decode error. Indicates no slave at the transaction address.

        Note:
            'EXOKAY' (0b01) response is not allowed by the AXI-Lite specification.
        """
        OKAY = 0b00
        SLVERR = 0b10
        DECERR = 0b11


    @dataclass
    class WireInAddresses:
        """
        Configuration for WireIn endpoint addresses required by the gateware controller.
        Address range: 0x00 – 0x1F.
        """
        address: int
        data: int
        timeout: int

    @dataclass
    class WireOutAddresses:
        """
        Configuration for WireOut endpoint addresses required by the gateware controller.
        Address range: 0x20 – 0x3F.
        """
        data: int
        status: int

    @dataclass
    class TriggerInAddressAndOffsets:
        """
        Configuration for Trigger In endpoints.
        Address range: 0x40 – 0x5F.
        This structure specifies the address location and bit offsets on a 32-bit bus
        for the single TriggerIn endpoint required by the gateware controller. The
        'address' field specifies the endpoint address. The 'writeBitOffset' and
        'readBitOffset' fields represent the bit positions on the 32-bit bus for
        one clock cycle pulses to initiate write or read operations.
        """
        address: int
        write_bit_offset: int
        read_bit_offset: int

    @dataclass
    class Configuration:
        """
        Configuration for the FrontPanelToAxiLiteBridge.

        Attributes:
            fpdev (ok.okCFrontPanel): Pointer to the FrontPanel device's instance.
            wire_in_addresses (WireInAddresses): Configuration for WireIn endpoint addresses required by the gateware controller.
            wire_out_addresses (WireOutAddresses): Configuration for WireOut endpoint addresses required by the gateware controller.
            trigger_in_address_and_offsets (TriggerInAddressAndOffsets): Configuration for Trigger In endpoints, specifying the address location and bit offsets on a 32-bit bus for the TriggerIn endpoint.
            hardware_timeout_ms (int): Hardware timeout in gateware loop, waiting for slave response; zero for indefinite wait.
        """
        fpdev: ok.okCFrontPanel
        wire_in_addresses: "WireInAddresses"
        wire_out_addresses: "WireOutAddresses"
        trigger_in_address_and_offsets: "TriggerInAddressAndOffsets"
        hardware_timeout_ms: int

    def __init__(self, configuration):
        """
        Constructs an FrontPanelToAxiLiteBridge instance using the provided configuration.
        Args:
            configuration (Configuration): Configuration data.
        """
        self._configuration = configuration
        timeout_clock_periods = int((configuration.hardware_timeout_ms * self.MS_TO_NS) / self.NS_PER_FRONTPANEL_CLOCK_PERIOD)
        self._configuration.fpdev.SetWireInValue(self._configuration.wire_in_addresses.timeout, timeout_clock_periods)
        self._configuration.fpdev.UpdateWireIns()

    def read(self, address):
        """
        Reads data from a given AXI-Lite address.

        Args:
            address (int): The AXI-Lite address to read from.

        Returns:
            tuple: A pair of (response, data) where:
                   - response (Response): The status of the read transaction, as an instance of the Response enumeration.
                   - data (int): The read value from the address.

        Raises:
            ResponseException: See the ResponseException documentation for more information.
            ValueError: If address is not a 32-bit integer.
        """
        start = time.time()

        self._configuration.fpdev.SetWireInValue(self._configuration.wire_in_addresses.address, address)
        self._configuration.fpdev.UpdateWireIns()
        self._configuration.fpdev.ActivateTriggerIn(self._configuration.trigger_in_address_and_offsets.address, self._configuration.trigger_in_address_and_offsets.read_bit_offset)

        self._configuration.fpdev.UpdateWireOuts()
        raw_status = self._configuration.fpdev.GetWireOutValue(self._configuration.wire_out_addresses.status)

        while raw_status & 1 != 0:
            if self._configuration.hardware_timeout_ms != 0:
                elapsed_ms = (time.time() - start) * 1000
                if elapsed_ms > (self._configuration.hardware_timeout_ms + self.GATEWARE_HANDSHAKE_DELAY_MS):
                    raise self.ResponseException()

            time.sleep(self.STATUS_CHECK_INTERVAL_MS / 1000)
            self._configuration.fpdev.UpdateWireOuts()
            raw_status = self._configuration.fpdev.GetWireOutValue(self._configuration.wire_out_addresses.status)

        response_bits = (raw_status >> 1) & 0b111

        if response_bits == 0b000:
            data = self._configuration.fpdev.GetWireOutValue(self._configuration.wire_out_addresses.data)
            return self.Response.OKAY, data
        elif response_bits == 0b010:
            return self.Response.SLVERR, None
        elif response_bits == 0b011:
            return self.Response.DECERR, None
        elif response_bits == 0b100:
            raise self.HardwareTimeoutException()
        else:
            raise self.ResponseException()

    def write(self, address, data):
        """
        Writes data to a given AXI-Lite address.

        Args:
            address (int): The AXI-Lite address to write to.
            data (int): The data to be written.

        Returns:
            Response: The status of the write transaction.

        Raises:
            ResponseException: See the ResponseException documentation for more information.
            ValueError: If address or data is not a 32-bit integer.
        """
        start = time.time()

        self._configuration.fpdev.SetWireInValue(self._configuration.wire_in_addresses.address, address)
        self._configuration.fpdev.SetWireInValue(self._configuration.wire_in_addresses.data, data)
        self._configuration.fpdev.UpdateWireIns()
        self._configuration.fpdev.ActivateTriggerIn(self._configuration.trigger_in_address_and_offsets.address, self._configuration.trigger_in_address_and_offsets.write_bit_offset)

        self._configuration.fpdev.UpdateWireOuts()
        raw_status = self._configuration.fpdev.GetWireOutValue(self._configuration.wire_out_addresses.status)

        while raw_status & 1 != 0:
            if self._configuration.hardware_timeout_ms != 0:
                elapsed_ms = (time.time() - start) * 1000
                if elapsed_ms > (self._configuration.hardware_timeout_ms + self.GATEWARE_HANDSHAKE_DELAY_MS):
                    raise self.ResponseException()

            time.sleep(self.STATUS_CHECK_INTERVAL_MS / 1000)
            self._configuration.fpdev.UpdateWireOuts()
            raw_status = self._configuration.fpdev.GetWireOutValue(self._configuration.wire_out_addresses.status)

        response_bits = (raw_status >> 1) & 0b111
        
        if response_bits == 0b000:
            return self.Response.OKAY
        elif response_bits == 0b010:
            return self.Response.SLVERR
        elif response_bits == 0b011:
            return self.Response.DECERR
        elif response_bits == 0b100:
            raise self.HardwareTimeoutException()
        else:
            raise self.ResponseException()
