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
// Test Application for Opal Kelly FPGA and FrontPanelToAxiLiteBridge Operations
// ----------------------------------------------------------------------------------------
//
// Description:
//    This C++ application provides functionality to test the FrontPanelToAxiLiteBridge operations 
//    with an Opal Kelly FPGA device. It covers basic functionalities like initializing the 
//    FPGA, AXI read/write, bit manipulations, bit mask operations, and 
//    bitfield operations.
//
// Usage:
//    1. Plug in the Opal Kelly FPGA device.
//    2. Generate a bitfile for your Opal Kelly product using the "gateware" 
//       sources found in this repository.
//    3. Ensure the generated bitfile is located in the same directory as this script.
//    4. Compile and execute this application.
//
// Build Instructions:
//     - Linux Build Instructions:
//       - Use the provided `Makefile.lnx` for compilation.
//     - Windows Build Instructions (Visual Studio 2022):
//       1. Set the `okFP_SDK` environment variable to the location of the SDK’s API folder, i.e., `C:\Program Files\Opal Kelly\FrontPanelUSB\API`.
//       2. Open the `example.vxproj` file in Visual Studio 2022 and build it.
//
// Note:
//    Make sure the required libraries and dependencies are installed and properly set up.
//    For more information, see the official Opal Kelly documentation:
//    https://docs.opalkelly.com/fpsdk/frontpanel-api/programming-languages/
// ----------------------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <string.h>
#include <cassert>

#include "okFrontPanel.h"
#include "FrontPanelToAxiLiteBridge.h"

/**
 * @brief Base address for AXI GPIO.
 *
 * This macro defines the base memory address for the AXI General Purpose 
 * IO (GPIO) peripheral.
 */
#define AXI_GPIO_BASE_ADDRESS 0x00000000

/**
 * @brief Evaluates to true if `response` is not OKAY.
 * @param response Transaction Response to evaluate.
 * @return True for failure, false otherwise.
 */
#define FAILED(response) ((response) != FrontPanelToAxiLiteBridge::Response::OKAY)

/**
 * @brief Initialize the FPGA device.
 * 
 * @param bitfile_name Name of the bitfile to be used for FPGA configuration.
 * @return Returns a shared pointer to the opened device if successful, otherwise nullptr.
 * 
 * This function attempts to open the first available FPGA device and configure 
 * it using the specified bitfile. If successful, it also checks if FrontPanel 
 * support is enabled for the FPGA configuration.
 */
OpalKelly::FrontPanelPtr initializeFPGA(const std::string& bitfile_name)
{
    // Open the first device found
    OpalKelly::FrontPanelPtr dev = OpalKelly::FrontPanelDevices().Open();

    if (!dev.get()) {
        printf("Device could not be opened.  Is one connected?\n");
        return dev;
    }

    printf("Found a device: %s\n", dev->GetBoardModelString(dev->GetBoardModel()).c_str());

    // Get some general information about the XEM.
    std::string str;
    printf("Device firmware version: %d.%d\n", dev->GetDeviceMajorVersion(), dev->GetDeviceMinorVersion());
    str = dev->GetSerialNumber();
    printf("Device serial number: %s\n", str.c_str());
    str = dev->GetDeviceID();
    printf("Device device ID: %s\n", str.c_str());
    
    // Configure the FPGA with the provided bitfile name
    if (okCFrontPanel::NoError != dev->ConfigureFPGA(bitfile_name)) {
        printf("FPGA configuration failed.\n");
        dev.reset();
        return dev;
    }

    // Check for FrontPanel support in the FPGA configuration.
    if (dev->IsFrontPanelEnabled()) {
        printf("FrontPanel support is enabled.\n");
    } else {
        printf("FrontPanel support is not enabled.\n");
    }

    return dev;
}

/**
 * @brief Resets the AXI system using the Opal Kelly FrontPanel interface.
 * 
 * This function provides a system-specific reset for the AXI system, particularly useful in
 * scenarios where the system hangs. It leverages the Opal Kelly FrontPanel interface to 
 * initiate a reset sequence to AMD's Processor System Reset Module IP. This module 
 * handles the reset of the AXI system, ensuring compliance with AMD's reset guidelines.
 * According to AMD's AXI Reference Guide (UG1037), a reset pulse asserted for 16 cycles
 * of the slowest AXI clock is generally sufficient for resetting Xilinx IP. This function
 * encapsulates the necessary steps to trigger this reset process.
 *
 * @param fpdev A pointer to the OpalKelly::FrontPanel object, used to interact with the 
 *              FrontPanel hardware interface.
 */
void resetAxiSystem(OpalKelly::FrontPanel* fpdev)
{
    fpdev->SetWireInValue(0x00, 1);
    fpdev->UpdateWireIns();
    fpdev->SetWireInValue(0x00, 0);
    fpdev->UpdateWireIns();
}

/**
 * @brief Tests FrontPanelToAxiLiteBridge operations with an FPGA device.
 * 
 * Executes the following:
 * 1. Opens and initializes the first available FPGA device.
 * 2. Creates a FrontPanelToAxiLiteBridge instance.
 * 3. Tests AXI write and read functionalities with up to 3 retries.
 *    - If a HardwareTimeoutException is caught, resets the AXI system and retries.
 * 
 * @note FPGA device must be available before execution.
 * 
 * @return 0 on success, -1 on failure after 3 retries.
 */
int real_main(int argc, char* argv[]) {
    const std::string bitfilePath = "fp_to_axil_exdes_wrapper.bit";

    // Check if the bitfile exists
    std::ifstream file(bitfilePath);
    if (!file.is_open()) {
        std::cerr << "The bitfile '" << bitfilePath << "' does not exist. Please generate it from the sources provided within this repo and place the generated bitfile in this directory." << std::endl;
        return -1;
    }
    file.close();

    // Initialize the FPGA with our configuration bitfile.
    auto fpdev = initializeFPGA(bitfilePath);
    if (!fpdev) {
        std::cerr << "FPGA could not be initialized.\n";
        return -1;
    }

    FrontPanelToAxiLiteBridge::Configuration configuration;

    // Initialize okCFrontPanel pointer
    configuration.fpdev = fpdev.get();

    // Initialize WireInAddresses struct
    configuration.wireInAddresses.address = 0x1d;
    configuration.wireInAddresses.data = 0x1e;
    configuration.wireInAddresses.timeout = 0x1f;

    // Initialize WireOutAddresses struct
    configuration.wireOutAddresses.data = 0x3e;
    configuration.wireOutAddresses.status = 0x3f;

    // Initialize TriggerInAddressAndOffsets struct
    configuration.triggerInAddressAndOffsets.address = 0x5f;
    configuration.triggerInAddressAndOffsets.writeBitOffset = 0;
    configuration.triggerInAddressAndOffsets.readBitOffset = 1;

    // Initialize timeout
    configuration.hardware_timeout_ms = 3000;

    // Create the FrontPanelToAxiLiteBridge instance
    FrontPanelToAxiLiteBridge axi_lite_controller(configuration);


    // Write & Read Test with retry mechanism and fail after 3 attempts
    std::cout << "\nTesting: AXI Write & Read" << std::endl;

    bool success = false;
    int attempts = 0;
    const int max_attempts = 3;
    uint32_t return_data;

    while (!success && attempts < max_attempts) {
        try {
            attempts++;  // Increment attempt counter

            // Writing data to AXI GPIO base address
            FrontPanelToAxiLiteBridge::Response writeTransactionResult = axi_lite_controller.Write(AXI_GPIO_BASE_ADDRESS, 0x00000007);
            if (FAILED(writeTransactionResult)) {
                std::cerr << "AXI Write Error. Response Code: " << static_cast<int>(writeTransactionResult) << "\n";
                continue;  // Skip the rest of the loop and retry
            }

            // Reading data from AXI GPIO base address
            FrontPanelToAxiLiteBridge::Response readTransactionResult = axi_lite_controller.Read(AXI_GPIO_BASE_ADDRESS, return_data);
            if (FAILED(readTransactionResult)) {
                std::cerr << "AXI Read Error. Response Code: " << static_cast<int>(readTransactionResult) << "\n";
                continue;  // Skip the rest of the loop and retry
            }

            if (return_data == 0x00000007) {
                std::cout << "Success: Written: 0x00000007, Read: " << std::hex << return_data << std::endl;
                success = true;  // End the loop
            } else {
                std::cerr << "Error: Data mismatch. Expected: 0x00000007, Got: " << std::hex << return_data << std::endl;
                continue;  // Skip the rest of the loop and retry
            }
        } catch (const FrontPanelToAxiLiteBridge::HardwareTimeoutException&) {
            std::cerr << "Caught HardwareTimeoutException. Resetting AXI system and retrying..." << std::endl;
            resetAxiSystem(fpdev.get());
            // The loop will continue after reset
        }
    }

    if (!success) {
        std::cerr << "Operation failed after " << max_attempts << " attempts." << std::endl;
        return -1;  // Indicate failure
    }

    return 0;  // Indicate success
}

/**
 * @brief The main entry point to the application.
 * 
 * This function acts as a wrapper for the `real_main` function. It catches and handles any standard exceptions thrown during the execution of `real_main`.
 * 
 * @return Returns 0 on successful execution of `real_main`, -1 on any error or exception encountered.
 */
int main(int argc, char* argv[]) {
    try {
        return real_main(argc, argv);
    }
    catch (const FrontPanelToAxiLiteBridge::ResponseException&) {
        std::cerr << "Gateware response error: Can indicate a configuration issue. Review system endpoint addresses. Not intended for runtime recovery." << std::endl;
    }
    catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
    catch (...) {
        std::cerr << "Error: caught unknown exception." << std::endl;
    }
    return -1;
}
