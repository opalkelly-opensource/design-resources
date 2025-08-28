The [Camera-HLS](https://docs.opalkelly.com/fpsdk/samples-and-tools/camera-example-design/hls-enhanced-design/) app is a demonstration FrontPanel Platform App providing an enhanced full image capture pipeline and display functionality to the FrontPanel host. The pipeline enhancements include automatic color correction and black level. Functionality includes:

* Adjustable capture size, exposure, pixel display mode, and image buffer depth
* Image sensor test modes such as color bars
* Real-time red, green and blue histograms
* Adjustable red, green, and blue color gains, black level correction, and white balance
* Black level correction and white balance provided by high-level synthesis image processing

# Compatibility

The camera-hls app is compatible with the following FPGA module and camera peripheral combinations:

* [XEM8320](https://opalkelly.com/products/xem8320/)
  * [SZG-CAMERA](https://opalkelly.com/products/szg-camera/). Note that the camera must be attached at Port A.

# Usage

This application provides settings to control camera operation and display output, along with indicators to monitor the status of the frame capture process.

## Settings

* **Continuous Capture:** Enable to periodically capture frames from the camera or disable to manually capture frames using the 'Capture' button.
* **Capture Size:** Select the size from the dropdown list. Frames are decimated on the FPGA resulting in lower bandwidth for smaller image sizes.
* **Exposure:** Set the value in the number entry field. Longer exposures may reduce frame rate.
* **Color Gains:** Adjust the *Red*, *Green*, and *Blue* color gains in the number entry fields.
* **Black Level Correction:** Adjust with the slider.
* **Auto White Balance:** Enable/adjust with the slider.
* **Display Mode:** Select from the dropdown list to control how the captured image data is displayed. (RGB mode is the only mode supported currently)
* **Capture Mode:** Select *Image Capture* or one of the image sensor test modes from the dropdown list.
* **Frame Buffer Capacity:** Use the slider to set the depth of the buffer. Larger buffers may result in image latency if the data port is unable to keep up with the frame rate.

## Status Indicators

* **Frames per Second (FPS):** Rate at which the application is able to retrieve and display captured images.
* **Buffer Level:** The number of frames that have been collected in the buffer that have not yet been retrieved and displayed.
* **Missed Frames:** The number of frames that have been dropped to avoid buffer overflow.
* **Real-Time Histograms:** Red, green, and blue channel histograms for evaluating image exposure and color balance.

# Version History

* 2.8 (released 2025-08-26)
  * Updated to provide application information
* 2.7
  * Updated to use version 0.5.0 of the FrontPanel Platform API
  * Updated so application can be installed in the FrontPanel Platform launcher
* 2.6
  * Initial release of the FrontPanel Platform App
