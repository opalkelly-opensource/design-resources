### fan-control Application
```
Usage: python3 fan-control.py [on | off]
```
fan-control is a Python application example that can turn on and off the fan output. This output
is controlled by the onboard LTC2991 part.

> Note: By default the fan is always enabled by the 0 Ohm jumper resistor R201. To control the fan, that resistor must first be removed.

```
root@brk1900:~/tools/fan-control# python3 fan-control.py on
------ Fan Control ------
Turning fan on...

root@brk1900:~/tools/fan-control# python3 fan-control.py off
------ Fan Control ------
Turning fan off...
```
