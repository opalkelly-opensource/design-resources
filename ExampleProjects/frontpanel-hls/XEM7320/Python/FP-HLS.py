import struct
import sys
import ok

PIPE_IN_EP = 0x80
STATUS_EP = 0x20
PIPE_OUT_EP = 0xA0
RESET_EP = 0x00
TRIGGER_EP = 0x40

def twos_comp(val, bits):
    if (val & (1 << (bits - 1))):
        val = val - (1 << bits)
    return val

def pipe_write(buf):
    ret = dev.WriteToPipeIn(PIPE_IN_EP, buf)

def wait_for_finish():
    while True:
        dev.UpdateWireOuts()
        status = dev.GetWireOutValue(STATUS_EP)
        if (status == 1):
            return

def pipe_read(length):
    output_buf = bytearray(len(input_buf) * 2)
    dev.ReadFromPipeOut(PIPE_OUT_EP, output_buf)
    n = 8
    """ List containing output """
    out_arr = []
    for i in range (0, len(output_buf), n):
        temp_var = int.from_bytes(output_buf[i:i+n], byteorder = "little")
        # Convert output data back to a float, shift right by 36 (divide by 2^36)
        temp_var = float(twos_comp(temp_var, 48)) / (2**36)
        out_arr.append(temp_var)
    return out_arr

def transaction(in_buf, out_arr):
    pipe_write(in_buf)
    dev.ActivateTriggerIn(TRIGGER_EP, 0)
    wait_for_finish()
    out_arr.extend(pipe_read(len(in_buf) * 2))

""" Open device """
if (len(sys.argv) < 5):
    print("Usage:")
    print("python3 FP-HLS.py <bitstream> <infile> <reference output> <outfile>")
    quit()

dev = ok.okCFrontPanel()
if (dev.NoError != dev.OpenBySerial("")):
	print("A device could not be opened.")
	quit()

dev.ConfigureFPGA(sys.argv[1])

""" Toggle reset """
dev.SetWireInValue(RESET_EP, 0x1)
dev.UpdateWireIns()
dev.SetWireInValue(RESET_EP, 0x0)
dev.UpdateWireIns()

input_float = []
input_buf = bytearray()
output_arr = []
with open(sys.argv[2]) as infile:
    i = 0
    for line in infile:
        line = line.rstrip()
        input_float.append(float(line))
        # Convert float data to bytes, shift left by 16 (multiply by 2^16) to
        # match fixed point settings in HLS
        val = int(float(line) * (2**16)).to_bytes(4, byteorder = "little", signed=True)
        #if i < 10:
            #print((float(line) * (2**16)))
        input_buf.extend(val)
        if i == 1023:
            transaction(input_buf, output_arr)
            input_buf = bytearray()
            i = 0
        else:
            i += 1

while len(input_buf) != 4096:
    input_buf.append(0x0)

transaction(input_buf, output_arr)

total_error = 0

with open(sys.argv[3]) as reffile:
    for i, line in enumerate(reffile):
        line = line.rstrip()
        ref_val = float(line)
        error = output_arr[i] - ref_val
        total_error += error

if (total_error < 10.0):
    print("Success! Error within bounds!")
else:
    print("Error out of bounds")

with open(sys.argv[4], mode = "wt") as outfile:
    outfile.write('\n'.join(str(value) for value in output_arr))
