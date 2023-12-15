// ----------------------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
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
// ----------------------------------------------------------------------------------------

#ifndef FrontPanelToAxiLiteBridge_H
#define FrontPanelToAxiLiteBridge_H

#include <stdexcept>
#include <cstdint>

/**
 * @class FrontPanelToAxiLiteBridge
 * @brief Implements a simple Read/Write API for AXI-Lite Transactions.
 * 
 *  This class provides an API for executing read and write transactions on an AXI-Lite bus.
 *  It serves as a bridge between FrontPanel endpoints and the gateware controller, which
 *  provides an AXI-Lite master interface.
 */
class FrontPanelToAxiLiteBridge {
public:
    static constexpr double NS_PER_FRONTPANEL_CLOCK_PERIOD = 9.920; ///< Nanoseconds per clock period in the FrontPanel clock domain.
    static constexpr double MS_TO_NS = 1e6;             ///< Constant to convert milliseconds to nanoseconds.
    static constexpr int STATUS_CHECK_INTERVAL_MS = 10; ///< Interval in milliseconds to check the status in operations.
        
    /**
     * @brief Total milliseconds for gateware command transmission and response.
     * 
     * @details Specifies the combined duration in milliseconds accounting for both the time taken for the 
     * command to reach the gateware and the additional wait time post `hardware_timeout_ms` for 
     * a response. This period is crucial for ensuring gateware has enough time to process and 
     * respond, particularly when a `0b100` code, indicating a hardware timeout event, is expected.
     * Absence of a response within this extended timeframe suggests a system fault. Default wait 
     * is set to 1000 ms. If `hardware_timeout_ms` is zero, the system waits indefinitely.
     */
    static constexpr int GATEWARE_HANDSHAKE_DELAY_MS = 1000;
        
    /**
     * @class HardwareTimeoutException
     * @brief Occurs when a hardware timeout is encountered in the loop in the gateware, 
     *        typically due to a non-responsive slave. This can lead to a system-wide hang 
     *        in the AXI system.
     *
     * Handling Instructions
     * ---------------------
     *        On catching this exception, reset the entire AXI system to resolve the hang 
     *        and restore normal operation.
     */
    class HardwareTimeoutException : public std::exception {};

    /**
     * @class ResponseException
     * @brief Exception for handling gateware response errors.
     *
     * This exception is thrown in two main scenarios:
     * 1. If the software does not receive the expected `0b100` hardware timeout code from the gateware 
     *    within the total duration combining `hardware_timeout_ms` and `GATEWARE_HANDSHAKE_DELAY_MS`. 
     *    `GATEWARE_HANDSHAKE_DELAY_MS` accounts for both the time taken for a command to reach the gateware 
     *    and the subsequent response time.
     * 2. If the gateware responds back to the software with an unknown error code.
     *
     * Handling Instructions
     * ---------------------
     * This exception generally indicates a need to review and verify system configurations, 
     * especially endpoint addresses. It's not intended for run-time resolution but rather for 
     * identifying and correcting setup mismatches or errors.
     */
    class ResponseException : public std::exception {};

    /**
     * @enum Response
     * @brief Enumeration of possible AXI bus responses.
     * 
     * These responses are part of the AXI specification, representing various types of errors
     * encountered during data transactions on the AXI bus.
     * 
     * Note: 'EXOKAY' (0b01) response not allowed by AXI-Lite specification.
     */
    enum class Response {
        OKAY = 0b00,  ///<  Access was successful.
        SLVERR = 0b10,  ///< Slave error: Access reached the slave successfully, but the slave returned an error.
        DECERR = 0b11   ///< Decode error: Indicates no slave at the transaction address.
    };
    
    /**
     * @struct WireInAddresses
     * @brief Configuration for WireIn endpoint addresses required by the gateware controller. 
     *        Address range: 0x00 – 0x1F.
     */
    struct WireInAddresses {
        int address;
        int data;
        int timeout;
    };

    /**
     * @struct WireOutAddresses
     * @brief Configuration for WireOut endpoint addresses required by the gateware controller. 
     *        Address range: 0x20 – 0x3F.
     */
    struct WireOutAddresses {
        int data;
        int status;
    };

    /**
     * @struct TriggerInAddressAndOffsets
     * @brief Configuration for Trigger In endpoints.
     *        Address range: 0x40 – 0x5F.
     *        This structure specifies the address location and bit offsets on a 32-bit bus
     *        for the single TriggerIn endpoint required by the gateware controller. The
     *        'address' field specifies the endpoint address. The 'writeBitOffset' and
     *        'readBitOffset' fields represent the bit positions on the 32-bit bus for
     *        one clock cycle pulses to initiate write or read operations.
     */
    struct TriggerInAddressAndOffsets {
        int address;
        int writeBitOffset;
        int readBitOffset;
    };

    /**
     * @struct Configuration
     * @brief Configuration for the FrontPanelToAxiLiteBridge.
     */
    struct Configuration {
        okCFrontPanel* fpdev; ///< Pointer to the FrontPanel device's instance.
        WireInAddresses wireInAddresses; ///< See documentation for WireInAddresses structure.
        WireOutAddresses wireOutAddresses; ///< See documentation for WireOutAddresses structure.
        TriggerInAddressAndOffsets triggerInAddressAndOffsets; ///< See documentation for TriggerInAddressAndOffsets structure.
        int hardware_timeout_ms; ///< Hardware timeout in gateware loop, waiting for slave response; zero for indefinite wait.
    };

    /**
     * Constructs an FrontPanelToAxiLiteBridge instance using the provided configuration.
     * @param configuration Configuration data.
     */
    FrontPanelToAxiLiteBridge(const Configuration& configuration);
    
    /**
     * @brief Reads data from a given AXI-Lite address.
     * @param address The AXI-Lite address to read from.
     * @param data Reference to store the read data.
     * @return Response indicating the status of the read transaction.
     * @throws ResponseException See the ResponseException documentation for more information.
     */
    Response Read(const uint32_t address, uint32_t& data);

    /**
     * @brief Writes data to a given AXI-Lite address.
     * @param address The AXI-Lite address to write to.
     * @param data The data to be written.
     * @return Response indicating the status of the write transaction.
     * @throws ResponseException See the ResponseException documentation for more information.
     */
    Response Write(const uint32_t address, const uint32_t data);

private:   
    Configuration m_configuration;     ///< Configuration struct containing the device and endpoint configuration.
};

#endif // FrontPanelToAxiLiteBridge_H
