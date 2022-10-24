### device-sensors Application
```
Usage: python3 device-sensors.py
```
device-sensors is a Python application which configures and reads out the four LTC2991 device sensors. 
Many voltage, current, and temperature readings are available. This is intended as a sample for implementing 
something similar into your own designs. An example output for this application can be seen below:
```
root@brk1900:~/pythonTest# python3 device-sensors.py
------ Device Sensors Readout ------
RAIL VOLTAGES/CURRENTS:
0.9V_MGTAVCC VOLTAGE: 0.895398
1.2V_MGTAVTT VOLTAGE: 1.217363
1.2V_DDR VOLTAGE: 1.199052
1.8V VOLTAGE: 1.801172
3.3V VOLTAGE: 3.347180
5.0V VOLTAGE: 5.045201
0.9V_MGTAVCC CURRENT: 0.019073
1.2V_MGTAVTT CURRENT: 0.022888
1.2V_DDR CURRENT: 0.720978
1.8V CURRENT: 0.480652
3.3V CURRENT: 0.396729
5V CURRENT: 0.297547


VIO/VCCO VOLTAGES/CURRENTS:
VCCO_28 VOLTAGE: 1.208818
VCCO_67 VOLTAGE: 1.198442
VCCO_68 VOLTAGE: 1.199968
VCCO_87_88 VOLTAGE: 1.188981
VCCO_28 CURRENT: 0.000000
VCCO_67 CURRENT: 0.003815
VCCO_68 CURRENT: -0.007629
VCCO_87_88 CURRENT: -0.003815


TEMPERATURES (Celsius):
BOARD TEMPERATURE 1: 38.500000
BOARD TEMPERATURE 2: 35.937500
BOARD TEMPERATURE 3: 35.125000
BOARD TEMPERATURE 4: 37.187500
FPGA TEMPERATURE: 46.062500
```
