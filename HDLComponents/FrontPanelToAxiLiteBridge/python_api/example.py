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

"""Test Application for Opal Kelly FPGA and FrontPanelToAxiLiteBridge Operations

Description:
    This script demonstrates how to handle common operations like opening and
    initializing an FPGA device, creating a FrontPanelToAxiLiteBridge instance,
    and performing AXI write/read tests with retry logic. Exception handling
    for scenarios like HardwareTimeoutException is also included, ensuring
    robust operation.

Usage:
    1. Plug in the Opal Kelly FPGA device.
    2. Generate a bitfile for your Opal Kelly product using the "gateware" 
       sources found in this repository.
    3. Ensure the generated bitfile is located in the same directory as this script.
    4. Execute this script with the command: "py example.py"

Note:
    Make sure the required libraries and dependencies are installed and properly set up. See:
    https://docs.opalkelly.com/fpsdk/frontpanel-api/programming-languages/
    
    Supported versions of Python are located in our release notes at:
    https://docs.opalkelly.com/fpsdk/release-notes-5-x/
"""

import sys
import os
import ok
from FrontPanelToAxiLiteBridge import FrontPanelToAxiLiteBridge

# Base address for AXI GPIO.
# This constant defines the base memory address for the AXI General Purpose 
# IO (GPIO) peripheral.
AXI_GPIO_BASE_ADDRESS = 0x00000000

def initialize_fpga(configuration_file):
    """
    Initializes the FPGA and returns the device handle if successful.

    Parameters:
    - configuration_file (str): The path to the FPGA configuration file.

    Returns:
    - fpdev (object): The FPGA device handle or None if an error occurs.
    """
    
    # Attempt to open the first available device.
    fpdev = ok.FrontPanelDevices().Open()
    
    variable_type = type(fpdev)
    print(variable_type)
    
    if not fpdev:
        print("Device could not be opened. Is one connected?")
        return None

    # Print device information.
    board_model_string = fpdev.GetBoardModelString(fpdev.GetBoardModel())
    print(f"Found a device: {board_model_string}")

    major_version = fpdev.GetDeviceMajorVersion()
    minor_version = fpdev.GetDeviceMinorVersion()
    print(f"Device firmware version: {major_version}.{minor_version}")
    
    serial_number = fpdev.GetSerialNumber()
    print(f"Device serial number: {serial_number}")

    device_id = fpdev.GetDeviceID()
    print(f"Device device ID: {device_id}")

    # Configure the FPGA.
    if fpdev.NoError != fpdev.ConfigureFPGA(configuration_file):
        print("FPGA configuration failed.")
        return None

    # Check for FrontPanel support in the FPGA configuration.
    if fpdev.IsFrontPanelEnabled():
        print("FrontPanel support is enabled.")
    else:
        print("FrontPanel support is not enabled.")

    return fpdev
    
def reset_axi_system(fpdev):
    """
    Resets the AXI system using the Opal Kelly FrontPanel interface.

    This function provides a system-specific reset for the AXI system, particularly useful in
    scenarios where the system hangs. It leverages the Opal Kelly FrontPanel interface to 
    initiate a reset sequence to AMD's Processor System Reset Module IP. This module 
    handles the reset of the AXI system, ensuring compliance with AMD's reset guidelines.
    According to AMD's AXI Reference Guide (UG1037), a reset pulse asserted for 16 cycles
    of the slowest AXI clock is generally sufficient for resetting Xilinx IP. This function
    encapsulates the necessary steps to trigger this reset process.

    Args:
        fpdev: An object representing the OpalKelly::FrontPanel, used to interact with the 
               FrontPanel hardware interface.
    """
    fpdev.SetWireInValue(0x00, 1)
    fpdev.UpdateWireIns()
    fpdev.SetWireInValue(0x00, 0)
    fpdev.UpdateWireIns()

def failed(response):
    """
    Evaluates to true if `response` is not OKAY.

    Parameters:
    - response: Transaction Response to evaluate.

    Returns:
    - True for failure, false otherwise.
    """
    return response != FrontPanelToAxiLiteBridge.Response.OKAY
    
def main():
    """
    Tests FrontPanelToAxiLiteBridge operations with an FPGA device.

    Executes the following:
    1. Opens and initializes the first available FPGA device.
    2. Creates a FrontPanelToAxiLiteBridge instance.
    3. Tests AXI write and read functionalities with up to 3 retries.
       - If a HardwareTimeoutException is caught, resets the AXI system and retries.

    Note: FPGA device must be available before execution.
    """
    bitfile_path = "fp_to_axil_exdes_wrapper.bit"

    # Check if the bitfile exists
    try:
        with open(bitfile_path, 'r') as file:
            pass
    except IOError:
        print(f"The bitfile '{bitfile_path}' does not exist. Please generate it from the sources provided within this repo and place the generated bitfile in this directory.")
        return -1

    # Initialize the FPGA with our configuration bitfile.
    fpdev = initialize_fpga(bitfile_path)
    if not fpdev:
        print("FPGA could not be initialized.")
        return -1

    # Configuration setup
    configuration = FrontPanelToAxiLiteBridge.Configuration(
        fpdev=fpdev,
        wire_in_addresses=FrontPanelToAxiLiteBridge.WireInAddresses(address=0x1d, data=0x1e, timeout=0x1f),
        wire_out_addresses=FrontPanelToAxiLiteBridge.WireOutAddresses(data=0x3e, status=0x3f),
        trigger_in_address_and_offsets=FrontPanelToAxiLiteBridge.TriggerInAddressAndOffsets(address=0x5f, write_bit_offset=0, read_bit_offset=1),
        hardware_timeout_ms=3000
    )

    # Create the FrontPanelToAxiLiteBridge instance
    axi_lite_controller = FrontPanelToAxiLiteBridge(configuration)

    # Write & Read Test with retry mechanism
    print("\nTesting: AXI Write & Read")

    success = False
    attempts = 0
    max_attempts = 3

    while not success and attempts < max_attempts:
        try:
            attempts += 1  # Increment attempt counter

            # Writing data to AXI GPIO base address
            write_transaction_result = axi_lite_controller.write(AXI_GPIO_BASE_ADDRESS, 0x00000007)
            if failed(write_transaction_result):
                print(f"AXI Write Error. Response Code: {write_transaction_result}")
                continue  # Skip the rest of the loop and retry

            # Reading data from AXI GPIO base address
            read_transaction_result, return_data = axi_lite_controller.read(AXI_GPIO_BASE_ADDRESS)
            if failed(read_transaction_result):
                print(f"AXI Read Error. Response Code: {read_transaction_result}")
                continue  # Skip the rest of the loop and retry

            if return_data == 0x00000007:
                print(f"Success: Written: 0x00000007, Read: {return_data:#x}")
                success = True  # End the loop
            else:
                print(f"Error: Data mismatch. Expected: 0x00000007, Got: {return_data:#x}")
                continue  # Skip the rest of the loop and retry

        except FrontPanelToAxiLiteBridge.HardwareTimeoutException:
            print("Caught HardwareTimeoutException. Resetting AXI system and retrying...")
            reset_axi_system(fpdev)

    if not success:
        print(f"Operation failed after {max_attempts} attempts.")
        return -1  # Indicate failure

    return 0  # Indicate success

if __name__ == "__main__":
    sys.exit(main())
    