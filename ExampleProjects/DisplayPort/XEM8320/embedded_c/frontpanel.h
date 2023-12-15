// ----------------------------------------------------------------------------------------
// Copyright (c) 2023 Opal Kelly Incorporated
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ----------------------------------------------------------------------------------------

#include "dppt.h"
#include "xv_mix_l2.h"
#include "xv_frmbufwr_l2.h"

// Initial batch size for the Python application; chosen for a balanced performance.
#define INITIAL_BATCH_SIZE 5

// Matrix size in pixels; must match the configuration in the Python script.
#define PIXEL_MATRIX_SIZE 512
#define BYTES_PER_PIXEL 3
#define BYTES_PER_HORZ_LINE (PIXEL_MATRIX_SIZE * BYTES_PER_PIXEL)
#define FRAME_LENGTH_FRONTPANEL        (PIXEL_MATRIX_SIZE * PIXEL_MATRIX_SIZE * BYTES_PER_PIXEL)

// This is the location in memory after the DisplayPort's triple buffer VDMA locations.
#define DDR_MEMORY_FRONTPANEL_OFFSET  (DDR_MEMORY + (FRAME_LENGTH * XPAR_AXIVDMA_0_NUM_FSTORES))

// This is the AXI address of the IIC peripheral buried away in the DisplayPort RX Vivado IP Core
#define DP_RX_I2C_DEV XPAR_DP_RX_HIER_V_DP_RXSS1_0_BASEADDR + XPAR_IIC_0_BASEADDR

/************************** Function Prototypes ******************************/
int FrontPanelInitPeripherals();
int FrontPanelConfig(int height, int width);
int FrontPanelInitInterrupts(XIntc *IntcInstPtr);
int ConfigMixer(int height, int width);
int ConfigWriteFrmbuf();
void XVMixCallback();
void XVFrameBufferWrCallback();
void ChangeBatchSizeInterruptHandler();
