import sys
import os
import fcntl
import time

# I2C addresses for the LTC2991 onboard the ECM1900 that is connected to the fan control
# Note: By default the fan is always enabled by the 0 Ohm jumper resistor R201. 
# To control the fan, that resistor must first be removed.

# The I2C addresses below are in 7 bit notation, this is required for the “import os” module. The 
# datasheet will show I2C addresses starting at 0x90 that they call the “I2C Base Address”, this 
# address includes the read/write bit at bit location 0 for a total of an 8 bit address. To convert, 
# shift to the right by one bit. For Example, 0x90 >> 1  = 0x48. 
FAN_CONTROL_ADDRESS = 0x49

# Value associated with the requested operation for the fcntl.ioctl function.
FCNTL_IOCTL_OPERATION_I2C = 0x703

def main():
    print ("------ Fan Control ------")
    if (len(sys.argv) != 2):
        print("Usage: python3 fan-control.py [on | off]")
        print("Note: By default the fan is always enabled by the 0 Ohm jumper resistor R201.")
        print("      To control the fan, that resistor must be removed.") 
        sys.exit(1)

    # We use the “os” module to gain access to our operating system. The operating system has access to our I2C device.
    i2cdev = os.open("/dev/i2c-0", os.O_RDWR)
    if i2cdev < 0:
        print("Error opening i2c device\n")
        sys.exit(1)

    enable_fan_control_output(i2cdev)

    if sys.argv[1] == "on":
        fan_turn_on(i2cdev)
    elif sys.argv[1] == "off":
        fan_turn_off(i2cdev)

    os.close(i2cdev)


def fan_turn_on(i2cdev):
    print("Turning fan on...")

    # Turn the fan on by setting the temperature threshold very low.
    i2cWrite8(i2cdev, FAN_CONTROL_ADDRESS, 0x09, 0x80)


def fan_turn_off(i2cdev):
    print("Turning fan off...")

    # Turn the fan off by setting the temperature threshold very high.
    i2cWrite8(i2cdev, FAN_CONTROL_ADDRESS, 0x09, 0x7F)


def enable_fan_control_output(i2cdev):
    # Enable PWM output
    i2cWrite8(i2cdev, FAN_CONTROL_ADDRESS, 0x08, 0x20)


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


if __name__ == "__main__":
    main()

