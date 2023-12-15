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

#include "frontpanel.h"

// GPIO instance for the FrontPanel.
XGpio GpioFrontPanel;

// Mixer instance to handle video overlay tasks.
XV_Mix_l2  mix;

// Frame buffer write instance and its associated configuration structure.
// This DMA engine writes video frames into DDR4.
XV_FrmbufWr_l2     frmbufwr;
XV_frmbufwr_Config frmbufwr_cfg;

// Pointer tracking the current read position in memory.
u32 readPointer = 0;

// Pointer tracking the current write position in memory.
u32 writePointer = 0;

// Size of each zone (or batch) in memory, initialized to match the Python application's initial value.
u32 zoneSize = INITIAL_BATCH_SIZE;

// The total size of memory allocated for video frames.
// Using two zones ensures no read-write contention. Details in XVMixCallback.
u32 totalMemorySize = INITIAL_BATCH_SIZE * 2;

/*****************************************************************************/
/**
*
* This function performs the various AMD peripheral initiation API calls
* to set up the peripherals associated with the video feed that is coming
* in on the FrontPanel link.
*
* @return	Returns a status indicating success (XST_SUCCESS) or failure
*			(XST_FAILURE).
*
* @note		None.
*
******************************************************************************/
int FrontPanelInitPeripherals() {
	u32 Status;

	/* Initialize mixer. */
	Status  = XVMix_Initialize(&mix, XPAR_V_MIX_0_DEVICE_ID);
	if(Status != XST_SUCCESS) {
		xil_printf("ERROR:: Mixer device not found\r\n");
		return(XST_FAILURE);
	}

	Status = XVFrmbufWr_Initialize(&frmbufwr, XPAR_V_FRMBUF_WR_0_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR:: Frame Buffer Write initialization failed\r\n");
		return(XST_FAILURE);
	}

	Status = XGpio_Initialize(&GpioFrontPanel, XPAR_GPIO_2_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("GpioFrontPanel Initialization Failed\r\n");
		return XST_FAILURE;
	} else {
		xil_printf("GpioFrontPanel Initialization Passed\r\n");
	}
    
    return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function configures the peripherals that have been previously
* initialized by the FrontPanelInitPeripherals function.
*
* @param	height represents the height for configuration.
* @param	width represents the width for configuration.
*
* @return	Returns a status indicating success (XST_SUCCESS) or failure
*			(XST_FAILURE).
*
* @note		Ensure that FrontPanelInitPeripherals has been called prior
*			to invoking this function.
*
******************************************************************************/
int FrontPanelConfig(int height, int width) {
	int Status;

	Status = ConfigWriteFrmbuf();
	Status |= ConfigMixer(height, width);
	if(Status != XST_SUCCESS) {
		xil_printf("ERROR:: Mixer device not found\r\n");
		return(XST_FAILURE);
	}

	return(Status);
}

/*****************************************************************************/
/**
*
* This function sets up various interrupts in the interrupt controller to
* facilitate the video feed that is coming in on the FrontPanel link.
*
* @param	IntcInstPtr is a pointer to the XIntc instance.
*
* @return	Returns a status indicating success (XST_SUCCESS) or failure
*			(XST_FAILURE).
*
* @note		None.
*
******************************************************************************/
int FrontPanelInitInterrupts(XIntc *IntcInstPtr) {
	u32 Status;

	/* Hook up interrupt service routine */
	Status = XIntc_Connect(IntcInstPtr,
						XPAR_INTC_0_V_MIX_0_VEC_ID,
						(XInterruptHandler)XVMix_InterruptHandler,
						&mix);
	if (Status != XST_SUCCESS) {
		xil_printf("ERROR:: Mixer interrupt connect failed!\r\n");
		return XST_FAILURE;
	}

	/* Enable the interrupt vector at the interrupt controller */
	XIntc_Enable(IntcInstPtr,
			XPAR_INTC_0_V_MIX_0_VEC_ID);


	Status = XIntc_Connect(IntcInstPtr,
					     XPAR_INTC_0_V_FRMBUF_WR_0_VEC_ID,
						 (XInterruptHandler)XVFrmbufWr_InterruptHandler,
						 &frmbufwr);
	if (Status != XST_SUCCESS) {
	xil_printf("ERROR:: FRMBUF WR interrupt connect failed!\r\n");
	return XST_FAILURE;
	}
	XIntc_Enable(IntcInstPtr,
			XPAR_INTC_0_V_FRMBUF_WR_0_VEC_ID);


	Status = XIntc_Connect(IntcInstPtr,
			XPAR_PROCESSOR_SUBSYSTEM_INTERCONNECT_AXI_INTC_1_BTPIPE2AXI_VIDEO_STR_0_FP2MB_INT_CHANGE_BATCH_SIZE_INTR,
						 (XInterruptHandler)ChangeBatchSizeInterruptHandler,
						 NULL);
	if (Status != XST_SUCCESS) {
	xil_printf("ERROR:: FP2MB_INT_CHANGE_BATCH_SIZE_INTR interrupt connect failed!\r\n");
	return XST_FAILURE;
	}
	XIntc_Enable(IntcInstPtr,
			XPAR_PROCESSOR_SUBSYSTEM_INTERCONNECT_AXI_INTC_1_BTPIPE2AXI_VIDEO_STR_0_FP2MB_INT_CHANGE_BATCH_SIZE_INTR);
    
    return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* XVMixCallback determines the next frame address to be read for frames from
* the FrontPanel application video feed. This setup revolves around two zones
* in memory, each designed to accommodate batches of frames.
*
* Zones are utilized primarily because of the use of the FrontPanel Pipe to
* dispatch frames in batches. Dispatching batches is more efficient than
* sending a single frame per FrontPanel Pipe call, which would add some
* overhead. This batching approach helps achieve the required Frames Per Second
* (FPS) for the system. Sending individual frames may restrict the system from
* reaching its desired FPS.
*
* The write mechanism, via rapid write DMA, is notably faster than the read
* operation, which operates at the application's frame rate. This speed
* differential could lead to potential screen tearing situations. For example,
* if the write pointer is about to write into the zone where the read pointer
* is still processing, a batch from FrontPanel could abruptly overwrite the
* frames, leading to concurrent read and write on the same frame.
*
* To prevent this, after a zone is fully written to by the rapid write DMA,
* the read pointer is moved to the start of that zone. This ensures the write
* pointer is primed for a zone not currently being read from. As a result, when
* a batch from FrontPanel arrives, frames can be written immediately without
* contending with the read pointer's slower pace.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
void XVMixCallback()
{
    // The current readPointer is from the last Callback, so we increment it.
    // and handle its cases below.
    readPointer = (readPointer + 1) % totalMemorySize;

    int readZone = readPointer / zoneSize;
    int writeZone = writePointer / zoneSize;

    // If readPointer catches up to writePointer, move it back by one frame.
    if (readPointer == writePointer) {
        readPointer = (readPointer - 1 + totalMemorySize) % totalMemorySize;
        // We add NUMBER_OF_WRITE_FRAMES_FRONTPANEL_VDMA during subtraction
        // to ensure a positive result and handle wrap-around.
    }

    // When a batch write completes, the zone increments. If read and write
    // zones match post-write, it implies the write is set to overwrite the
    // read zone next, risking screen tearing. To avert this, the read
    // pointer shifts to the start of the zone just written, which frees up
    // the read zone to be written to next.
    else if (readZone == 0 && writeZone == 0) {
        readPointer = zoneSize; // Move to start of second zone.
    } else if (readZone == 1 && writeZone == 1) {
        readPointer = 0; // Move to start of the first zone.
    }


    // Calculate the memory address for the next frame.
    u32 nextFrameAddress = DDR_MEMORY_FRONTPANEL_OFFSET
                          + (FRAME_LENGTH_FRONTPANEL * readPointer);

    // Set the buffer address for the layer.
    u32 status = XVMix_SetLayerBufferAddr(&mix, XVMIX_LAYER_1, nextFrameAddress);

    // Handle any errors from setting the buffer address.
    if (status != XST_SUCCESS)
    {
        xil_printf("XVMixCallback: XVMix_SetLayerBufferAddr failed %d\r\n", status);
    }
}

/*****************************************************************************/
/**
*
* XVFrameBufferWrCallback is triggered for each frame written. It determines
* the next write location in DDR4 memory by unconditionally incrementing the
* write pointer. Once the new address is identified, the buffer address for the
* frame buffer writer is set and the writer is started.
*
* @return	None.
*
* @note		Ensure prerequisites, such as memory allocation, are met before use.
*
******************************************************************************/
void XVFrameBufferWrCallback()
{
	int Status;
	writePointer = (writePointer + 1) % totalMemorySize;

	// Calculate the memory address for the next frame.
	u32 nextFrameAddress = DDR_MEMORY_FRONTPANEL_OFFSET
					  + (FRAME_LENGTH_FRONTPANEL * writePointer);

	Status = XVFrmbufWr_SetBufferAddr(&frmbufwr, nextFrameAddress);
	if (Status != XST_SUCCESS) {
	xil_printf("ERROR:: Unable to configure Frame Buffer Write buffer address\r\n");
	}

	XVFrmbufWr_Start(&frmbufwr);
}

/*****************************************************************************/
/**
*
* ChangeBatchSizeInterruptHandler is executed upon receiving a one clock cycle
* pulse from a FrontPanel TriggerIn endpoint. This handler resets the read/write
* pointers and updates variables related to batching in the system.
*
* @return	None.
*
* @note		The function updates zoneSize, totalMemorySize, writePointer, and
*           readPointer based on the batch size read from the FrontPanel GPIO.
*
******************************************************************************/
void ChangeBatchSizeInterruptHandler()
{
	u32 application_requested_batch_size = XGpio_DiscreteRead(&GpioFrontPanel, 1);

	zoneSize = application_requested_batch_size;
	totalMemorySize = application_requested_batch_size * 2;
	writePointer = 0;
	readPointer = 0;
}

/*****************************************************************************/
/**
*
* ConfigWriteFrmbuf configures the write DMA engine attributes for the expected
* incoming FrontPanel video feed. This setup includes size, stride, and format
* for writing into DDR4 memory.
*
* @return	Returns status code: XST_SUCCESS if successful, XST_FAILURE otherwise.
*
* @note		The function assumes certain attributes, like size and stride, are fixed
*           at 512 and BYTES_PER_HORZ_LINE respectively. It also checks for RGB8
*           support and uses the XVIDC_CSF_MEM_RGB8 format.
*
******************************************************************************/
int ConfigWriteFrmbuf()
{
  int Status;
  XVidC_ColorFormat instanceColorFormat;
  if (!XVFrmbufWr_IsRGB8Enabled(&frmbufwr)) {
	  xil_printf("INFO: XVFrmbufWr_IsRGB8Enabled not enabled\r\n");
	  return(XST_FAILURE);
  }
  instanceColorFormat = XVIDC_CSF_MEM_RGB8;
  XV_frmbufwr_Set_HwReg_width(&(frmbufwr.FrmbufWr),
		  PIXEL_MATRIX_SIZE);
  XV_frmbufwr_Set_HwReg_height(&(frmbufwr.FrmbufWr),
		  PIXEL_MATRIX_SIZE);
  XV_frmbufwr_Set_HwReg_stride(&(frmbufwr.FrmbufWr), BYTES_PER_HORZ_LINE);
  XV_frmbufwr_Set_HwReg_video_format(&(frmbufwr.FrmbufWr), instanceColorFormat);

  Status = XVFrmbufWr_SetBufferAddr(&frmbufwr, DDR_MEMORY_FRONTPANEL_OFFSET);
  if (Status != XST_SUCCESS) {
    xil_printf("ERROR:: Unable to configure Frame Buffer Write buffer address\r\n");
    return(XST_FAILURE);
  }

  XVFrmbufWr_SetCallback(&frmbufwr, XVFRMBUFWR_HANDLER_DONE, &XVFrameBufferWrCallback,
		(void *)&frmbufwr);

  /* Enable Interrupt */
  XVFrmbufWr_InterruptEnable(&frmbufwr, XVFRMBUFWR_IRQ_DONE_MASK);

  /* Start Frame Buffers */
  XVFrmbufWr_Start(&frmbufwr);

  xil_printf("INFO: FRMBUF configured\r\n");
  return(Status);
}

/*****************************************************************************/
/**
*
* ConfigMixer configures the Mixer peripheral to overlay the FrontPanel video
* feed over the main video feed. It sets up the resolution, window settings,
* buffer addresses, and enables required layers.
*
* @param	height is the height of the main video feed resolution.
* @param	width is the width of the main video feed resolution.
*
* @return	Returns status code: XST_SUCCESS if successful, XST_FAILURE otherwise.
*
* @note		The function should be called after determining the main video feed's
*           resolution. In the context of the AMD DisplayPort example design,
*           it is appropriate to call this within the detect_rx_video_and_startTx
*           function.
*
******************************************************************************/
int ConfigMixer(int height, int width)
{
  int Status;

  XV_Mix_l2 *MixerPtr = &mix;

  /* Setup default config after reset */
  XVMix_LayerDisable(MixerPtr, XVMIX_LAYER_MASTER);
  XVMix_LayerDisable(MixerPtr, XVMIX_LAYER_1);
  /* set resolution */
  XV_mix_Set_HwReg_width(&(MixerPtr->Mix),  height);
  XV_mix_Set_HwReg_height(&(MixerPtr->Mix), width);


  XVidC_VideoWindow window;
  window.StartX = 16;
  window.StartY = 16;
  window.Width = PIXEL_MATRIX_SIZE;
  window.Height = PIXEL_MATRIX_SIZE;

  Status = XVMix_SetLayerWindow(MixerPtr, XVMIX_LAYER_1, &window, BYTES_PER_HORZ_LINE);
  if(Status != XST_SUCCESS) {
      xil_printf("MIXER ERROR:: Unable to XVMix_SetLayerWindow(MixerPtr, XVMIX_LAYER0_BASEADDR, &window, 0);" );
      return(XST_FAILURE);
  }


  Status = XVMix_SetLayerBufferAddr(MixerPtr, XVMIX_LAYER_1, DDR_MEMORY_FRONTPANEL_OFFSET);
  if(Status != XST_SUCCESS) {
      xil_printf("MIXER ERROR:: Unable to set layer %d buffer addr to 0x%X\r\n",
    		  XVMIX_LAYER_1, DDR_MEMORY_FRONTPANEL_OFFSET);
      return(XST_FAILURE);
  }

  XVMix_SetCallback(MixerPtr, &XVMixCallback, (void *)MixerPtr);
  XVMix_InterruptEnable(MixerPtr);

  XVMix_LayerEnable(MixerPtr, XVMIX_LAYER_MASTER);
  XVMix_LayerEnable(MixerPtr, XVMIX_LAYER_1);

  XVMix_Start(MixerPtr);
  xil_printf("INFO: Mixer configured\r\n");

  return(Status);
}
