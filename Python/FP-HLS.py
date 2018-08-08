import struct
import sys
import ok

PIPE_IN_EP = 0x80
STATUS_EP = 0x20
PIPE_OUT_EP = 0xA0
RESET_EP = 0x00
TRIGGER_EP = 0x40

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
    out_arr = [int.from_bytes(output_buf[i:i + n], byteorder = "little") for i in range(0, len(output_buf), n)]
    return out_arr

def transaction(in_buf, out_arr):
    pipe_write(in_buf)
    dev.ActivateTriggerIn(TRIGGER_EP, 0)
    wait_for_finish()
    out_arr.extend(pipe_read(len(in_buf) * 2))

""" Open device """
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

input_buf = bytearray()
output_arr = []
with open(sys.argv[2]) as infile:
    i = 0
    for line in infile:
        line = line.rstrip()
        val = int(line).to_bytes(4, byteorder = "little")
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

with open(sys.argv[4], mode = "wt") as outfile:
    outfile.write('\n'.join(str(value) for value in output_arr))
