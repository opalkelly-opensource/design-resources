#!/usr/bin/env python
"""POD-SENSOR Test Suite

Test suite used to demonstrate use of the various sensors on the POD-SENSOR
SYZYGY peripheral with the XEM7320.
"""

from __future__ import print_function
import ok
import argparse
import time
from gnss_ubx import GNSSTest
from hts221 import HTS221Test
from lps22hb import LPS22HBTest
from lsm9ds1 import LSM9DS1mTest, LSM9DS1agTest
from si1153 import Si1153Test


def initFPGA(dev, bitfile):
    # Open and configure the FPGA, then reset the HDL design
    devInfo = ok.okTDeviceInfo()
    dev.GetDeviceInfo(devInfo)

    print("Found a device: " + devInfo.productName)

    print("Device firmware version: " + str(devInfo.deviceMajorVersion) + "." + str(devInfo.deviceMinorVersion))
    print("Device serial number: " + devInfo.serialNumber)
    print("Device ID: " + str(devInfo.productID))

    print("Configuring FPGA...")

    if (ok.okCFrontPanel.NoError != dev.ConfigureFPGA(bitfile)):
        print("FPGA configuration failed.")
        return False

    if (dev.IsFrontPanelEnabled()):
        print("FrontPanel support is enabled")
    else:
        print("FrontPanel support is not enabled")
        return False

    # Toggle reset
    dev.SetWireInValue(0x00, 0x1, 0x1)
    dev.UpdateWireIns()

    dev.SetWireInValue(0x00, 0x0, 0x1)
    dev.UpdateWireIns()

    return True


# Start of script... Parse arguments and then run the selected tests
parser = argparse.ArgumentParser(description='SYZYGY Sensor POD Demo, specify a bitfile and an optional demo to run.')

parser.add_argument('bitfile', type=str, help='Sensor POD demo bitfile, required')
group = parser.add_mutually_exclusive_group()
group.add_argument('--gnss', dest='gnss', action='store_true', help='Run GNSS demo, prints standard NMEA GNSS messages from uBlox CAM-M8Q. Exit with a keyboard interrupt (Ctrl+C)')
parser.add_argument('--ext', dest='ext', action='store_true', help='Enable the external GNSS antenna')
group.add_argument('--prox', dest='prox', action='store_true', help='Run the ambient light sensor demo. Exit with a keyboard interrupt (Ctrl+C)')
group.add_argument('--humidity', dest='humidity', action='store_true', help='Run the humidity sensor demo')
group.add_argument('--pressure', dest='pressure', action='store_true', help='Run the pressure sensor demo')
group.add_argument('--accel', dest='accel', action='store_true', help='Run the accelerometer/gyroscope demo. Exit with a keyboard interrupt (Ctrl+C)')
group.add_argument('--mag', dest='mag', action='store_true', help='Run the magnetometer demo. Exit with a keyboard interrupt (Ctrl+C)')

args = parser.parse_args()

print("---- Opal Kelly ---- Sensor Application v1.0 ----")
print("FrontPanel DLL Loaded. Version: " + ok.okCFrontPanel.GetAPIVersionString())

dev = ok.okCFrontPanelDevices().Open()

if dev is None:
    print("Failed to open device, is one connected?")
    parser.print_help()
    exit(2)

if (args.bitfile is not None):
    if (initFPGA(dev, args.bitfile) is False):
        print("FPGA could not be initialized")
        exit(2)
    print('FPGA configured successfully')
else:
    print('Bitfile must be provided')
    parser.print_help()
    exit(2)

if (args.ext is True):
    dev.SetWireInValue(0x00, 0x00, 0x02)
    dev.UpdateWireIns()
else:
    dev.SetWireInValue(0x00, 0x02, 0x02)
    dev.UpdateWireIns()

if (args.gnss is True):
    GNSSTest(dev)

if (args.prox is True):
    Si1153Test(dev)

if (args.humidity is True):
    HTS221Test(dev)
    exit(0)

if (args.pressure is True):
    LPS22HBTest(dev)
    exit(0)

if (args.accel is True):
    LSM9DS1agTest(dev)

if (args.mag is True):
    LSM9DS1mTest(dev)

parser.print_help()
