I2CController Software Distribution
===================================
This is a full-featured I2C Controller designed to communicate I2C commands from 
a host computer, through USB to an FPGA connected to an I2C bus. This I2C 
Controller utilizes [Opal Kelly's](https://www.opalkelly.com/) FrontPanel enabled 
FPGA modules and the Opal Kelly FrontPanel SDK. Opal Kelly’s FrontPanel SDK allows 
stimulation of wires from within an FPGA HDL design, communicated over USB from either the 
FrontPanel GUI, or by use of the FrontPanel API. 

This I2C Controller makes up two components, the hardware(HDL) component and the 
software(API) component. The HDL component essentially makes up a state machine that 
executes the I2C protocol. The software(API) component utilizes the FrontPanel 
SDK to stimulate/sense the hardware(HDL) state machine, for example the start/done signals. 
The FrontPanel SDK also sends/receives data to/from the hardware(HDL) state machine. 

This project provides more useful I2C API calls that consist of sequences of 
more fundamental FrontPanel API calls provided by the FrontPanel SDK.

The sources are FPGA agnostic and been confirmed to work
with both Intel and Xilinx FPGA chips. 

Requirements
------------
* A [Opal Kelly](https://www.opalkelly.com/) FrontPanel enabled FPGA module
* A [FrontPanel](https://opalkelly.com/products/frontpanel/) enabled HDL design with 
FrontPanel HDL components instantiated at the addresses described in the HDL section below.
The provided example.v HDL design gives an example of this. 
* An I2C Bus that the HDL can connect to. 
* C++ software that includes and utilizes the API provided in this project. 

Example XEM6002 Project
-----------------------
An example project has been set up for use with the Opal Kelly [XEM6002](https://www.opalkelly.com/products/xem6002/).
This example is designed to interact with a PMOD Gyro on the XEM6002 POD1
port.

Software
--------
A C++ API wrapper is provided to interact with the I2C device through the 
FrontPanel software interface.

An example program written in C++ is also provided and can be used to
communicate with EEPROM devices connected to the FPGA I2C controller along
with the PMOD Gyro.

The C++ API wrapper consists of five functions:
1. Configure()
2. Receive()
3. Transmit()
4. Write8()
5. Read8()


### 1. Configure() 
Configure() is used to help configure the I2C Controller before executing a command. 

__void Configure(unsigned char length, unsigned char starts, unsigned char stops, const unsigned char *preamble);__
* LENGTH -   Length of the preamble in bytes.
* STARTS -   Defines the preamble bytes after which a start bit is 
		   		 	 transmitted. For example, if STARTS=0x04, a start bit is
		  		 	 transmitted after the 3rd preamble byte.
* STOPS -    Defines the preamble bytes after which a stop bit is 
		  		 	 transmitted. For example, if STOPS=0x04, a stop bit is
		  		 	 transmitted after the 3rd preamble byte.
* PREAMBLE - This is a byte(char) data array containing the preamble.

Lets say that your device requires the following I2C communication for a read:
```c++
//An example I2C read format is commented below:
//Omitting the acknowledgments and first start bit. All () parentheses refer to 8 bits(1 byte).
//(DeviceAddress{Write})(RegisterAddress)(Start)(DeviceAddress{read})(ReadData)(ReadData)......
unsigned char preamble[8], starts, stops;
preamble[0] = 0xA0; // devAddr (write)
preamble[1] = 0x00; // byteAddress
preamble[2] = 0xA1; // devAddr (read)
starts = 0x02;
stops = 0x00;
i2c.Configure(3, starts, stops, preamble);
```
Typically stops will not be used and remains at zero, but it is added if you require that functionality.


### 2. Receive()
Receive() executes a receive I2C command after you have done the configuration step above.

__void Receive(unsigned char *data, unsigned int length);__
* DATA -     Pointer to a byte(char) data array in which to store the data.
* LENGTH -   Defines the amount of data bytes to receive
An example:
```c++
unsigned char data[256];
i2c.Configure(3, starts, stops, preamble); //Using the same configuration from above.
i2c.Receive(data, 10);
for (int i = 0; i < 10; i++) {
	printf("Read: %02X from memory\n", data[i]);
}
```


### 3. Transmit()
Transmit() executes a transmit I2C command after you have done the configuration step above.

__void Transmit(const unsigned char *data, unsigned int length);__
* DATA -     Pointer to a byte(char) data array containing the data to send.
* LENGTH -   Defines the amount of data bytes to transmit. 

An example:
```c++
//An example I2C write format is commented below:
//Omitting the acknowledgments and first start bit. All () parentheses refer to 8 bits(1 byte).
//(DeviceAddress{Write})(RegisterAddress)(WriteData)(WriteData)......
unsigned char preamble[8], starts, stops, data[256];
data[0] = 0xDE;
data[1] = 0xAD;
data[2] = 0x00;
data[3] = 0xF0;
data[4] = 0x0D;
data[5] = 0x00;
data[6] = 0xBE;
data[7] = 0xEF;
data[8] = 0x00;
data[9] = 0xFF;
starts = 0x00; //Note there is no start bit for a write. 
stops = 0x00;
preamble[0] = 0xA0; // devAddr (write)
preamble[1] = 0x00; // byteAddress
i2c.Configure(2, starts, stops, preamble);	
i2c.Transmit(data, 10);
```

### 4. Write()
Write() is a wrapper function of the above functions created for 8-bit addressing I2C devices.
If your I2C device uses 8 bit addressing which looks similar to the following:
```c++
//An example 8-bit addressing I2C write format is commented below:
//Omitting the acknowledgments and first start bit. All () parentheses refer to 8 bits(1 byte).
//(DeviceAddress{Write})(RegisterAddress)(WriteData)(WriteData)......
```
Then the following function can be used to write to this I2C device.

__void Write8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, const unsigned char *data);__
* DEVADDR -   Defines the device address. 
* REGADDR -   Defines the register address to write to. 
* LENGTH -    Defines the number of bytes to transmit. 
* DATA - 		This is a byte(char) data array containing the data to send.  
An example:
```c++
unsigned char data[2];
data[0] = 0xDE;
data[1] = 0xAD;
unsigned char devAddr = 0xD0;
unsigned char CTRL_REG1 = 0x21;
i2c.Write8(devAddr, CTRL_REG1, 2, data);
```
### 5. Read()
Read() is a wrapper function of the above functions created for 8-bit addressing I2C devices.
If your I2C device uses 8 bit addressing and looks similar to the following:
```c++
//An example 8-bit addressing I2C read format is commented below:
//Omitting the acknowledgments and first start bit. All () parentheses refer to 8 bits(1 byte).
//(DeviceAddress{Write})(RegisterAddress)(Start)(DeviceAddress{read})(ReadData)(ReadData)......
```
Then the following function can be used to read from this I2C device. 

__void Read8(const unsigned char devAddr, const unsigned char regAddr, const unsigned char length, unsigned char *data);__
* DEVADDR -   Defines the device address. 
* REGADDR -   Defines the register address to write to. 
* LENGTH -    Defines the number of bytes to receive. 
* DATA - 		This is a byte(char) data array where the data received is placed. 
An example:
```c++
unsigned char data[2];
unsigned char devAddr = 0xD0;
unsigned char CTRL_REG2 = 0x21;
i2c.Read8(devAddr, CTRL_REG2, 2, data);
for (int i = 0; i < 2; i++) {
	printf("Received: %02X from I2C Device\n", data[i]);
}
```


Hardware(HDL)
--------
This is a simple I2C Controller designed to work on a single master 
multiple slave I2C bus and support slave clock stretching.  A command 
sequence for the controller is written to a small 64-byte memory after
which the START signal is asserted.  The controller performs the 
command and asserts DONE for a single cycle upon completion.

The command memory is setup as follows:
```
  Address   Bits    Contents
     0       3:0    Preamble length (1..7) = P
             7      1=read from I2C.  0=write to I2C.
     1       7:0    Preamble STARTs
     2       7:0    Preamble STOPs.
     3       7:0    Payload Length = N
     4       7:0    Preamble contents [P]
     4+P     7:0    Payload contents [N]
```
When a read is performed, a second memory is filled with the contents
read from the bus.

The memory access ports write to the command memory and read from the
result memory.  MEMSTART is used to reset a shared address pointer.

Example: Write to 16 bits Register 9 the value 644 (0x0284)\
Command Memory - 0x02 0x00 0x00 0x02 0xB8 0x09 0x02 0x84

Example: Read 16 bits from Register 9 (result is 0x0282)\
Command Memory - 0x82 0x02 0x00 0x02 0xB8 0x09\
Result Memory - 0x02 0x82
	   
	   
___Important notice:___ \
You must ensure that the top level HDL module that contains the FrontPanel HDL components from the FrontPanel SDK
have the following address/bit assignments. The C++ software API wrapper provided by this project targets these
FrontPanel endpoints, addresses, and bit locations. An example of this is provided in the example.v file of this project:
```
Host Interface registers:

WireIn 0x00
    0 - Asynchronous reset
WireIn 0x10
	7:0 - I2C input data

WireOut 0x30
	15:0 - I2C data output

TriggerIn 0x50
    0 - I2C start
    1 - I2C memory start
    2 - I2C memory write
    3 - I2C memory read
TriggerOut 0x70  (i2c_clk)
    0 - I2C done
```
An example for the okTriggerIn FrontPanel HDL component can be seen below. The required okHost instantiation and additional required 
connections to the i2cController have been omitted to highlight the required connections for the okTriggerIn component. 
Please see example.v of this project to see a full example.
```verilog
wire [15:0] ti50_clkti;

i2cController i2c_ctrl0 (
		.start        (ti50_clkti[0]),
		.memstart     (ti50_clkti[1]),
		.memwrite     (ti50_clkti[2]),
		.memread      (ti50_clkti[3]),
		.i2c_sclk     (gyro_scl), 
		.i2c_sdat     (gyro_sda)
	);
	
okTriggerIn  ti50  (.ok1(ok1),                           .ep_addr(8'h50), .ep_clk(clk_ti),   .ep_trigger(ti50_clkti));
```

Simulation
----------
A test fixture is provided for the I2C controller in the Simulation
folder. This text fixture is designed to interact with an I2C EEPROM
simulation model (see below). This test is intended to demonstrate usage
of the I2C controller only and is not intended to be used in verification.


I2C EEPROM Device Simulation Models
-----------------------------------
Simulation Models for Microchip I2C EEPROMs are used in the simulation of the
controller. These models may be downloaded directly from Microchip and are
not included in this distribution. You may want to change the tWC (write 
cycle time) in the simulations to a short period for testing.

License
-------
This project is released under the [MIT License](https://opensource.org/licenses/MIT).
Please see the LICENSE file for more information.
