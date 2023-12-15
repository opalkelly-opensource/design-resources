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

"""Constants used throughout the system.

This module contains constants related to the operation of the system.
Each constant's purpose and usage is further described in the comments within
the module.
"""

STATUS_INTERVAL = 3   # Interval (in seconds) to print FPS to the console.
USE_SPIN_WAIT = True  # Use spin-wait for accurate timing at the cost of CPU.

# `SHOW_BATCHED_FRAMES` determines whether the visual representation of batched frames is enabled or not.
# Batching refers to the process of collecting multiple frames into a buffer and sending them in one go with a single WriteToBlockPipeIn call.
# The exact size of the batch is determined by the HDL/Gateware and is communicated to this Python application during initialization.
# When visualization is enabled by setting this variable to True, the frames in each batch will be displayed in a grid format.
SHOW_BATCHED_FRAMES = True

# `SHOW_BATCHED_FRAMES_FRAMES_PER_ROW` dictates the number of frames displayed per row in the visualization grid.
# Adjust this value to modify the layout of the visual representation.
SHOW_BATCHED_FRAMES_FRAMES_PER_ROW = 3


# The following parameters determine the location of the region of interest 
# for capturing frames within this application. They define the offset from 
# an origin situated at the top-left corner of the screen.

# It's crucial to remember that the size of the pixel matrix is not defined here.
# Instead, it's defined in the Microblaze application code and passed on to 
# this Python application. Therefore, ensure compatibility: the selected offset 
# plus the matrix size should remain within the bounds of your screen.

# Horizontal offset from the top-left corner.
X_OFFSET = 16

# Vertical offset from the top-left corner.
Y_OFFSET = 512

# This value determines the thickness of the red border drawn around the region
# of interest. Adjusting this value will increase or decrease the border width.
BORDER_THICKNESS = 10 

# This is the base address of the VMIX Vivado IP Core as defined in the Address Editor in Vivado.
# Alternativity, you can also find this define within the xparameters.h Microblaze file.
XPAR_V_MIX_0_S_AXI_CTRL_BASEADDR = 0x44A50000

# Base and Register offsets for VMIX Vivado IP Core
XV_MIX_CTRL_ADDR_HWREG_WIDTH_DATA = 0x00010
XV_MIX_CTRL_ADDR_HWREG_HEIGHT_DATA = 0x00018
XV_MIX_CTRL_ADDR_HWREG_LAYERSTARTX_0_DATA = 0x00208
XV_MIX_CTRL_ADDR_HWREG_LAYERSTARTY_0_DATA = 0x00210

# Base and Register offsets for RX DisplayPort Vivado IP Core
XPAR_DPRXSS_0_BASEADDR = 0x44B80000
 
XDP_RX_OVER_LINK_BW_SET = 0x09C
XDP_RX_MSA_MVID = 0x530
XDP_RX_MSA_NVID = 0x534
XDP_RX_MSA_HTOTAL = 0x510
XDP_RX_MSA_VTOTAL = 0x524

# Interval between updating the pie chart and fps status
STATS_UPDATE_INTERVAL = 0.1

# 1000ms or 1 second
PIE_CHART_STEP_TIME_MS = 1000

# Device Thread Priority Queue Ticket Type Priorities
RETRIEVE_AND_SET_FPS_QUEUE_PRIORITY = 0
UPDATE_BATCH_SIZE_QUEUE_PRIORITY = 0
SEND_FRAME_BATCH_QUEUE_PRIORITY = 1
SET_X_POSITION_QUEUE_PRIORITY = 2
SET_Y_POSITION_QUEUE_PRIORITY = 2
AXI_READ_QUEUE_PRIORITY = 2
AXI_WRITE_QUEUE_PRIORITY = 2
