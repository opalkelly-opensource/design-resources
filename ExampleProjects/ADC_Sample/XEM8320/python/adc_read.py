import ok
import sys
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import time

FIFO_SIZE = 2044

X_AXIS_LIMIT = 2044 # Lower this value to zoom in on the waveform

XEM_SN = ""

if (len(sys.argv) != 2):
    print(f"Usage: {sys.argv[0]} bitfile")
    sys.exit(2)
    
dev = ok.okCFrontPanel()
if (dev.OpenBySerial(XEM_SN) != 0):
    print("Device couldn't be opened. Is one connected?")
    sys.exit(2)

if (dev.ConfigureFPGA(sys.argv[1]) != 0):
    print(f"Error programming device with bitfile \"{sys.argv[1]}\"")
    sys.exit(2)

dev.SetWireInValue(0x00,0x1) # assert reset
dev.UpdateWireIns()

fig, (ax1) = plt.subplots()

data_channel1 = [0] * FIFO_SIZE
data_channel2 = [0] * FIFO_SIZE
sample = bytearray(b'0000000000000000') # 16 byte sample size

time.sleep(.1)
dev.SetWireInValue(0x00,0x0)
dev.UpdateWireIns() # deassert reset
time.sleep(.1)

def animate(i):
            
    dev.ActivateTriggerIn(0x40, 0) #fill fifo
    time.sleep(.01)
    
    for x in range(0, FIFO_SIZE, 4):
        error_check = dev.ReadFromPipeOut(0xA0, sample)
        
        if (error_check != 16):
            print("Error reading pipe.")
            sys.exit(error_check)
        for y in range(4):
            data_channel1[x+y] = (int.from_bytes(sample[y*4:y*4+2], "big") >> 2) - 0x2000 # remove the 2 zero bits,
            data_channel2[x+y] = (int.from_bytes(sample[y*4+2:y*4+4], "big") >> 2) - 0x2000 # subtract offset
            
    ax1.clear()
    ax1.plot(range(FIFO_SIZE), data_channel1, label="Ch 1")
    ax1.plot(range(FIFO_SIZE), data_channel2, label="Ch 2") 
    ax1.set_xlim(3, X_AXIS_LIMIT - 1) # ignore first two samples, as they are hold overs from the past trigger
    ax1.legend(loc='lower right', fontsize='x-small') 
    ax1.set_xlabel('sample number')
    ax1.set_ylabel('adc reading')
    
    ax1.grid(True)
    
ani = animation.FuncAnimation(fig, animate, interval=50)
plt.show()
