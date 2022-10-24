import sys
import os
import fcntl
import time

# I2C addresses for the 4 LTC2991s onboard the ECM1900.
# The I2C addresses below are in 7 bit notation, this is required for the “import os” module. The 
# datasheet will show I2C addresses starting at 0x90 that they call the “I2C Base Address”, this 
# address includes the read/write bit at bit location 0 for a total of an 8 bit address. To convert, 
# shift to the right by one bit. For Example, 0x90 >> 1  = 0x48. 
I2C_SENSOR_ADDR = [0x48, 0x49, 0x4A, 0x4B]

# Value associated with the requested operation for the fcntl.ioctl function.
FCNTL_IOCTL_OPERATION_I2C = 0x703

def main():
    print ("------ Device Sensors Readout ------")
    if (len(sys.argv) != 1):
        print ("Usage: DeviceSensors")
    # We use the “os” module to gain access to our operating system. The operating system has access to our I2C device.
    i2cdev = os.open("/dev/i2c-0", os.O_RDWR)
    if i2cdev < 0:
        print("Error opening i2c device\n")
        sys.exit()

    preConfiguration(i2cdev)
    readSensor(i2cdev)
    os.close(i2cdev)


# The following function is necessary to configure the LTC2991’s control registers for the correct 
# configuration that is present on the ECM1900. There are four LTC2991s present onboard the ECM1900, 
# each will be configured as specified below:
def preConfiguration(i2cdev):
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[0], 0x06, 0x01) # Enable V1, V2 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[0], 0x07, 0x10) # Enable V7, V8 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[0], 0x08, 0x10) # Enable Repeated Acquisition 
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[0], 0x01, 0xf8) # Enable all channels
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[0], 0x08, 0x10 | 0x08) # Enable internal temperature filter
  
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x06, 0x01) # Enable V1, V2 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x07, 0x31) # Enable V5, V6 Differential, Enable V7, V8 Differential, Enable V7, V8 Temperature
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x08, 0x10) # Enable Repeated Acquisition 
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x01, 0xf8) # Enable all channels
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x07, 0x31 | 0x80) # Enable V7, V8 Filter
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[1], 0x08, 0x10 | 0x08) # Enable internal temperature filter
  
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[2], 0x06, 0x11) # Enable V1, V2 Differential, Enable V3, V4 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[2], 0x07, 0x10) # Enable V7, V8 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[2], 0x08, 0x10) # Enable Repeated Acquisition
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[2], 0x01, 0xf8) # Enable all channels
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[2], 0x08, 0x10 | 0x08) # Enable internal temperature filter
  
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[3], 0x06, 0x11) # Enable V1, V2 Differential, Enable V3, V4 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[3], 0x07, 0x10) # Enable V7, V8 Differential
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[3], 0x08, 0x10) # Enable Repeated Acquisition
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[3], 0x01, 0xf8) # Enable all channels
    i2cWrite8(i2cdev, I2C_SENSOR_ADDR[3], 0x08, 0x10 | 0x08) # Enable internal temperature filter
  
    time.sleep(.1)


def i2cWrite8(i2cdev, i2cAddr, reg_addr, reg_data):
    i2cDataBuffer = bytearray(2)
    i2cDataBuffer[0] = reg_addr
    i2cDataBuffer[1] = reg_data
    if fcntl.ioctl(i2cdev, FCNTL_IOCTL_OPERATION_I2C, i2cAddr) < 0:
        print("Error during address set: %X\n" % (i2cAddr))
        sys.exit()
    if os.write(i2cdev, i2cDataBuffer) != 2:
        print("Error during data write: %X, %X\n" % (reg_addr, reg_data))
        sys.exit()


def readSensor(i2cdev):
    sensorData = []
    for addr in I2C_SENSOR_ADDR:
        sensorData.extend(LTC2991ReadRegisterMap(i2cdev, addr))

    # Below we access the cumulative sensor data from the sensorData byte array. We do array indexing 
    # mathematics to access the correct LTC2991 device and register. For example, sensorData[1*30 + 0x0E]
    # will access the second LTC2991 device’s register space and return register 0x0E.
    print("RAIL VOLTAGES/CURRENTS:")
    print("0.9V_MGTAVCC VOLTAGE: %f" % (LTC2991_CONV_VSINGLE(sensorData[0*30 + 0x14], sensorData[0*30 + 0x15])))
    print("1.2V_MGTAVTT VOLTAGE: %f" % (LTC2991_CONV_VSINGLE(sensorData[1*30 + 0x10], sensorData[1*30 + 0x11])))
    print("1.2V_DDR VOLTAGE: %f"     % (LTC2991_CONV_VSINGLE(sensorData[1*30 + 0x0E], sensorData[1*30 + 0x0F])))
    print("1.8V VOLTAGE: %f"         % (LTC2991_CONV_VSINGLE(sensorData[0*30 + 0x0E], sensorData[0*30 + 0x0F])))
    print("3.3V VOLTAGE: %f"         % (LTC2991_CONV_VCC(    sensorData[0*30 + 0x1C], sensorData[0*30 + 0x1D])))
    print("5.0V VOLTAGE: %f"         % (LTC2991_CONV_VCC(    sensorData[3*30 + 0x1C], sensorData[3*30 + 0x1D])))
    print("0.9V_MGTAVCC CURRENT: %f" % (LTC2991_CONV_CURRENT(sensorData[0*30 + 0x18], sensorData[0*30 + 0x19], 0.005)))
    print("1.2V_MGTAVTT CURRENT: %f" % (LTC2991_CONV_CURRENT(sensorData[1*30 + 0x14], sensorData[1*30 + 0x15], 0.005)))
    print("1.2V_DDR CURRENT: %f"     % (LTC2991_CONV_CURRENT(sensorData[1*30 + 0x0C], sensorData[1*30 + 0x0D], 0.005)))
    print("1.8V CURRENT: %f"         % (LTC2991_CONV_CURRENT(sensorData[0*30 + 0x0C], sensorData[0*30 + 0x0D], 0.005)))
    print("3.3V CURRENT: %f"         % (LTC2991_CONV_CURRENT(sensorData[2*30 + 0x0C], sensorData[2*30 + 0x0D], 0.005)))
    print("5V CURRENT: %f"           % (LTC2991_CONV_CURRENT(sensorData[3*30 + 0x0C], sensorData[3*30 + 0x0D], 0.005)))
    print("\n\nVIO/VCCO VOLTAGES/CURRENTS:")
    print("VCCO_28 VOLTAGE: %f"      % (LTC2991_CONV_VSINGLE(sensorData[2*30 + 0x12], sensorData[2*30 + 0x13])))
    print("VCCO_67 VOLTAGE: %f"      % (LTC2991_CONV_VSINGLE(sensorData[2*30 + 0x14], sensorData[2*30 + 0x15])))
    print("VCCO_68 VOLTAGE: %f"      % (LTC2991_CONV_VSINGLE(sensorData[3*30 + 0x14], sensorData[3*30 + 0x15])))
    print("VCCO_87_88 VOLTAGE: %f"   % (LTC2991_CONV_VSINGLE(sensorData[3*30 + 0x12], sensorData[3*30 + 0x13])))
    print("VCCO_28 CURRENT: %f"      % (LTC2991_CONV_CURRENT(sensorData[2*30 + 0x10], sensorData[2*30 + 0x11], 0.005)))
    print("VCCO_67 CURRENT: %f"      % (LTC2991_CONV_CURRENT(sensorData[2*30 + 0x18], sensorData[2*30 + 0x19], 0.005)))
    print("VCCO_68 CURRENT: %f"      % (LTC2991_CONV_CURRENT(sensorData[3*30 + 0x18], sensorData[3*30 + 0x19], 0.005)))
    print("VCCO_87_88 CURRENT: %f"   % (LTC2991_CONV_CURRENT(sensorData[3*30 + 0x10], sensorData[3*30 + 0x11], 0.005)))
    print("\n\nTEMPERATURES (Celsius):")
    print("BOARD TEMPERATURE 1: %f"  % (LTC2991_CONV_TEMP(   sensorData[0*30 + 0x1A], sensorData[0*30 + 0x1B])))
    print("BOARD TEMPERATURE 2: %f"  % (LTC2991_CONV_TEMP(   sensorData[1*30 + 0x1A], sensorData[1*30 + 0x1B])))
    print("BOARD TEMPERATURE 3: %f"  % (LTC2991_CONV_TEMP(   sensorData[2*30 + 0x1A], sensorData[2*30 + 0x1B])))
    print("BOARD TEMPERATURE 4: %f"  % (LTC2991_CONV_TEMP(   sensorData[3*30 + 0x1A], sensorData[3*30 + 0x1B])))
    print("FPGA TEMPERATURE: %f"     % (LTC2991_CONV_TEMP(   sensorData[1*30 + 0x16], sensorData[1*30 + 0x17])))


# The following function gathers the entire register map space of the LTC2991 and returns a 30 byte array. 
# Starting at register address 0x00 (1) and ending at 0x1D (30). Please see the LTC2991 datasheet for more 
# information about this register map. 
def LTC2991ReadRegisterMap(i2cdev, i2cAddr):
    startRegMapAddr = bytearray(1)
    startRegMapAddr[0] = 0x00
    if fcntl.ioctl(i2cdev, FCNTL_IOCTL_OPERATION_I2C, i2cAddr) < 0:
        print("Error during address set: %X\n" % (i2cAddr))
        sys.exit()
    if os.write(i2cdev, startRegMapAddr) != 1:
        print("Error during data write for i2cAddr: %X\n" % (i2cAddr))
        sys.exit()
    buf = os.read(i2cdev, 30)
    if len(buf) != 30:
        print("Error during data read for i2cAddr: %X\n" % (i2cAddr))
        sys.exit()
    return buf 


# The functions defined below are used to convert the raw data retrieved from the LTC2991 into the appropriate units of 
# Voltage, Amps, and Celsius. This conversion can be read in more detail at the LTC2991’s datasheet. 
# The first function will be explained with comments:  
def LTC2991_CONV_VSINGLE(msb, lsb):
    # This is the check as to whether the number is positive or negative by inspection of the “Sign” bit. 
    if (0.00030518   * (((msb)&0x40))):
        # If negative, we assemble the valid data bits from the MSB and LSBs. We then extract out the 
        # absolute value (positive) from the two's complement representation, multiply by -1, and multiply 
        # by the LSB Weight. 
        return (-1.0 * (0x4000 - ((((msb)&0x3f)<<8) | (lsb)) )) * 0.00030518 
    else:
        # If positive, we assemble the vaid data bits from the MSB and LSBs. We then multiply by the LSB Weight. 
        return (+1.0 *           ((((msb)&0x3f)<<8) | (lsb))  ) * 0.00030518


def LTC2991_CONV_VDIFF(msb, lsb):
    if (0.0000190735 * (((msb)&0x40))):
        return (-1.0 * (0x4000 - ((((msb)&0x3f)<<8) | (lsb)) )) * 0.0000190735
    else:
        return (+1.0 *           ((((msb)&0x3f)<<8) | (lsb))  ) * 0.0000190735


def LTC2991_CONV_TEMP(msb, lsb):
    if (0.0625       * (((msb)&0x10))): # No dedicated sign bit for temperature readings, the MSB of two's complement specifies the sign. 
        return (-1.0 * (0x2000 - ((((msb)&0x1f)<<8) | (lsb)) )) * 0.0625
    else:
        return (+1.0 *           ((((msb)&0x1f)<<8) | (lsb))  ) * 0.0625


def LTC2991_CONV_CURRENT(msb, lsb, r):
    # "r" refers to the electrical resistance (Ohms) of our Rsense resistor. You can read about the Rsense 
    # resistor's purpose in current calculations at the LTC2991’s datasheet.
    return (LTC2991_CONV_VDIFF(msb,lsb) / r) 


def LTC2991_CONV_VCC(msb, lsb):
    return (2.5 + LTC2991_CONV_VSINGLE(msb,lsb)) # 2.5 is added as instructed by LTC2991’s datasheet for VCC readings.


if __name__ == "__main__":
    main()

