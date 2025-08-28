The [Camera App](https://docs.opalkelly.com/fpsdk/samples-and-tools/camera-example-design/) is a demonstration FrontPanel Platform App providing a full image capture pipeline and display functionality to the FrontPanel host. Functionality includes:

* Adjustable capture size, exposure, pixel display mode, and image buffer depth
* Image sensor test modes such as color bars

# Compatibility

The camera app is compatible with the following FPGA module and camera peripheral combinations:

* [XEM8320](https://opalkelly.com/products/xem8320/)
  * [SZG-CAMERA](https://opalkelly.com/products/szg-camera/). Note that the camera must be attached at Port A.

# Usage

This application provides settings to control camera operation and display output, along with indicators to monitor the status of the frame capture process.

## Settings

* **Continuous Capture:** Enable to periodically capture frames from the camera or disable to manually capture frames using the 'Capture' button.
* **Capture Size:** Select the size from the dropdown list. Frames are decimated on the FPGA resulting in lower bandwidth for smaller image sizes.
* **Exposure:** Set the value in the number entry field. Longer exposures may reduce frame rate.
* **Display Mode:** Select from the dropdown list to control how the captured image data is displayed.
* **Capture Mode:** Select *Image Capture* or one of the image sensor test modes from the dropdown list.
* **Frame Buffer Capacity:** Use the slider to set the depth of the buffer. Larger buffers may result in image latency if the data port is unable to keep up with the frame rate.

## Status Indicators

* **Frames per Second (FPS):** Rate at which the application is able to retrieve and display captured images.
* **Buffer Level:** The number of frames that have been collected in the buffer that have not yet been retrieved and displayed.
* **Missed Frames:** The number of frames that have been dropped to avoid buffer overflow.

# Version History

* 2.8 (released 2025-08-26)
  * Updated to provide application information
* 2.7
  * Updated to use version 0.5.0 of the FrontPanel Platform API
  * Updated so application can be installed in the FrontPanel Platform launcher
* 2.6
  * Initial release of the FrontPanel Platform App
