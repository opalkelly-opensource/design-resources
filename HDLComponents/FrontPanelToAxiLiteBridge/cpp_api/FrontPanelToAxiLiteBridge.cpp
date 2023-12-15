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

#include <iostream>
#include <stdexcept>
#include <chrono>
#include "okFrontPanel.h"
#include "FrontPanelToAxiLiteBridge.h"

#if defined(_WIN32)
#include <windows.h>
#define strncpy strncpy_s
#define sscanf  sscanf_s
#endif
#if defined(__linux__) || defined(__APPLE__)
#include <unistd.h>
#define Sleep(ms)   usleep(ms*1000)
#endif
#if defined(__QNX__)
#include <unistd.h>
#define Sleep(ms)   usleep((useconds_t) (ms*1000));
#endif

FrontPanelToAxiLiteBridge::FrontPanelToAxiLiteBridge(const Configuration& configuration)
    : m_configuration(configuration) {

    int timeout_clock_periods = static_cast<int>((m_configuration.hardware_timeout_ms * MS_TO_NS) / NS_PER_FRONTPANEL_CLOCK_PERIOD);
    m_configuration.fpdev->SetWireInValue(m_configuration.wireInAddresses.timeout, timeout_clock_periods);
    m_configuration.fpdev->UpdateWireIns();
}

FrontPanelToAxiLiteBridge::Response FrontPanelToAxiLiteBridge::Read(const uint32_t address, uint32_t& data) {
    auto start = std::chrono::steady_clock::now();

    m_configuration.fpdev->SetWireInValue(m_configuration.wireInAddresses.address, address);
    m_configuration.fpdev->UpdateWireIns();
    m_configuration.fpdev->ActivateTriggerIn(m_configuration.triggerInAddressAndOffsets.address, m_configuration.triggerInAddressAndOffsets.readBitOffset);

    m_configuration.fpdev->UpdateWireOuts();
    uint32_t raw_status = m_configuration.fpdev->GetWireOutValue(m_configuration.wireOutAddresses.status);

    while ((raw_status & 1) != 0) {
        if (m_configuration.hardware_timeout_ms != 0) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();

            if (elapsed_ms > (m_configuration.hardware_timeout_ms + GATEWARE_HANDSHAKE_DELAY_MS)) {
                throw ResponseException();
            }
        }

        Sleep(STATUS_CHECK_INTERVAL_MS);

        m_configuration.fpdev->UpdateWireOuts();
        raw_status = m_configuration.fpdev->GetWireOutValue(m_configuration.wireOutAddresses.status);
    }

    uint32_t responseBits = (raw_status >> 1) & 0b111;  // Extract bits 3:1
    
    switch (responseBits) {
        case 0b000:
            data = m_configuration.fpdev->GetWireOutValue(m_configuration.wireOutAddresses.data);
            return Response::OKAY;
        case 0b010:
            return Response::SLVERR;
        case 0b011:
            return Response::DECERR;
        case 0b100:
            throw HardwareTimeoutException();
        default:
            // Handle unexpected response
            throw ResponseException();
    }
}

FrontPanelToAxiLiteBridge::Response FrontPanelToAxiLiteBridge::Write(const uint32_t address, const uint32_t data) {
    auto start = std::chrono::steady_clock::now();

    m_configuration.fpdev->SetWireInValue(m_configuration.wireInAddresses.address, address);
    m_configuration.fpdev->SetWireInValue(m_configuration.wireInAddresses.data, data);
    m_configuration.fpdev->UpdateWireIns();
    m_configuration.fpdev->ActivateTriggerIn(m_configuration.triggerInAddressAndOffsets.address, m_configuration.triggerInAddressAndOffsets.writeBitOffset);

    m_configuration.fpdev->UpdateWireOuts();
    uint32_t raw_status = m_configuration.fpdev->GetWireOutValue(m_configuration.wireOutAddresses.status);

    while ((raw_status & 1) != 0) {
        if (m_configuration.hardware_timeout_ms != 0) {
            auto now = std::chrono::steady_clock::now();
            auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();

            if (elapsed_ms > (m_configuration.hardware_timeout_ms + GATEWARE_HANDSHAKE_DELAY_MS)) {
                throw ResponseException();
            }
        }

        Sleep(STATUS_CHECK_INTERVAL_MS);

        m_configuration.fpdev->UpdateWireOuts();
        raw_status = m_configuration.fpdev->GetWireOutValue(m_configuration.wireOutAddresses.status);
    }
    
    uint32_t responseBits = (raw_status >> 1) & 0b111;  // Extract bits 3:1
    
    switch (responseBits) {
        case 0b000:
            return Response::OKAY;
        case 0b010:
            return Response::SLVERR;
        case 0b011:
            return Response::DECERR;
        case 0b100:
            throw HardwareTimeoutException();
        default:
            // Handle unexpected response
            throw ResponseException();
    }
}
