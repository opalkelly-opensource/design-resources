//------------------------------------------------------------------------
// okCCamera.cpp
//
// Image sensor communication.
//
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "i2c_api.h"
#include "okFrontPanel.h"
#include "okCCamera.h"

#include <algorithm>				// std::min(), max()
#include <functional>

#if __cplusplus >= 201103L
#define HAVE_OVERRIDE
#elif defined(_MSC_VER) && _MSC_VER >= 1700
#define HAVE_OVERRIDE
#endif

#ifndef HAVE_OVERRIDE
#define override
#endif

#if defined(_WIN32)
#include <windows.h>
#define strncpy strncpy_s
#define sscanf  sscanf_s
#undef min
#undef max
#endif
#if defined(__linux__) || defined(__APPLE__)
#include <unistd.h>
#define Sleep(ms)   usleep(ms*1000)
#endif
#if defined(__QNX__)
#include <unistd.h>
#define Sleep(ms)   usleep((useconds_t) (ms*1000));
#endif


#define DEVICE_ADDRESS_MT9P031       0xBA
#define DEVICE_ADDRESS_AR0330        0x30

#define MT9P031_DEFAULT_WIDTH                 2592
#define MT9P031_DEFAULT_HEIGHT                1944
#define MT9P031_REG_CHIP_VERSION              0x00
#define MT9P031_REG_ROW_START                 0x01
#define MT9P031_REG_COLUMN_START              0x02
#define MT9P031_REG_ROW_SIZE                  0x03
#define MT9P031_REG_COLUMN_SIZE               0x04
#define MT9P031_REG_HORIZONTAL_BLANK          0x05
#define MT9P031_REG_VERTICAL_BLANK            0x06
#define MT9P031_REG_OUTPUT_CONTROL            0x07
#define MT9P031_REG_SHUTTER_WIDTH_UPPER       0x08
#define MT9P031_REG_SHUTTER_WIDTH_LOWER       0x09
#define MT9P031_REG_PIXEL_CLOCK_CONTROL       0x0A
#define MT9P031_REG_RESTART                   0x0B
#define MT9P031_REG_SHUTTER_DELAY             0x0C
#define MT9P031_REG_RESET                     0x0D
#define MT9P031_REG_PLL_CONTROL               0x10
#define MT9P031_REG_PLL_CONFIG1               0x11
#define MT9P031_REG_PLL_CONFIG2               0x12
#define MT9P031_REG_READ_MODE1                0x1E
#define MT9P031_REG_READ_MODE2                0x20
#define MT9P031_REG_ROW_ADDRESS_MODE          0x22
#define MT9P031_REG_COLUMN_ADDRESS_MODE       0x23
#define MT9P031_REG_GREEN1_GAIN               0x2B
#define MT9P031_REG_BLUE_GAIN                 0x2C
#define MT9P031_REG_RED_GAIN                  0x2D
#define MT9P031_REG_GREEN2_GAIN               0x2E
#define MT9P031_REG_GLOBAL_GAIN               0x35
#define MT9P031_REG_ROW_BLACK_TARGET          0x49
#define MT9P031_REG_ROW_BLACK_DEFAULT_OFFSET  0x4B
#define MT9P031_REG_BLC_SAMPLE_SIZE           0x5B
#define MT9P031_REG_BLC_TUNE_1                0x5C
#define MT9P031_REG_BLC_DELTA_THRESHOLDS      0x5D
#define MT9P031_REG_BLC_TUNE_2                0x5E
#define MT9P031_REG_BLC_TARGET_THRESHOLDS     0x5F
#define MT9P031_REG_GREEN1_OFFSET             0x60
#define MT9P031_REG_GREEN2_OFFSET             0x61
#define MT9P031_REG_RED_OFFSET                0x63
#define MT9P031_REG_BLUE_OFFSET               0x64
#define MT9P031_REG_TEST_PATTERN_CONTROL      0xA0
#define MT9P031_REG_TEST_PATTERN_GREEN        0xA1
#define MT9P031_REG_TEST_PATTERN_RED          0xA2
#define MT9P031_REG_TEST_PATTERN_BLUE         0xA3
#define MT9P031_REG_TEST_PATTERN_BAR_WIDTH    0xA4
#define MT9P031_REG_CHIP_VERSION_ALT          0xFF

#define AR0330_DEFAULT_WIDTH                  2304
#define AR0330_DEFAULT_HEIGHT                 1296
#define AR0330_REG_CHIP_VERSION               0x3000
#define AR0330_REG_Y_ADDR_START               0x3002
#define AR0330_REG_X_ADDR_START               0x3004
#define AR0330_REG_Y_ADDR_END                 0x3006
#define AR0330_REG_X_ADDR_END                 0x3008
#define AR0330_REG_FRAME_LENGTH_LINES         0x300A
#define AR0330_REG_LINE_LENGTH_PCK            0x300C
#define AR0330_REG_REVISION_NUMBER            0x300E
#define AR0330_REG_LOCK_CONTROL               0x3010
#define AR0330_REG_COARSE_INTEGRATION_TIME    0x3012
#define AR0330_REG_FINE_INTEGRATION_TIME      0x3014
#define AR0330_REG_RESET_REGISTER             0x301A
#define AR0330_REG_MODE_SELECT                0x301C
#define AR0330_REG_IMAGE_ORIENTATION          0x301D
#define AR0330_REG_DATA_PEDESTAL              0x301E
#define AR0330_REG_SOFTWARE_RESET             0x3021
#define AR0330_REG_ROW_SPEED                  0x3028
#define AR0330_REG_VT_PIX_CLK_DIV             0x302A
#define AR0330_REG_VT_SYS_CLK_DIV             0x302C
#define AR0330_REG_PRE_PLL_CLK_DIV            0x302E
#define AR0330_REG_PLL_MULTIPLIER             0x3030
#define AR0330_REG_OP_PIX_CLK_DIV             0x3036
#define AR0330_REG_OP_SYS_CLK_DIV             0x3038
#define AR0330_REG_FRAME_COUNT                0x303A
#define AR0330_REG_FRAME_STATUS               0x303C
#define AR0330_REG_LINE_LENGTH_PCK_CB         0x303E
#define AR0330_REG_READ_MODE                  0x3040
#define AR0330_REG_EXTRA_DELAY                0x3042
#define AR0330_REG_FLASH                      0x3046
#define AR0330_REG_FLASH2                     0x3048
#define AR0330_REG_GREEN1_GAIN                0x3056
#define AR0330_REG_BLUE_GAIN                  0x3058
#define AR0330_REG_RED_GAIN                   0x305A
#define AR0330_REG_GREEN2_GAIN                0x305C
#define AR0330_REG_GLOBAL_GAIN                0x305E
#define AR0330_REG_ANALOG_GAIN                0x3060
#define AR0330_REG_SMIA_TEST                  0x3064
#define AR0330_REG_DATAPATH_STATUS            0x306A
#define AR0330_REG_DATAPATH_SELECT            0x306E
#define AR0330_REG_TEST_PATTERN_MODE          0x3070
#define AR0330_REG_TEST_DATA_RED              0x3072
#define AR0330_REG_TEST_DATA_GREENR           0x3074
#define AR0330_REG_TEST_DATA_BLUE             0x3076
#define AR0330_REG_TEST_DATA_GREENB           0x3078
#define AR0330_REG_TEST_RAW_MODE              0x307A
#define AR0330_REG_OPERATION_MODE_CTRL        0x3082
#define AR0330_REG_SEQ_DATA_PORT              0x3086
#define AR0330_REG_SEQ_CTRL_PORT              0x3088
#define AR0330_REG_X_ADDR_START_CB            0x308A
#define AR0330_REG_Y_ADDR_START_CB            0x308C
#define AR0330_REG_X_ADDR_END_CB              0x308E
#define AR0330_REG_Y_ADDR_END_CB              0x3090
#define AR0330_REG_X_EVEN_INC                 0x30A0
#define AR0330_REG_X_ODD_INC                  0x30A2
#define AR0330_REG_Y_EVEN_INC                 0x30A4
#define AR0330_REG_Y_ODD_INC                  0x30A6
#define AR0330_REG_Y_ODD_INC_CB               0x30A8
#define AR0330_REG_FRAME_LENGTH_LINES_CB      0x30AA
#define AR0330_REG_X_ODD_INC_CB               0x30AE
#define AR0330_REG_DIGITAL_TEST               0x30B0
#define AR0330_REG_DIGITAL_CTRL               0x30BA
#define AR0330_REG_GREEN1_GAIN_CB             0x30BC
#define AR0330_REG_BLUE_GAIN_CB               0x30BE
#define AR0330_REG_RED_GAIN_CB                0x30C0
#define AR0330_REG_GREEN2_GAIN_CB             0x30C2
#define AR0330_REG_GLOBAL_GAIN_CB             0x30C4
#define AR0330_REG_GRR_CONTROL1               0x30CE
#define AR0330_REG_GRR_CONTROL2               0x30D0
#define AR0330_REG_GRR_CONTROL3               0x30D2
#define AR0330_REG_GRR_CONTROL4               0x30DA
#define AR0330_REG_DATA_FORMAT_BITS           0x31AC
#define AR0330_REG_HISPI_TIMING               0x31C0
#define AR0330_REG_HISPI_CONTROL_STATUS       0x31C6
#define AR0330_REG_COMPRESSION                0x31D0
#define AR0330_REG_STAT_FRAME_ID              0x31D2
#define AR0330_REG_I2C_WRT_CHECKSUM           0x31D6
#define AR0330_REG_HORIZONTAL_CURSOR_POSITION 0x31E8
#define AR0330_REG_VERITCAL_CURSOR_POSITION   0x31EA
#define AR0330_REG_HORIZONTAL_CURSOR_WIDTH    0x31EC
#define AR0330_REG_VERTICAL_CURSOR_WIDTH      0x31EE

#define Pcam_DEFAULT_WIDTH                  1920 
#define Pcam_DEFAULT_HEIGHT                 1080 

const int IMAGE_BUFFER_DEPTH_MAX = 1023;
const int IMAGE_BUFFER_DEPTH_MIN = 5;
const int IMAGE_BUFFER_DEPTH_AUTO = -1;
const int ONE_MEBIBYTE = 1024 * 1024;


namespace {

enum class CameraKind {
	Other, // Anything that is not SZG or Pcam.
	SZG,
	Pcam
};

struct ErrorResult {
	ErrorResult(std::string&& message) : message{message} { }

	const std::string message;
};

// This is a generalization of okCCamera::InfoResult to any type.
template <typename T>
struct Result {
	const T value;
	const std::string error;

	// Implicit ctor creates a valid object.
	Result(T&& value) : value{value} { }

	// Ctor used to create an invalid object.
	Result(ErrorResult&& err) : value{}, error{err.message} { }

	// Allow testing whether the returned value is an error naturally.
	explicit operator bool() const { return error.empty(); }

	// This can be used to steal the error message from this result, typically
	// to reuse it in another one.
	std::string&& take_error() const {
		return std::move(const_cast<std::string&>(error));
	}
};

} // anonymous namespace


// This is the abstract base class for providing traits of camera sensors, it
// inherits from okCCameraValues just to allow specifying the various constants
// used here without the "okCCamera::" prefix.
class okCameraTraits : protected okCCameraValues
{
public:
	virtual ~okCameraTraits() { }

	virtual okSize GetDefaultSize() const = 0;
	virtual std::vector<int> GetSupportedSkips() const = 0;
	virtual std::vector<TestMode> GetSupportedTestModes() const = 0;
	virtual ExposureValues GetSupportedExposureValues() const = 0;
	virtual BayerFilter GetBayerFilter() const = 0;
	virtual bool SupportsOffsets() const = 0;
};

// The traits of MT9P031 sensor.
class okMT9P031Traits : public okCameraTraits
{
public:
	okMT9P031Traits() = default;

	okSize GetDefaultSize() const override;
	std::vector<int> GetSupportedSkips() const override;
	std::vector<okCCameraValues::TestMode> GetSupportedTestModes() const override;
	okCCameraValues::ExposureValues GetSupportedExposureValues() const override;
	okCCameraValues::BayerFilter GetBayerFilter() const override;
	bool SupportsOffsets() const override;
};

// The traits of MT9P031 sensor.
class okAR0330Traits : public okCameraTraits
{
public:
	okAR0330Traits() = default;

	okSize GetDefaultSize() const override;
	std::vector<int> GetSupportedSkips() const override;
	std::vector<okCCameraValues::TestMode> GetSupportedTestModes() const override;
	okCCameraValues::ExposureValues GetSupportedExposureValues() const override;
	okCCameraValues::BayerFilter GetBayerFilter() const override;
	bool SupportsOffsets() const override;
};

// The traits of Pcam sensor.
class PcamTraits : public okCameraTraits
{
public:
	PcamTraits() = default;

	okSize GetDefaultSize() const override;
	std::vector<int> GetSupportedSkips() const override;
	std::vector<okCCameraValues::TestMode> GetSupportedTestModes() const override;
	okCCameraValues::ExposureValues GetSupportedExposureValues() const override;
	okCCameraValues::BayerFilter GetBayerFilter() const override;
	bool SupportsOffsets() const override;
};
// There are two implementations of the camera API: one using direct FrontPanel
// API calls and another using scripts executing the same API calls indirectly.
// The advantage of the latter is much lower latency when working with the
// remote devices as performing many API calls requires just a single network
// round trip instead of one trip per call.

// This is the abstract base class for both implementations, it inherits from
// okCameraTraits to provide CMOS sensor traits.
class okCCameraImpl : public okCameraTraits
{
public:
	virtual ~okCCameraImpl() { }

	// Initialize the device and return the HDL version used (or -1 on error).
	virtual int InitAfterConfigure() = 0;

	virtual int GetCapabilities() = 0;

	virtual void LogicReset() = 0;
	virtual void SetTestMode(bool enable, TestMode mode) = 0;
	virtual void SetGains(int r, int g1, int g2, int b) = 0;
	virtual void SetOffsets(int r, int g1, int g2, int b) = 0;
	virtual void SetShutterWidth(int shutter) = 0;
	virtual void SetSize(int x, int y) = 0;
	virtual void SetSkips(int x, int y, int len) = 0;
	virtual void EnablePingPong(bool enable) = 0;
	virtual int GetBufferedImageCount() = 0;

	// Depending on HDL version, either V1 or V2 functions are used (there is
	// no V2 version of SingleCapture() because BufferedCaptureV2() is used for
	// the single frame capture as well).
	virtual ErrorCode BufferedCaptureV1(unsigned char *u8Image, unsigned len) = 0;
	virtual ErrorCode BufferedCaptureV2(unsigned char *u8Image, unsigned len) = 0;
	virtual ErrorCode SingleCaptureV1(unsigned char *u8Image, unsigned len) = 0;

	virtual void SetImageBufferDepth(int depth) = 0;

};

// This is the implementation using direct API calls.
class okCCameraDirectImpl : public okCCameraImpl
{
public:
	explicit okCCameraDirectImpl(okCFrontPanel* dev);

	int GetCapabilities() override;
	void LogicReset() override;
	void EnablePingPong(bool enable) override;
	int GetBufferedImageCount() override;
	ErrorCode BufferedCaptureV1(unsigned char *u8Image, unsigned len) override;
	ErrorCode BufferedCaptureV2(unsigned char *u8Image, unsigned len) override;
	ErrorCode SingleCaptureV1(unsigned char *u8Image, unsigned len) override;
	void SetImageBufferDepth(int depth) override;

protected:
	// Assert all RESETs: System PLL, Image Sensor, Pixel Clock DCM, Logic.
	void AssertResets();
	// Release PIXCLK DCM RESET.
	void ReleaseResets();

	okCFrontPanel *m_dev;
};

// To actually use the direct implementation, this template must be
// instantiated with the appropriate traits class.
template <typename T>
class okCCameraDirectImplWith : public okCCameraDirectImpl
{
public:
	using Traits = T;

	explicit okCCameraDirectImplWith(okCFrontPanel* dev) :
		okCCameraDirectImpl(dev)
	{
	}

	okSize GetDefaultSize() const override {
		return m_traits.GetDefaultSize();
	}
	std::vector<int> GetSupportedSkips() const override {
		return m_traits.GetSupportedSkips();
	}
	std::vector<okCCameraValues::TestMode> GetSupportedTestModes() const override {
		return m_traits.GetSupportedTestModes();
	}
	okCCameraValues::ExposureValues GetSupportedExposureValues() const override {
		return m_traits.GetSupportedExposureValues();
	}
	okCCameraValues::BayerFilter GetBayerFilter() const override {
		return m_traits.GetBayerFilter();
	}
	bool SupportsOffsets() const override {
		return m_traits.SupportsOffsets();
	}

private:
	Traits m_traits;
};

// Implements configuring of the EVB100x boards with the Aptina MT9P031
// CMOS image sensor.
class okCCameraDirectEVB100xImpl : public okCCameraDirectImplWith<okMT9P031Traits>
{
public:
	explicit okCCameraDirectEVB100xImpl(okCFrontPanel* dev);

	int InitAfterConfigure() override;
	void SetTestMode(bool enable, TestMode mode) override;
	void SetGains(int r, int g1, int g2, int b) override;
	void SetOffsets(int r, int g1, int g2, int b) override;
	void SetShutterWidth(int shutter) override;
	void SetSize(int x, int y) override;
	void SetSkips(int x, int y, int len) override;

private:
	void I2CWrite8(unsigned addr, unsigned data);
	unsigned I2CRead8(unsigned addr);

	void SetupOptimizedRegisterSet();
};

// This is the helper for the implementation classes for the devices with 3
// cameras support.
//
// It notably provides a convenient ForAllCameras() helper.
template <typename Traits>
class okC3CameraImpl : public okCCameraDirectImplWith<Traits>
{
public:
	using Base = okCCameraDirectImplWith<Traits>;

	okSize GetDefaultSize() const override {
		okSize size = Base::GetDefaultSize();

		// In multi-camera configuration we combine the view from all cameras
		// into a single image, so it has a bigger height.
		size.m_height *= m_numCameras;

		return size;
	}

protected:
	// This function returns the size to be used for each camera from the total
	// size used by all cameras -- it does the converse of GetDefaultSize()
	// above.
	okSize GetPerCameraSize(okSize size) const {
		size.m_height /= m_numCameras;

		return size;
	}


	okC3CameraImpl(okCFrontPanel* dev, int configuration) :
		Base(dev),
		m_i2cDevice(dev),
		m_numCameras(GetNumCamerasFor(configuration))
	{
	}

	// Perform the given action for each I2C controller.
	void ForAllCameras(std::function<void ()> action) {
		if (m_numCameras == 1) {
			// Don't bother calling SelectController() at all, it's just
			// unnecessary in this case.
			action();
		} else {
			for (int controller = 0; controller < m_numCameras; ++controller) {
				m_i2cDevice.SelectController(controller);
				action();
			}
		}
	}

	OpalKelly::I2C m_i2cDevice;

private:
	// Configuration here must be either -1 (default, single camera) or 0
	// (first extra configuration using 3 cameras), see XEM8320::GetInfo().
	static int GetNumCamerasFor(int configuration)
	{
		switch (configuration) {
			case -1: return 1;
			case  0: return 3;
		}

		throw std::logic_error("unsupported SZG camera configuration");
	}

	// This can be currently either 1 or 3.
	const int m_numCameras;
};


// Implements configuring of the SZG-CAMERA boards with the Semiconductor
// AR0330 CMOS image sensor (currently compatible only with XEM7320 devices).
class okCCameraDirectSZGImpl : public okC3CameraImpl<okAR0330Traits>
{
public:
	okCCameraDirectSZGImpl(okCFrontPanel* dev, int configuration) :
		okC3CameraImpl<okAR0330Traits>(dev, configuration)
	{
	}

	int InitAfterConfigure() override;
	void SetTestMode(bool enable, TestMode mode) override;
	void SetGains(int r, int g1, int g2, int b) override;
	void SetOffsets(int r, int g1, int g2, int b) override;
	void SetShutterWidth(int shutter) override;
	void SetSize(int x, int y) override;
	void SetSkips(int x, int y, int len) override;

private:
	void I2CWrite16(unsigned long u16Addr, unsigned long u16Data);
	unsigned long I2CRead16(unsigned long u16Addr);

	void SetupOptimizedRegisterSet();
};


// Implements configuring of the Pcam with the OmniVision OV5640
// image sensor.
class okCCameraDirect_Pcam_Impl : public okC3CameraImpl<PcamTraits>
{
public:
	okCCameraDirect_Pcam_Impl(okCFrontPanel* dev, int configuration) :
		okC3CameraImpl<PcamTraits>(dev, configuration)
	{
	}

	int InitAfterConfigure() override;
	void SetTestMode(bool enable, TestMode mode) override;
	void SetGains(int r, int g1, int g2, int b) override;
	void SetOffsets(int r, int g1, int g2, int b) override;
	void SetShutterWidth(int shutter) override;
	void SetSize(int x, int y) override;
	void SetSkips(int x, int y, int len) override;

private:
	void I2CWrite8(uint16_t addr, uint8_t data);
	uint8_t I2CRead8(uint16_t addr);

	void resetPcam();
	void InitPcam();
	void SetupInitMode();
	void PcamAWB();
};


// This is the implementation using scripting.
class okCCameraScriptImpl : public okCCameraImpl
{
public:
	okCCameraScriptImpl(okCFrontPanel* dev, CameraKind cameraKind);

	okSize GetDefaultSize() const override;
	std::vector<int> GetSupportedSkips() const override;
	std::vector<TestMode> GetSupportedTestModes() const override;
	okCCameraValues::ExposureValues GetSupportedExposureValues() const override;
	BayerFilter GetBayerFilter() const override;
	bool SupportsOffsets() const override;

	int InitAfterConfigure() override;
	int GetCapabilities() override;
	void LogicReset() override;
	void SetTestMode(bool enable, TestMode mode) override;
	void SetGains(int r, int g1, int g2, int b) override;
	void SetOffsets(int r, int g1, int g2, int b) override;
	void SetShutterWidth(int shutter) override;
	void SetSize(int x, int y) override;
	void SetSkips(int x, int y, int len) override;
	void EnablePingPong(bool enable) override;
	int GetBufferedImageCount() override;
	ErrorCode BufferedCaptureV1(unsigned char *u8Image, unsigned len) override;
	ErrorCode BufferedCaptureV2(unsigned char *u8Image, unsigned len) override;
	ErrorCode SingleCaptureV1(unsigned char *u8Image, unsigned len) override;
	void SetImageBufferDepth(int depth) override;

private:
	// Common implementation of {Single,Buffered}Capture().
	ErrorCode DoCapture(const char *func, unsigned char *u8Image, unsigned len);

	OpalKelly::ScriptEngine m_scriptEngine;
	std::unique_ptr<okCameraTraits> m_cameraTraits;
};

namespace {

// Helpers for XEM8320 devices, which can have either a SZG or Pcam attached to
// them, and so require extra logic.
namespace XEM8320 {

// Return the kind of the product attached to the device or an error if it
// couldn't be retrieved.
//
// This function never returns CameraKind::Other.
Result<CameraKind> GetAttachedProduct(okCFrontPanel* dev);

// Return information about the camera attached to a XEM8320.
// If no known camera is present, returns an error result.
okCCamera::InfoResult GetInfo(okCFrontPanel* dev);

} // namespace XEM8320

// Broadly classify the camera device.
Result<CameraKind> GetCameraKind(okCFrontPanel* dev) {
	switch (dev->GetBoardModel()) {
		case okCFrontPanel::brdXEM7320A75T:
			return CameraKind::SZG;

		case okCFrontPanel::brdXEM8320AU25P:
			return XEM8320::GetAttachedProduct(dev);

		default:
			return CameraKind::Other;
	}
}

} // anonymous namespace


okSize
okMT9P031Traits::GetDefaultSize() const
{
	okSize defaultSize;
	defaultSize.m_width = MT9P031_DEFAULT_WIDTH;
	defaultSize.m_height = MT9P031_DEFAULT_HEIGHT;
	return defaultSize;
}


std::vector<int>
okMT9P031Traits::GetSupportedSkips() const
{
	return { 0, 1, 3 };
}


std::vector<okCCameraValues::TestMode>
okMT9P031Traits::GetSupportedTestModes() const
{
	using M = okCCameraValues::TestMode;
	return {
		M::ColorField, M::HorizontalGradient, M::VerticalGradient,
		M::DiagonalGradient, M::Classic, M::Walking1s,
		M::MonochromeHorizontalBars, M::MonochromeVerticalBars,
		M::VerticalColorBars
	};
}


okCCameraValues::ExposureValues
okMT9P031Traits::GetSupportedExposureValues() const
{
	return { 2000, 0, 65535 };
}


okCCameraValues::BayerFilter
okMT9P031Traits::GetBayerFilter() const
{
	return okCCameraValues::BayerFilter::GRBG;
}


bool
okMT9P031Traits::SupportsOffsets() const
{
	return true;
}


okSize
okAR0330Traits::GetDefaultSize() const
{
	okSize defaultSize;
	defaultSize.m_width = AR0330_DEFAULT_WIDTH;
	defaultSize.m_height = AR0330_DEFAULT_HEIGHT;
	return defaultSize;
}


std::vector<int>
okAR0330Traits::GetSupportedSkips() const
{
	return { 0, 1, 2 };
}


std::vector<okCCameraValues::TestMode>
okAR0330Traits::GetSupportedTestModes() const
{
	using M = okCCameraValues::TestMode;
	return { M::ColorField, M::Classic, M::Walking1s, M::VerticalColorBars };
}


okCCameraValues::ExposureValues
okAR0330Traits::GetSupportedExposureValues() const
{
	return { 6000, 0, 65535 };
}


okCCameraValues::BayerFilter
okAR0330Traits::GetBayerFilter() const
{
	return okCCameraValues::BayerFilter::GRBG;
}


bool
okAR0330Traits::SupportsOffsets() const
{
	return false;
}


okSize
PcamTraits::GetDefaultSize() const
{
	okSize defaultSize;
	defaultSize.m_width = Pcam_DEFAULT_WIDTH;
	defaultSize.m_height = Pcam_DEFAULT_HEIGHT;
	return defaultSize;
}


std::vector<int>
PcamTraits::GetSupportedSkips() const
{
	return { 0 };
}


std::vector<okCCameraValues::TestMode>
PcamTraits::GetSupportedTestModes() const
{
	using M = okCCameraValues::TestMode;
	return {};
}


okCCameraValues::ExposureValues
PcamTraits::GetSupportedExposureValues() const
{
	return { 100, 0, 247 };
}


okCCameraValues::BayerFilter
PcamTraits::GetBayerFilter() const
{
	return okCCameraValues::BayerFilter::BGGR;
}


bool
PcamTraits::SupportsOffsets() const
{
	return false;
}

void
okCCameraDirect_Pcam_Impl::I2CWrite8(uint16_t addr, uint8_t data)
{
	// You can read about this I2C configuration and usage at
	// our I2CController repository on our opalkelly-opensource
	// GitHub account.
	uint8_t dev_address = 0x78;
	unsigned char buf[256];
	buf[0] = (dev_address & 0xfe);
	buf[1] = (uint8_t)(addr >> 8);
	buf[2] = (uint8_t)addr;
	m_i2cDevice.Configure(3, 0x00, 0x00, buf);
	m_i2cDevice.Transmit(&data, 0x01);
}


uint8_t
okCCameraDirect_Pcam_Impl::I2CRead8(uint16_t addr)
{
	// You can read about this I2C configuration and usage at
	// our I2CController repository on our opalkelly-opensource
	// GitHub account.

	uint8_t dev_address = 0x78;
	unsigned data = 0;

	unsigned char buf[256];
	buf[0] = (dev_address & 0xfe);
	buf[1] = (uint8_t)(addr >> 8);
	buf[2] = (uint8_t)addr;
	buf[3] = (dev_address | 0x01);
	m_i2cDevice.Configure(4, 0x04, 0x00, buf);
	m_i2cDevice.Receive(buf, 1);
	data = buf[0];

	return(data);
}

void
okCCameraDirect_Pcam_Impl::resetPcam()
{
	// [0]=Active low Pcam power enable
	m_dev->SetWireInValue(0x06, 0x0000, 0x0001); 
	m_dev->UpdateWireIns();
	Sleep(100);
	m_dev->SetWireInValue(0x06, 0x0001, 0x0001); 
	m_dev->UpdateWireIns();
	Sleep(50);

}

int
okCCameraDirect_Pcam_Impl::InitAfterConfigure()
{
	m_dev->SetTimeout(1000);


	AssertResets();
	ReleaseResets();

	// Finally perform logic reset
	LogicReset();

	// [7]=MIPI CSI-2 RX Subsystem core enable.
	// [8]=Reset video interface of MIPI CSI-2 RX Subsystem
	m_dev->SetWireInValue(0x00, 0x0100, 0x0180);
	m_dev->UpdateWireIns();

	// Assert active low Pcam power enable.
	resetPcam();

	// Below we check to see if the I2C communication is up by
	// reading the device ID of the Pcam and checking if it correct.
	bool badID = false;
	ForAllCameras([&badID, this]() {
		uint8_t const dev_ID_h_ = 0x56;
		uint8_t const dev_ID_l_ = 0x40;
		uint16_t const reg_ID_h = 0x300A;
		uint16_t const reg_ID_l = 0x300B;

		uint8_t id_h, id_l;
		id_h = I2CRead8(reg_ID_h);
		id_l = I2CRead8(reg_ID_l);
		if (id_h != dev_ID_h_ || id_l != dev_ID_l_)
		{
			badID = true;
		}
	});

	if (badID)
		return -2; // Pcam device ID was incorrect. This return code prints a corresponding message in okCameraApp.cpp

	ForAllCameras([this]() {
		// [1]=0 System input clock from pad; Default read = 0x11
		I2CWrite8(0x3103, 0x11);
		// [7]=1 Software reset; [6]=0 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x82);
	});


	// Initialize Pcam for device bringup.
	InitPcam();

	// [7]=MIPI CSI-2 RX Subsystem core enable.
	// [8]=Reset video interface of MIPI CSI-2 RX Subsystem
	m_dev->SetWireInValue(0x00, 0x0080, 0x0180);
	m_dev->UpdateWireIns();

	// Setup sensor for 1080p 30fps
	SetupInitMode();

	// Setup Pcam auto white balance.
	PcamAWB();

	// Determine which version of HDL do we use.
	m_dev->UpdateWireOuts();

	return m_dev->GetWireOutValue(0x3f);
}

void
okCCameraDirect_Pcam_Impl::SetTestMode(bool enable, TestMode mode)
{

}


void
okCCameraDirect_Pcam_Impl::SetGains(int r, int g1, int g2, int b)
{

}


void
okCCameraDirect_Pcam_Impl::SetOffsets(int r, int g1, int g2, int b)
{

}


void
okCCameraDirect_Pcam_Impl::SetShutterWidth(int shutter)
{
	ForAllCameras([this, shutter]() {
		// [7]=0 Software reset; [6]=1 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x42);

		// The Pcam is configured for auto exposure control (AEC). The Pcam will 
		// continually update the lumance of the image and if this value is outside 
		// of the sliding window defined below the Pcam will automatically adjust 
		// the exposure for the lumance to fall within this window. You can read more 
		// about these registers on the OV5640’s datasheet.
		I2CWrite8(0x3a0f, shutter + 8); //Max for window
		I2CWrite8(0x3a10, shutter); // Min for window
		I2CWrite8(0x3a1b, shutter + 8); // Max for window.
		I2CWrite8(0x3a1e, shutter); // Min for window

		// [7]=0 Software reset; [6]=0 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x02);
		// Device is powered on.
	});
}


void
okCCameraDirect_Pcam_Impl::SetSize(int x, int y)
{

}


void
okCCameraDirect_Pcam_Impl::SetSkips(int x, int y, int len)
{
	m_dev->SetWireInValue(0x02, len & 0xffff);
	m_dev->SetWireInValue(0x03, len >> 16);

	LogicReset();
}

void
okCCameraDirect_Pcam_Impl::PcamAWB()
{
	ForAllCameras([this]() {
		// [7]=0 Software reset; [6]=1 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x42);

		// The following register dump was taken from OV5640.h in Digilents Pcam example design.
		// You can find their source code on GitHub through their website.

		//Advanced AWB
		I2CWrite8(0x3406, 0x00);
		I2CWrite8(0x5192, 0x04);
		I2CWrite8(0x5191, 0xf8);
		I2CWrite8(0x518d, 0x26);
		I2CWrite8(0x518f, 0x42);
		I2CWrite8(0x518e, 0x2b);
		I2CWrite8(0x5190, 0x42);
		I2CWrite8(0x518b, 0xd0);
		I2CWrite8(0x518c, 0xbd);
		I2CWrite8(0x5187, 0x18);
		I2CWrite8(0x5188, 0x18);
		I2CWrite8(0x5189, 0x56);
		I2CWrite8(0x518a, 0x5c);
		I2CWrite8(0x5186, 0x1c);
		I2CWrite8(0x5181, 0x50);
		I2CWrite8(0x5184, 0x20);
		I2CWrite8(0x5182, 0x11);
		I2CWrite8(0x5183, 0x00);
		I2CWrite8(0x5001, 0x03);

		// [7]=0 Software reset; [6]=0 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x02);
	});
}

void
okCCameraDirect_Pcam_Impl::InitPcam()
{
	ForAllCameras([this]() {
		// The following register dump was taken from OV5640.h in Digilents Pcam example design.
		// You can find their source code on GitHub through their website.
		I2CWrite8(0x3008, 0x42);
		I2CWrite8(0x3103, 0x03);
		I2CWrite8(0x3017, 0x00);
		I2CWrite8(0x3018, 0x00);
		I2CWrite8(0x3034, 0x18);
		I2CWrite8(0x3035, 0x11);
		I2CWrite8(0x3036, 0x38);
		I2CWrite8(0x3037, 0x11);
		I2CWrite8(0x3108, 0x01);
		I2CWrite8(0x303D, 0x10);
		I2CWrite8(0x303B, 0x19);
		I2CWrite8(0x3630, 0x2e);
		I2CWrite8(0x3631, 0x0e);
		I2CWrite8(0x3632, 0xe2);
		I2CWrite8(0x3633, 0x23);
		I2CWrite8(0x3621, 0xe0);
		I2CWrite8(0x3704, 0xa0);
		I2CWrite8(0x3703, 0x5a);
		I2CWrite8(0x3715, 0x78);
		I2CWrite8(0x3717, 0x01);
		I2CWrite8(0x370b, 0x60);
		I2CWrite8(0x3705, 0x1a);
		I2CWrite8(0x3905, 0x02);
		I2CWrite8(0x3906, 0x10);
		I2CWrite8(0x3901, 0x0a);
		I2CWrite8(0x3731, 0x02);
		I2CWrite8(0x3600, 0x37);
		I2CWrite8(0x3601, 0x33);
		I2CWrite8(0x302d, 0x60);
		I2CWrite8(0x3620, 0x52);
		I2CWrite8(0x371b, 0x20);
		I2CWrite8(0x471c, 0x50);
		I2CWrite8(0x3a13, 0x43);
		I2CWrite8(0x3a18, 0x00);
		I2CWrite8(0x3a19, 0xf8);
		I2CWrite8(0x3635, 0x13);
		I2CWrite8(0x3636, 0x06);
		I2CWrite8(0x3634, 0x44);
		I2CWrite8(0x3622, 0x01);
		I2CWrite8(0x3c01, 0x34);
		I2CWrite8(0x3c04, 0x28);
		I2CWrite8(0x3c05, 0x98);
		I2CWrite8(0x3c06, 0x00);
		I2CWrite8(0x3c07, 0x08);
		I2CWrite8(0x3c08, 0x00);
		I2CWrite8(0x3c09, 0x1c);
		I2CWrite8(0x3c0a, 0x9c);
		I2CWrite8(0x3c0b, 0x40);
		I2CWrite8(0x503d, 0x00);
		I2CWrite8(0x3820, 0x46);
		I2CWrite8(0x300e, 0x45);
		I2CWrite8(0x4800, 0x14);
		I2CWrite8(0x302e, 0x08);
		I2CWrite8(0x4300, 0x6f);
		I2CWrite8(0x501f, 0x01);
		I2CWrite8(0x4713, 0x03);
		I2CWrite8(0x4407, 0x04);
		I2CWrite8(0x440e, 0x00);
		I2CWrite8(0x460b, 0x35);
		I2CWrite8(0x460c, 0x20);
		I2CWrite8(0x3824, 0x01);
		I2CWrite8(0x5000, 0x07);
		I2CWrite8(0x5001, 0x03);
		// Stay in power down afterwards
	});
}



void
okCCameraDirect_Pcam_Impl::SetupInitMode()
{
	ForAllCameras([this]() {
		// [7]=0 Software reset; [6]=1 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x42);


		// The following register dump was taken from OV5640.h in Digilents Pcam example design.
		// You can find their source code on GitHub through their website.

		// Setup sensor for 1080p 30fps
		// 420Mbps per lane.
		// 1920 x 1080 @ 30fps, RAW10, MIPISCLK=420, SCLK=84MHz, PCLK=84M
		I2CWrite8(0x3035, 0x21);
		I2CWrite8(0x3036, 0x69);
		I2CWrite8(0x3037, 0x05);
		I2CWrite8(0x3108, 0x11);
		I2CWrite8(0x3034, 0x1A);
		I2CWrite8(0x3800, (336 >> 8) & 0x0F);
		I2CWrite8(0x3801, 336 & 0xFF);
		I2CWrite8(0x3802, (426 >> 8) & 0x07);
		I2CWrite8(0x3803, 426 & 0xFF);
		I2CWrite8(0x3804, (2287 >> 8) & 0x0F);
		I2CWrite8(0x3805, 2287 & 0xFF);
		I2CWrite8(0x3806, (1529 >> 8) & 0x07);
		I2CWrite8(0x3807, 1529 & 0xFF);
		I2CWrite8(0x3810, (16 >> 8) & 0x0F);
		I2CWrite8(0x3811, 16 & 0xFF);
		I2CWrite8(0x3812, (12 >> 8) & 0x07);
		I2CWrite8(0x3813, 12 & 0xFF);
		I2CWrite8(0x3808, (1920 >> 8) & 0x0F);
		I2CWrite8(0x3809, 1920 & 0xFF);
		I2CWrite8(0x380a, (1080 >> 8) & 0x7F);
		I2CWrite8(0x380b, 1080 & 0xFF);
		I2CWrite8(0x380c, (2500 >> 8) & 0x1F);
		I2CWrite8(0x380d, 2500 & 0xFF);
		I2CWrite8(0x380e, (1120 >> 8) & 0xFF);
		I2CWrite8(0x380f, 1120 & 0xFF);
		I2CWrite8(0x3814, 0x11);
		I2CWrite8(0x3815, 0x11);
		I2CWrite8(0x3821, 0x00);
		I2CWrite8(0x4837, 24);
		I2CWrite8(0x3618, 0x00);
		I2CWrite8(0x3612, 0x59);
		I2CWrite8(0x3708, 0x64);
		I2CWrite8(0x3709, 0x52);
		I2CWrite8(0x370c, 0x03);
		I2CWrite8(0x4300, 0x00);
		I2CWrite8(0x501f, 0x03);

		// [7]=0 Software reset; [6]=0 Software power down; Default=0x02
		I2CWrite8(0x3008, 0x02);
		// Device is powered on.
	});
}

okCCamera::okCCamera()
{
	m_dev = NULL;
	m_impl = NULL;
	m_nXskip = 0;
	m_nYskip = 0;
	m_nBytesPerPixel = 1;
	m_nHDLVersion = 0;
	m_nHDLCapability = 0;
	m_nMemSize = 0;
	m_nImageBufferDepth = IMAGE_BUFFER_DEPTH_AUTO;
}


okCCamera::~okCCamera()
{
	delete m_impl;
	delete m_dev;
}


okCCameraDirectImpl::okCCameraDirectImpl(okCFrontPanel* dev) :
	m_dev(dev)
{
	m_dev->SetTimeout(1000);
}


okCCameraDirectEVB100xImpl::okCCameraDirectEVB100xImpl(okCFrontPanel* dev) :
	okCCameraDirectImplWith<okMT9P031Traits>(dev)
{
}


void
okCCameraDirectEVB100xImpl::I2CWrite8(unsigned addr, unsigned data)
{
	m_dev->ActivateTriggerIn(0x42, 1);
	// Num of Data Words
	m_dev->SetWireInValue(0x01, 0x0030, 0x00ff); // Address + Data Words
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Device Address
	m_dev->SetWireInValue(0x01, DEVICE_ADDRESS_MT9P031, 0x00ff); // 0xBA for MT9P031
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Register Address
	m_dev->SetWireInValue(0x01, addr, 0x00ff);
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Data 0 MSB
	m_dev->SetWireInValue(0x01, data >> 8, 0x00ff);
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Data 1 LSB
	m_dev->SetWireInValue(0x01, data, 0x00ff);
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);

	// Start I2C Transaction
	m_dev->ActivateTriggerIn(0x42, 0);

	// Wait for Transaction to Finish
	for (int i = 0; i < 50; i++) {
		m_dev->UpdateTriggerOuts();
		if (0 == m_dev->IsTriggered(0x61, 0x0001))
			break;
	}
}


unsigned
okCCameraDirectEVB100xImpl::I2CRead8(unsigned addr)
{
	unsigned data = 0;

	m_dev->ActivateTriggerIn(0x42, 1);
	// Num of Data Words
	m_dev->SetWireInValue(0x01, 0x0031, 0x00ff); // Address + Data Words
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Device Address (read)
	m_dev->SetWireInValue(0x01, DEVICE_ADDRESS_MT9P031, 0x00ff); // 0xBA for MT9P031
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);
	// Register Address
	m_dev->SetWireInValue(0x01, addr, 0x00ff);
	m_dev->UpdateWireIns();
	m_dev->ActivateTriggerIn(0x42, 2);

	// Start I2C Transaction
	m_dev->ActivateTriggerIn(0x42, 0);

	// Wait for Transaction to Finish
	for (int i = 0; i < 50; i++) {
		m_dev->UpdateTriggerOuts();
		if (0 == m_dev->IsTriggered(0x61, 0x0001))
			break;
	}

	m_dev->ActivateTriggerIn(0x42, 1);
	// Read result 0
	m_dev->UpdateWireOuts();
	data = (m_dev->GetWireOutValue(0x22) & 0xff) << 8;
	// Read result 1
	m_dev->ActivateTriggerIn(0x42, 3);
	m_dev->UpdateWireOuts();
	data |= (m_dev->GetWireOutValue(0x22) & 0xff);

	return(data);
}


void
okCCameraDirectEVB100xImpl::SetupOptimizedRegisterSet()
{
	// Setup on-chip output FIFO to clock out at 72 MHz.  The internal pixel
	// array still runs at 96 MHz.  This is documented in TN-09-148.
	// + Configure horizontal blanking to 450
	// + Enable the output FIFO
	I2CWrite8(MT9P031_REG_HORIZONTAL_BLANK, 0x01c2);
	I2CWrite8(MT9P031_REG_OUTPUT_CONTROL, 0x1f8e);

	// Fix "Blue Strip" issue documented in TN-09-148.
	I2CWrite8(0x7f, 0x0000);

	// Optimize sensor performance for full-resolution at 15 fps as 
	// documented in TN-09-148.
	I2CWrite8(0x70, 0x0079);
	I2CWrite8(0x71, 0x7800);
	I2CWrite8(0x72, 0x7800);
	I2CWrite8(0x73, 0x0300);
	I2CWrite8(0x74, 0x0300);
	I2CWrite8(0x75, 0x3c00);
	I2CWrite8(0x76, 0x4e3d);
	I2CWrite8(0x77, 0x4e3d);
	I2CWrite8(0x78, 0x774f);
	I2CWrite8(0x79, 0x7900);
	I2CWrite8(0x7a, 0x7904);
	I2CWrite8(0x7b, 0x7800);
	I2CWrite8(0x7c, 0x7800);
	I2CWrite8(0x7e, 0x7800);
	I2CWrite8(0x7f, 0x0000);
	I2CWrite8(0x06, 0x0000);
	I2CWrite8(0x29, 0x0481);
	I2CWrite8(0x3e, 0x0087);
	I2CWrite8(0x3f, 0x0007);
	I2CWrite8(0x41, 0x0003);
	I2CWrite8(0x48, 0x0018);
	I2CWrite8(0x5f, 0x1c16);
	I2CWrite8(0x57, 0x0007);
}

void okCCameraDirectImpl::AssertResets()
{
	// Assert all RESETs:
	// + System PLL
	// + Image Sensor
	// + Pixel Clock DCM
	// + Logic
	// Note that HDL implementations targeting certain cameras or
	// boards may not have all these resets. They are provided to be backwards
	// compatible with all devices and cameras. Inspection of the HDL targeted 
	// for your board and camera will determine which apply.
	m_dev->SetWireInValue(0x00, 0x000f, 0x000f);
	m_dev->UpdateWireIns();
	Sleep(1);
	m_dev->SetWireInValue(0x00, 0x0000, 0x0001);  // Release system PLL RESET
	m_dev->UpdateWireIns();
	Sleep(1);
	m_dev->SetWireInValue(0x00, 0x0000, 0x0002);  // Release image sensor RESET
	m_dev->UpdateWireIns();
	Sleep(1);
	m_dev->SetWireInValue(0x00, 0x0000, 0x0008);  // Release logic RESET
	m_dev->UpdateWireIns();
	Sleep(10);
}


void okCCameraDirectImpl::ReleaseResets()
{
	// Release PIXCLK DCM RESET
	Sleep(10);
	m_dev->SetWireInValue(0x00, 0x0000, 0x0004);
	m_dev->SetWireInValue(0x00, 0x0010, 0x0010);
	m_dev->UpdateWireIns();
}


int
okCCameraDirectEVB100xImpl::InitAfterConfigure()
{
	m_dev->SetTimeout(1000);

	int N, M, P1;

	// Load the default PLL configuration for some boards.
	okTDeviceInfo devInfo;
	m_dev->GetDeviceInfo(&devInfo);
	if (devInfo.isPLL22150Supported || devInfo.isPLL22393Supported) {
		m_dev->LoadDefaultPLLConfiguration();
	}

	AssertResets();

	// Note: Pixel clock DCM remains in RESET until we've setup the image 
	// sensor's PIXCLK output.

	// Power on the PLL
	I2CWrite8(MT9P031_REG_PLL_CONTROL, 0x0051);

	//          EXTCLK           >> /N  >> *M   >> /P1 >>        PIXCLK
	// XEM6006: EXTCLK =  24 MHz >> /6  >> *72  >> /3  >> 96 MHz PIXCLK
	// XEM6010: EXTCLK =  20 MHz >> /5  >> *72  >> /3  >> 96 MHz PIXCLK
	// XEM6110: EXTCLK =  20 MHz >> /5  >> *72  >> /3  >> 96 MHz PIXCLK
	switch (m_dev->GetBoardModel()) {
	case okCFrontPanel::brdXEM6006LX9:
	case okCFrontPanel::brdXEM6006LX16:
	case okCFrontPanel::brdXEM6006LX25:
		N = 6;  M = 72;  P1 = 3;
		break;

	case okCFrontPanel::brdXEM6010LX45:
	case okCFrontPanel::brdXEM6010LX150:
	case okCFrontPanel::brdXEM6310LX45:
	case okCFrontPanel::brdXEM6310LX150:
	case okCFrontPanel::brdXEM7010A50:
	case okCFrontPanel::brdXEM7010A200:
	case okCFrontPanel::brdXEM7310A75:
	case okCFrontPanel::brdXEM7310A200:
	case okCFrontPanel::brdXEM7350K70T:
	case okCFrontPanel::brdXEM7350K160T:
	case okCFrontPanel::brdZEM4310:
		N = 5;  M = 72;  P1 = 3;
		break;

	default:
		return -1;
	}
	I2CWrite8(MT9P031_REG_PLL_CONFIG1, ((N - 1) << 0) | (M << 8));
	I2CWrite8(MT9P031_REG_PLL_CONFIG2, ((P1 - 1) << 0));

	// Wait to allow PLL to lock, then select PLL output as the system clock
	Sleep(1);
	I2CWrite8(MT9P031_REG_PLL_CONTROL, 0x0053);

	// Setup image sensor registers
	SetupOptimizedRegisterSet();

	ReleaseResets();

	// Turn off the programmable empty setting in hardware, this is not used in
	// this implementation, the wire is updated in LogicReset.
	m_dev->SetWireInValue(0x04, 0, 0xfff);

	// Finally perform logic reset
	LogicReset();

	// Determine which version of HDL do we use.
	m_dev->UpdateWireOuts();

	return m_dev->GetWireOutValue(0x3f);
}


int
okCCameraDirectImpl::GetCapabilities()
{
	return m_dev->GetWireOutValue(0x3e);
}


void
okCCameraDirectImpl::LogicReset()
{
	m_dev->SetWireInValue(0x00, 0x0008, 0x0008);
	m_dev->UpdateWireIns();
	m_dev->SetWireInValue(0x00, 0x0000, 0x0008);
	m_dev->UpdateWireIns();
}


okCCamera::ErrorCode
okCCamera::Initialize(
	std::string& message,
	OpalKelly::FrontPanel* dev,
	const std::string& bitfilePath,
	int configuration
)
{
	if (dev) {
		m_dev = dev;
	}
	else {
		m_dev = new okCFrontPanel();
		if (okCFrontPanel::NoError != m_dev->OpenBySerial()) {
			delete m_dev;
			m_dev = NULL;
		}
	}

	if (!m_dev) {
		message = "failed to open the camera device";
		return(okCCamera::Failed);
	}

	auto const cameraKind = GetCameraKind(m_dev);
	if (!cameraKind) {
		message = "failed to determine the type of the camera: ";
		message += cameraKind.error;
		return(okCCamera::Failed);
	}

	if (m_dev->IsRemote()) {
		if (configuration != -1) {
			message = "non-default configurations not supported for remote devices";
			return(okCCamera::Failed);
		}

		// Use host-side scripting to reduce latency.
		try {
			m_impl = new okCCameraScriptImpl(m_dev, cameraKind.value);
		}
		catch (std::exception& e) {
			// In principle, we could try using the camera directly, using
			// FrontPanel API via FPoIP, but this is unusably slow except on
			// very fast connections due to the added latency of all the
			// individual API calls, so it seems better to fail instead.
			message = "initializing scripting failed: ";
			message += e.what();
			return(okCCamera::Failed);
		}
	}

	if (!m_impl) {
		try {
			switch (cameraKind.value) {
				case CameraKind::SZG:
					m_impl = new okCCameraDirectSZGImpl(m_dev, configuration);
					break;

				case CameraKind::Pcam:
					m_impl = new okCCameraDirect_Pcam_Impl(m_dev, configuration);
					break;

				case CameraKind::Other:
					if (configuration != -1) {
						throw std::runtime_error(
							"non-default configurations not supported for this device"
						);
					}

					m_impl = new okCCameraDirectEVB100xImpl(m_dev);
					break;
			}

			if (!m_impl) {
				// This is normally unreachable because all camera kinds should
				// be processed in the switch above, but provide an error
				// message if this still happens somehow in the future/
				message = "unknown camera device kind";
			}
		} catch (const std::exception& e) {
			message = e.what();
		}

		if (!message.empty())
			return(okCCamera::Failed);
	}

	switch (m_dev->GetBoardModel()) {
	case okCFrontPanel::brdXEM6006LX9:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6006LX16:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6006LX25:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6010LX45:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6010LX150:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7010A50:
		m_nMemSize = 512 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7010A200:
		m_nMemSize = 512 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6310LX45:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM6310LX150:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7310A75:
		m_nMemSize = 1024 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7310A200:
		m_nMemSize = 1024 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7320A75T:
		m_nMemSize = 1024 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7350K70T:
		m_nMemSize = 512 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM7350K160T:
		m_nMemSize = 512 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdZEM4310:
		m_nMemSize = 128 * ONE_MEBIBYTE;
		break;
	case okCFrontPanel::brdXEM8320AU25P:
		m_nMemSize = 2 * 512 * ONE_MEBIBYTE;
		break;

	default:
		message = "unknown device model";
		return(okCCamera::Failed);
	}
	
	std::string bitfile{bitfilePath};
	if (bitfile.empty()) {
		auto const infoOrError = GetInfo(m_dev);
		if (!infoOrError) {
			message = infoOrError.error;
			return(okCCamera::Failed);
		}

		bitfile = infoOrError.info.bitfileDefaultName;
	}

	if (okCFrontPanel::NoError != m_dev->ConfigureFPGA(bitfile)) {
		message = "device configuration using bitfile " + bitfile + " failed";
		return(okCCamera::Failed);
	}
	
	try {
		m_nHDLVersion = m_impl->InitAfterConfigure();

		if (m_nHDLVersion == -1) {
			throw std::runtime_error("couldn't retrieve HDL version");
		}
		if (m_nHDLVersion == -2) {
			throw std::runtime_error("Pcam device ID was incorrect");
		}
		// Set the default size.
		m_size = GetDefaultSize();

		if ((m_nHDLVersion & 0xFF00) >= 0x0200) {
			m_nHDLCapability = m_impl->GetCapabilities();

			SetImageBufferDepth(IMAGE_BUFFER_DEPTH_AUTO);
		}
	}
	catch (std::exception& e) {
		message = "initializing the device failed: ";
		message += e.what();
		return(okCCamera::Failed);
	}

	// Turn off the programmable empty setting in hardware, this is not used in
	// this implementation.
	m_dev->SetWireInValue(0x04, 0, 0xfff);

	m_dev->UpdateWireOuts();

	m_nHDLVersion = m_dev->GetWireOutValue(0x3f);
	m_nHDLCapability = m_dev->GetWireOutValue(0x3e);

	if ((m_nHDLVersion & 0xFF00) >= 0x0200) {
		SetImageBufferDepth(IMAGE_BUFFER_DEPTH_AUTO);
	}

	return(okCCamera::NoError);
}


bool
okCCamera::IsOpen()
{
	if (NULL == m_dev)
		return(false);
	return(m_dev->IsOpen());
}


void
okCCamera::LogicReset()
{
	if (m_impl)
		m_impl->LogicReset();
}


okSize
okCCamera::GetDefaultSize() const
{
	if (m_impl)
		return m_impl->GetDefaultSize();
	return {};
}


std::vector<int>
okCCamera::GetSupportedSkips() const
{
	if (m_impl)
		return m_impl->GetSupportedSkips();
	return {};
}


std::vector<okCCameraValues::TestMode>
okCCamera::GetSupportedTestModes() const
{
	if (m_impl)
		return m_impl->GetSupportedTestModes();
	return {};
}


okCCamera::ExposureValues
okCCamera::GetSupportedExposureValues() const
{
	if (m_impl)
		return m_impl->GetSupportedExposureValues();
	return {};
}


okCCamera::BayerFilter
okCCamera::GetBayerFilter() const
{
	if (m_impl)
		return m_impl->GetBayerFilter();
	return BayerFilter::GRBG;
}


bool
okCCamera::SupportsOffsets() const
{
	if (m_impl)
		return m_impl->SupportsOffsets();
	return false;
}


void
okCCamera::SetGains(int r, int g1, int g2, int b)
{
	if (m_impl)
		m_impl->SetGains(r, g1, g2, b);
}


void
okCCamera::SetOffsets(int r, int g1, int g2, int b)
{
	if (!SupportsOffsets()) {
		throw std::runtime_error("The camera sensor doesn't support setOffsets()");
	}

	if (m_impl)
		m_impl->SetOffsets(r, g1, g2, b);
}


void
okCCamera::SetTestMode(bool enable, TestMode mode)
{
	if (m_impl)
		m_impl->SetTestMode(enable, mode);
}


void
okCCamera::SetShutterWidth(int shutter)
{
	if (m_impl)
		m_impl->SetShutterWidth(shutter);
}


void
okCCamera::SetSize(int x, int y)
{
	m_size.m_width = x;
	m_size.m_height = y;

	if (m_impl)
		m_impl->SetSize(x, y);
}


void
okCCamera::SetSkips(int x, int y)
{
	m_nXskip = x;
	m_nYskip = y;

	// We want to ensure that any changes to resolution haven't reduced
	// our available buffers. If so, shrink the number of buffers to match.
	SetImageBufferDepth(m_nImageBufferDepth);

	if (m_impl)
		m_impl->SetSkips(x, y, GetFrameBufferSize());
}


unsigned
okCCamera::GetFrameBufferSize()
{
	const auto size = GetSizeWithSkips(m_size, m_nXskip, m_nYskip);
	unsigned len = size.m_width * size.m_height * m_nBytesPerPixel;
	// Round up to 256 (burst length * 8 bytes)
	if (m_dev->GetBoardModel() != okCFrontPanel::brdXEM8320AU25P) {
		len += 256 - (len % 256);
	}

	return(len);
}


void
okCCamera::EnablePingPong(bool enable)
{
	if (m_impl)
		m_impl->EnablePingPong(enable);
}


int
okCCamera::GetBufferedImageCount()
{
	return m_impl ? m_impl->GetBufferedImageCount() : 0;
}


okCCamera::ErrorCode
okCCamera::BufferedCapture(unsigned char *u8Image)
{
	if (!m_impl)
		return Failed;

	const unsigned ulLen = GetFrameBufferSize();
	if ((m_nHDLVersion & 0xFF00) >= 0x0200) {
		return m_impl->BufferedCaptureV2(u8Image, ulLen);
	}
	else {
		return m_impl->BufferedCaptureV1(u8Image, ulLen);
	}
}


okCCamera::ErrorCode
okCCamera::SingleCapture(unsigned char *u8Image)
{
	if (!m_impl)
		return Failed;

	const unsigned ulLen = GetFrameBufferSize();
	if ((m_nHDLVersion & 0xFF00) >= 0x0200) {
		return m_impl->BufferedCaptureV2(u8Image, ulLen);
	}
	else {
		return m_impl->SingleCaptureV1(u8Image, ulLen);
	}
}


// Helper function used to provide the maximum Depth value for the current
// resolution.
int
okCCamera::GetMaxDepthForResolution()
{
	int frame_size = GetFrameBufferSize();
	int max_depth = 0;

	if (frame_size > 0) {
		// We subtract two from the maximum number of buffers that can be stored
		// in DRAM (given by MEM_SIZE/FRAME_SIZE) to account for the buffers
		// reserved by the read and write paths.
		max_depth = (m_nMemSize / frame_size) - 2;
	}

	return std::min(max_depth, IMAGE_BUFFER_DEPTH_MAX);
}


// Check the provided depth against the maximum number of available
// buffers. If there are not enough buffers allocate as many as possible.
okCCamera::ErrorCode
okCCamera::SetImageBufferDepth(int depth)
{
	if (!m_impl)
		return Failed;

	int max_frames = GetMaxDepthForResolution();

	if (depth == IMAGE_BUFFER_DEPTH_AUTO) {
		m_impl->SetImageBufferDepth(std::max(max_frames, IMAGE_BUFFER_DEPTH_MIN));
	}
	else if ((depth > IMAGE_BUFFER_DEPTH_MAX) || (depth < IMAGE_BUFFER_DEPTH_MIN)) {
		return Failed;
	}
	else {
		// The depth is within the acceptable range and is not AUTO, so pass it on
		m_impl->SetImageBufferDepth(std::min(depth, max_frames));
	}

	m_nImageBufferDepth = depth;

	return NoError;
}


// okCCameraDirectImpl


void
okCCameraDirectEVB100xImpl::SetTestMode(bool enable, TestMode mode)
{
	if (false == enable) {
		I2CWrite8(MT9P031_REG_READ_MODE2, 1 << 6);
		I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, 0x0000);
	}
	else {
		// Turn Off BLC
		I2CWrite8(MT9P031_REG_READ_MODE2, 0 << 6);
		I2CWrite8(MT9P031_REG_ROW_BLACK_DEFAULT_OFFSET, 0x0000);

		switch (mode) {
		case ColorField:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_RED, 0x0dd0);
			I2CWrite8(MT9P031_REG_TEST_PATTERN_GREEN, 0x0ee0);
			I2CWrite8(MT9P031_REG_TEST_PATTERN_BLUE, 0x0bb0);
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case HorizontalGradient:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case VerticalGradient:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case DiagonalGradient:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case Classic:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case Walking1s:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case MonochromeHorizontalBars:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_BAR_WIDTH, 0x0a);
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		case MonochromeVerticalBars:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_BAR_WIDTH, 0x0a);
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		default:
		case VerticalColorBars:
			I2CWrite8(MT9P031_REG_TEST_PATTERN_CONTROL, (mode & 0x0f) << 3 | 0x01);
			break;
		}
	}
}


void
okCCameraDirectEVB100xImpl::SetGains(int r, int g1, int g2, int b)
{
	I2CWrite8(MT9P031_REG_RED_GAIN, (r & 0x7f) << 8);
	I2CWrite8(MT9P031_REG_GREEN1_GAIN, (g1 & 0x7f) << 8);
	I2CWrite8(MT9P031_REG_GREEN2_GAIN, (g2 & 0x7f) << 8);
	I2CWrite8(MT9P031_REG_BLUE_GAIN, (b & 0x7f) << 8);
}


void
okCCameraDirectEVB100xImpl::SetOffsets(int r, int g1, int g2, int b)
{
	I2CWrite8(MT9P031_REG_RED_OFFSET, r);
	I2CWrite8(MT9P031_REG_GREEN1_OFFSET, g1);
	I2CWrite8(MT9P031_REG_GREEN2_OFFSET, g2);
	I2CWrite8(MT9P031_REG_BLUE_OFFSET, b);
}


void
okCCameraDirectEVB100xImpl::SetShutterWidth(int shutter)
{
	I2CWrite8(MT9P031_REG_SHUTTER_WIDTH_UPPER, (shutter & 0xffff0000) >> 16);
	I2CWrite8(MT9P031_REG_SHUTTER_WIDTH_LOWER, shutter & 0xffff);
}


void
okCCameraDirectEVB100xImpl::SetSize(int x, int y)
{
	I2CWrite8(MT9P031_REG_COLUMN_SIZE, x - 1);
	I2CWrite8(MT9P031_REG_ROW_SIZE, y - 1);
}


/* static */
int
okCCamera::GetMinDepth()
{
	return IMAGE_BUFFER_DEPTH_MIN;
}


/* static */
okCCamera::InfoResult
okCCamera::GetInfo(OpalKelly::FrontPanel *dev)
{
	char const* bitfileDefaultName;

	auto const model = dev->GetBoardModel();
	switch (model) {
	case okCFrontPanel::brdXEM6006LX9:
		bitfileDefaultName = "evb1006-xem6006-lx9.bit"; break;
	case okCFrontPanel::brdXEM6006LX16:
		bitfileDefaultName = "evb1006-xem6006-lx16.bit"; break;
	case okCFrontPanel::brdXEM6006LX25:
		bitfileDefaultName = "evb1006-xem6006-lx25.bit"; break;
	case okCFrontPanel::brdXEM6010LX45:
		bitfileDefaultName = "evb1005-xem6010-lx45.bit"; break;
	case okCFrontPanel::brdXEM6010LX150:
		bitfileDefaultName = "evb1005-xem6010-lx150.bit"; break;
	case okCFrontPanel::brdXEM7010A50:
		bitfileDefaultName = "evb1005-xem7010-a50.bit"; break;
	case okCFrontPanel::brdXEM7010A200:
		bitfileDefaultName = "evb1005-xem7010-a200.bit"; break;
	case okCFrontPanel::brdXEM6310LX45:
		bitfileDefaultName = "evb1005-xem6310-lx45.bit"; break;
	case okCFrontPanel::brdXEM6310LX150:
		bitfileDefaultName = "evb1005-xem6310-lx150.bit"; break;
	case okCFrontPanel::brdXEM7310A75:
		bitfileDefaultName = "evb1005-xem7310-a75.bit"; break;
	case okCFrontPanel::brdXEM7310A200:
		bitfileDefaultName = "evb1005-xem7310-a200.bit"; break;
	case okCFrontPanel::brdXEM7320A75T:
		bitfileDefaultName = "szg-camera-xem7320-a75.bit"; break;
	case okCFrontPanel::brdXEM7350K70T:
		bitfileDefaultName = "evb1006-xem7350-k70t.bit"; break;
	case okCFrontPanel::brdXEM7350K160T:
		bitfileDefaultName = "evb1006-xem7350-k160t.bit"; break;
	case okCFrontPanel::brdZEM4310:
		bitfileDefaultName = "evb1007-zem4310.rbf"; break;
	case okCFrontPanel::brdXEM8320AU25P:
		return XEM8320::GetInfo(dev);
	case okCFrontPanel::brdUnknown:
		{
			okTDeviceInfo devInfo;
			dev->GetDeviceInfo(&devInfo);
			if (strcmp(devInfo.productName, "Test product") == 0) {
				// Allow using the test device as camera for, well, testing,
				// and pretend supporting an extra configuration to be able to
				// test multiple configuration support too.
				InfoResult info{Info{"Test", "test.bit"}};
				info.extraConfigs.emplace_back(
					"Test-EU",
					"test-EU.bit",
					"European"
				);
				return info;
			}
		}
		// fall through

	default:
		bitfileDefaultName = nullptr;
		break;
	}

	auto const modelStr = OpalKelly::FrontPanel::GetBoardModelString(model);
	if (!bitfileDefaultName)
		return InfoResult::Error{modelStr + " does not have a supported camera module."};

	return Info{modelStr, bitfileDefaultName};
}


/* static */
okSize
okCCamera::GetSizeWithSkips(okSize fullSize, int xSkips, int ySkips)
{
	okSize size;
	size.m_width =
		static_cast<int>(2.0 * ceil(fullSize.m_width / (2.0 * (xSkips + 1.0))));
	size.m_height =
		static_cast<int>(2.0 * ceil(fullSize.m_height / (2.0 * (ySkips + 1.0))));
	return size;
}


void
okCCameraDirectImpl::SetImageBufferDepth(int depth)
{
	// Set the bit #11 to switch to programmable mode and put the number of
	// frames to use in the lower 10 bits.
	m_dev->SetWireInValue(0x05, 0x400 | depth, 0x7ff);

	// Notice that we don't need to call UpdateWireIns() before calling
	// LogicReset() as it will do it internally anyhow.
	LogicReset();
}


void
okCCameraDirectEVB100xImpl::SetSkips(int x, int y, int len)
{
	I2CWrite8(MT9P031_REG_COLUMN_ADDRESS_MODE, (x << 4) | x);
	I2CWrite8(MT9P031_REG_ROW_ADDRESS_MODE, (y << 4) | y);

	m_dev->SetWireInValue(0x02, len & 0xffff);
	m_dev->SetWireInValue(0x03, len >> 16);

	LogicReset();
}


int
okCCameraDirectImpl::GetBufferedImageCount()
{
	return m_dev->GetWireOutValue(0x24);
}


void
okCCameraDirectImpl::EnablePingPong(bool enable)
{
	if (enable) {
		m_dev->SetWireInValue(0x00, 1 << 4, 1 << 4);
		m_dev->UpdateWireIns();
	}
	else {
		m_dev->SetWireInValue(0x00, 0 << 4, 1 << 4);
		m_dev->UpdateWireIns();
	}

	// Reset things
	m_dev->SetWireInValue(0x00, 1 << 3, 1 << 3);
	m_dev->UpdateWireIns();
	m_dev->SetWireInValue(0x00, 0 << 3, 1 << 3);
	m_dev->UpdateWireIns();
}


okCCamera::ErrorCode
okCCameraDirectImpl::BufferedCaptureV1(unsigned char *u8Image, unsigned ulLen)
{
	int i;
	long len = 0;

	m_dev->UpdateWireOuts();
	for (i = 0; i < 100; i++) {
		if (m_dev->GetWireOutValue(0x23) & 0x0300)   // Frame buffer full?
			break;
		Sleep(2);
		m_dev->UpdateWireOuts();
	}
	if (100 == i)
		return(okCCamera::Timeout);

	if (m_dev->GetWireOutValue(0x23) & 0x0100) {   // Frame ready (buffer A)
		m_dev->SetWireInValue(0x04, 0x0000);
		m_dev->SetWireInValue(0x05, 0x0000);
		m_dev->UpdateWireIns();
		m_dev->ActivateTriggerIn(0x40, 1);  // Readout start trigger
		if (okCFrontPanel::brdZEM4310 == m_dev->GetBoardModel()) {
			len = m_dev->ReadFromBlockPipeOut(0xA0, 128, ulLen, u8Image);
		}
		else {
			len = m_dev->ReadFromPipeOut(0xA0, ulLen, u8Image);
		}
		if (len < 0)
			return(okCCamera::ImageReadoutError);
		if (len != ulLen)
			return(okCCamera::ImageReadoutShort);
		m_dev->ActivateTriggerIn(0x40, 2);  // Readout done (buffer A)
	}
	else if (m_dev->GetWireOutValue(0x23) & 0x0200) {   // Frame ready (buffer B)
		m_dev->SetWireInValue(0x04, 0x0000);
		m_dev->SetWireInValue(0x05, 0x0080);
		m_dev->UpdateWireIns();
		m_dev->ActivateTriggerIn(0x40, 1);  // Readout start trigger
		if (okCFrontPanel::brdZEM4310 == m_dev->GetBoardModel()) {
			len = m_dev->ReadFromBlockPipeOut(0xA0, 128, ulLen, u8Image);
		}
		else {
			len = m_dev->ReadFromPipeOut(0xA0, ulLen, u8Image);
		}
		if (len < 0)
			return(okCCamera::ImageReadoutError);
		if (len != ulLen)
			return(okCCamera::ImageReadoutShort);
		m_dev->ActivateTriggerIn(0x40, 3);  // Readout done (buffer B)
	}

	return(okCCamera::NoError);
}


okCCamera::ErrorCode
okCCameraDirectImpl::BufferedCaptureV2(unsigned char *u8Image, unsigned ulLen)
{
	int i;
	long len = 0;

	m_dev->UpdateWireOuts();
	for (i = 0; i < 100; i++) {
		if (m_dev->GetWireOutValue(0x23) & 0x0100)   // Frame avail?
			break;
		Sleep(2);
		m_dev->UpdateWireOuts();
	}
	if (100 == i)
		return(okCCamera::Timeout);

	m_dev->ActivateTriggerIn(0x40, 0);
	if ((okCFrontPanel::brdZEM4310 == m_dev->GetBoardModel())) {
		len = m_dev->ReadFromBlockPipeOut(0xA0, 128, ulLen, u8Image);
	}
	else {
		len = m_dev->ReadFromPipeOut(0xA0, ulLen, u8Image);
	}
	m_dev->ActivateTriggerIn(0x40, 1);
	if (len < 0)
		return(okCCamera::ImageReadoutError);
	if (len != ulLen)
		return(okCCamera::ImageReadoutShort);

	return(okCCamera::NoError);
}


okCCamera::ErrorCode
okCCameraDirectImpl::SingleCaptureV1(unsigned char *u8Image, unsigned ulLen)
{
	int i;
	long len;

	//I2CWrite8(MT9P031_REG_READ_MODE1, 0x4006 | (1<<9) | (1<<8)); // Snapshot+ERS
	//I2CWrite8(MT9P031_REG_READ_MODE1, 0x4006 | (1<<9) | (1<<8) | (1<<7)); // Snapshot+GRR

	// PINGPONG = 0
	m_dev->SetWireInValue(0x00, 0 << 4, 1 << 4);
	// Set data length
	m_dev->SetWireInValue(0x02, ulLen & 0xffff);
	m_dev->SetWireInValue(0x03, ulLen >> 16);
	// Readout address = 0x00000000
	m_dev->SetWireInValue(0x04, 0x0000);
	m_dev->SetWireInValue(0x05, 0x0000);
	m_dev->UpdateWireIns();

	m_dev->UpdateTriggerOuts();
	m_dev->ActivateTriggerIn(0x40, 0);  // Capture trigger
	for (i = 0; i < 1000; i++) {
		Sleep(2);
		m_dev->UpdateTriggerOuts();
		if (m_dev->IsTriggered(0x60, 1 << 0))   // Frame done trigger
			break;
	}
	if (1000 == i)
		return(okCCamera::Timeout);

	m_dev->ActivateTriggerIn(0x40, 1);  // Readout start trigger
	if (okCFrontPanel::brdZEM4310 == m_dev->GetBoardModel()) {
		len = m_dev->ReadFromBlockPipeOut(0xA0, 128, ulLen, u8Image);
	}
	else {
		len = m_dev->ReadFromPipeOut(0xA0, ulLen, u8Image);
	}
	if (len < 0)
		return(okCCamera::ImageReadoutError);
	if (len != ulLen)
		return(okCCamera::ImageReadoutShort);
	m_dev->ActivateTriggerIn(0x40, 2);  // Readout done trigger

	return(okCCamera::NoError);
}


void
okCCameraDirectSZGImpl::I2CWrite16(unsigned long u16Addr, unsigned long u16Data)
{
	// You can read about this I2C configuration and usage at
	// our I2CController repository on our opalkelly-opensource
	// GitHub account.
	unsigned char buf[256];
	unsigned char data[2];
	data[0] = (u16Data >> 8) & 0xff;
	data[1] = u16Data & 0xff;
	buf[0] = (DEVICE_ADDRESS_AR0330 & 0xfe);
	buf[1] = (uint8_t)(u16Addr >> 8);
	buf[2] = (uint8_t)u16Addr;
	m_i2cDevice.Configure(3, 0x00, 0x00, buf);
	m_i2cDevice.Transmit(data, 0x02);
}


unsigned long
okCCameraDirectSZGImpl::I2CRead16(unsigned long u16Addr)
{
	// You can read about this I2C configuration and usage at
	// our I2CController repository on our opalkelly-opensource
	// GitHub account.
	unsigned long data = 0;
	unsigned char buf[256];
	buf[0] = (DEVICE_ADDRESS_AR0330 & 0xfe);
	buf[1] = (uint8_t)(u16Addr >> 8);
	buf[2] = (uint8_t)u16Addr;
	buf[3] = (DEVICE_ADDRESS_AR0330 | 0x01);
	m_i2cDevice.Configure(4, 0x04, 0x00, buf);
	m_i2cDevice.Receive(buf, 2);
	data = (buf[0] << 8) | buf[1];

	return(data);
}


void
okCCameraDirectSZGImpl::SetupOptimizedRegisterSet()
{
	// Setup sensor for 1080p 30fps
	I2CWrite16(AR0330_REG_HISPI_CONTROL_STATUS, 0x8400); // hispi_control setting
	I2CWrite16(AR0330_REG_SMIA_TEST, 0x1802); // Disable embedded Data
	I2CWrite16(AR0330_REG_DATA_FORMAT_BITS, 0x0A0A); // Data Width
	I2CWrite16(AR0330_REG_COMPRESSION, 0x0000); // Disable compression
	I2CWrite16(AR0330_REG_DATAPATH_SELECT, 0x0210); // Datapath select
	I2CWrite16(AR0330_REG_VT_PIX_CLK_DIV, 0x0005); // vt_pix_clk_div originally 0x0005
	I2CWrite16(AR0330_REG_PLL_MULTIPLIER, 0x0031); // pll_multiplier originally 0x0031
	I2CWrite16(AR0330_REG_OP_PIX_CLK_DIV, 0x000A); // op_pix_clk_div (data width)
	I2CWrite16(AR0330_REG_COARSE_INTEGRATION_TIME, 0x0400); // Increase exposure 400 for sensor+lens, 20 for bare sensor
	I2CWrite16(AR0330_REG_ANALOG_GAIN, 0x0018); // Set gain to ISO 400

	I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x0000); // 1 = Solid color test pattern, 2 = vertical color bars

	I2CWrite16(AR0330_REG_MODE_SELECT, 0x0100); // Enable streaming
}


int
okCCameraDirectSZGImpl::InitAfterConfigure()
{
	m_dev->SetTimeout(1000);

	AssertResets();
	ReleaseResets();

	// Finally perform logic reset
	LogicReset();

	// Setup image sensor registers
	ForAllCameras([this]() {
		SetupOptimizedRegisterSet();
	});

	// Determine which version of HDL do we use.
	m_dev->UpdateWireOuts();

	return m_dev->GetWireOutValue(0x3f);
}


void
okCCameraDirectSZGImpl::SetTestMode(bool enable, TestMode mode)
{
	ForAllCameras([=, this]() {
		if (false == enable) {
			I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x0);
		}
		else {
			switch (mode) {
			case ColorField:
				// Set test pattern for mix of red, green, and blue
				I2CWrite16(AR0330_REG_TEST_DATA_RED, 0x0dd0);
				I2CWrite16(AR0330_REG_TEST_DATA_GREENR, 0x0ee0);
				I2CWrite16(AR0330_REG_TEST_DATA_GREENB, 0x0ee0);
				I2CWrite16(AR0330_REG_TEST_DATA_BLUE, 0x0bb0);
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x1);
				break;
			case VerticalColorBars:
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x3);
				break;
			case Walking1s:
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0xFF);
				break;
			default:
			case Classic:
				I2CWrite16(AR0330_REG_TEST_PATTERN_MODE, 0x2);
				break;
			}
		}
	});
}


void
okCCameraDirectSZGImpl::SetGains(int r, int g1, int g2, int b)
{
	ForAllCameras([=, this]() {
		I2CWrite16(AR0330_REG_RED_GAIN, r & 0xFFFF);
		I2CWrite16(AR0330_REG_GREEN1_GAIN, g1 & 0xFFFF);
		I2CWrite16(AR0330_REG_GREEN2_GAIN, g2 & 0xFFFF);
		I2CWrite16(AR0330_REG_BLUE_GAIN, b & 0xFFFF);
	});
}


void
okCCameraDirectSZGImpl::SetOffsets(int r, int g1, int g2, int b)
{
	(void)r;
	(void)g1;
	(void)g2;
	(void)b;
	// TODO: Unsupported by sensor
}


void
okCCameraDirectSZGImpl::SetShutterWidth(int shutter)
{
	// line_length_pck is the number of pixel clock periods in one line. 1248 is 
	// the default value for AR0330_REG_LINE_LENGTH_PCK. You could alternatively 
	// perform I2CRead16(AR0330_REG_LINE_LENGTH_PCK) here, although this is faster.
	int line_length_pck = 1248;
	int pix_clk_ns = 34; // Pixel clock rate in ns
	int shutter_ms = (shutter * 250) / 10000;
	int shutter_llpck = 0; // Shutter time in terms of line_length_pck periods

	shutter_llpck = ((shutter_ms * 1000000)) / (line_length_pck * pix_clk_ns);

	ForAllCameras([=, this]() {
		I2CWrite16(AR0330_REG_COARSE_INTEGRATION_TIME, shutter_llpck & 0xFFFF);
	});
}


void
okCCameraDirectSZGImpl::SetSize(int x, int y)
{
	okSize size;
	size.m_width = x;
	size.m_height = y;
	size = GetPerCameraSize(size);

	ForAllCameras([=, this]() {
		I2CWrite16(AR0330_REG_X_ADDR_END, size.m_width + 6 - 1);
		I2CWrite16(AR0330_REG_Y_ADDR_END, size.m_height + 124 - 1);
	});
}


// Skip pixels in the sensor to return a lower resolution image.
// Supported values for the AR0330 are 0, 1, and 2 for both X and Y
void
okCCameraDirectSZGImpl::SetSkips(int x, int y, int len)
{
	ForAllCameras([=, this]() {
		if (x == 0) {
			I2CWrite16(AR0330_REG_X_ODD_INC, 1);
		}
		else if (x == 1) {
			I2CWrite16(AR0330_REG_X_ODD_INC, 3);
		}
		else if (x == 2) {
			I2CWrite16(AR0330_REG_X_ODD_INC, 5);
		}

		if (y == 0) {
			I2CWrite16(AR0330_REG_Y_ODD_INC, 1);
		}
		else if (y == 1) {
			I2CWrite16(AR0330_REG_Y_ODD_INC, 3);
		}
		else if (y == 2) {
			I2CWrite16(AR0330_REG_Y_ODD_INC, 5);
		}
	});

	m_dev->SetWireInValue(0x02, len & 0xffff);
	m_dev->SetWireInValue(0x03, len >> 16);

	LogicReset();
}


Result<CameraKind>
XEM8320::GetAttachedProduct(okCFrontPanel* dev)
{
	okCDeviceSettings settings;
	if (dev->GetDeviceSettings(settings) != okCFrontPanel::NoError) {
		return ErrorResult(
				"Failed to get device settings from the SZG device."
			);
	}

	std::string product;
	if (settings.GetString("SYZYGY0_PRODUCT_NAME", &product)
			!= okCFrontPanel::NoError) {
		return ErrorResult(
				"Failed to get attached device name from the SZG device."
			);
	}

	if (product == "SZG-CAMERA")
		return CameraKind::SZG;
	else if (product == "SZG-MIPI-8320")
		return CameraKind::Pcam;
	else
		return ErrorResult{
				"SZG-CAMERA or SZG-MIPI-8320 must be attached at Port A; " +
				product + " is not supported."
			};
}


okCCamera::InfoResult
XEM8320::GetInfo(okCFrontPanel* dev)
{
	auto const product = GetAttachedProduct(dev);
	if (!product)
	    return okCCamera::InfoResult::Error{product.take_error()};

	// Append the product name to board model string to make it different
	// depending on the camera, as we want to handle different camera
	// differently in the application.
	std::string cameraModel, bitfileDefaultName;
	switch (product.value) {
		case CameraKind::SZG:
			cameraModel = "XEM8320-AU25P-SZG-CAMERA";
			bitfileDefaultName = "szg-camera-xem8320";
			break;

		case CameraKind::Pcam:
			cameraModel = "XEM8320-AU25P-SZG-MIPI-8320";
			bitfileDefaultName = "szg-mipi-8320";
			break;

		case CameraKind::Other:
			break;
	}

	if (bitfileDefaultName.empty()) {
		// This should never happen as GetAttachedProduct() can return only the
		// values covered above.
		throw std::logic_error("unsupported SZG camera device");
	}

	// We also support multiple configurations for these devices, with the
	// special configuration with 3 cameras support. Right now we use the same
	// model and default bitfile names for the latter configuration, except
	// that we append this suffix to them.
	constexpr const char* SUFFIX_3CAMERA = "-3camera";

	okCCamera::InfoResult res{okCCamera::Info{cameraModel, bitfileDefaultName + ".bit"}};
	res.extraConfigs.emplace_back(
		cameraModel + SUFFIX_3CAMERA,
		bitfileDefaultName + SUFFIX_3CAMERA + ".bit",
		"3 cameras"
	);
	return res;
}


// okCCameraScriptImpl

okCCameraScriptImpl::okCCameraScriptImpl(okCFrontPanel* dev, CameraKind cameraKind)
{
	switch (cameraKind) {
		case CameraKind::SZG:
			m_cameraTraits.reset(new okAR0330Traits());
			break;

		case CameraKind::Pcam:
			m_cameraTraits.reset(new PcamTraits());
			break;

		case CameraKind::Other:
			m_cameraTraits.reset(new okMT9P031Traits());
			break;
	}

	m_scriptEngine.ConstructLua(*dev);

	// This is convenient when running the program after building it:
	// its current directory must then be "Bitfiles" subdirectory of
	// the source tree in order to find the bitfiles below and hence
	// the script is found in the specified relative path.
	m_scriptEngine.PrependToScriptPath("../Software/Common");

	m_scriptEngine.LoadFile("camera.lua");
}


okSize
okCCameraScriptImpl::GetDefaultSize() const
{
	return m_cameraTraits->GetDefaultSize();
}


std::vector<int>
okCCameraScriptImpl::GetSupportedSkips() const
{
	return m_cameraTraits->GetSupportedSkips();
}


std::vector<okCCameraValues::TestMode>
okCCameraScriptImpl::GetSupportedTestModes() const
{
	return m_cameraTraits->GetSupportedTestModes();
}


bool
okCCameraScriptImpl::SupportsOffsets() const
{
	return m_cameraTraits->SupportsOffsets();
}


okCCameraValues::ExposureValues
okCCameraScriptImpl::GetSupportedExposureValues() const
{
	return m_cameraTraits->GetSupportedExposureValues();
}


okCCameraValues::BayerFilter
okCCameraScriptImpl::GetBayerFilter() const
{
	return m_cameraTraits->GetBayerFilter();
}


int
okCCameraScriptImpl::InitAfterConfigure()
{
	const OpalKelly::ScriptValues
		rc = m_scriptEngine.RunScriptFunction("InitAfterConfigure");

	int nHDLVersion;
	if (rc.GetCount() != 1 || !rc.Get().GetAsInt(&nHDLVersion))
		nHDLVersion = -1;

	return nHDLVersion;
}


int
okCCameraScriptImpl::GetCapabilities()
{
	const OpalKelly::ScriptValues
		rc = m_scriptEngine.RunScriptFunction("GetCapabilities");

	int nHDLCapabilities;
	if (rc.GetCount() != 1 || !rc.Get().GetAsInt(&nHDLCapabilities))
		nHDLCapabilities = 0;

	return nHDLCapabilities;
}


void
okCCameraScriptImpl::LogicReset()
{
	m_scriptEngine.RunScriptFunction("LogicReset");
}


void
okCCameraScriptImpl::SetTestMode(bool enable, TestMode mode)
{
	OpalKelly::ScriptValues args;
	args.Add(enable);
	args.Add((int)mode);
	m_scriptEngine.RunScriptFunction("SetTestMode", args);
}


void
okCCameraScriptImpl::SetGains(int r, int g1, int g2, int b)
{
	OpalKelly::ScriptValues args;
	args.Add(r);
	args.Add(g1);
	args.Add(g2);
	args.Add(b);
	m_scriptEngine.RunScriptFunction("SetGains", args);
}


void
okCCameraScriptImpl::SetOffsets(int r, int g1, int g2, int b)
{
	OpalKelly::ScriptValues args;
	args.Add(r);
	args.Add(g1);
	args.Add(g2);
	args.Add(b);
	m_scriptEngine.RunScriptFunction("SetOffsets", args);
}


void
okCCameraScriptImpl::SetShutterWidth(int shutter)
{
	OpalKelly::ScriptValues args;
	args.Add(shutter);
	m_scriptEngine.RunScriptFunction("SetShutterWidth", args);
}


void
okCCameraScriptImpl::SetSize(int x, int y)
{
	OpalKelly::ScriptValues args;
	args.Add(x);
	args.Add(y);
	m_scriptEngine.RunScriptFunction("SetSize", args);
}


void
okCCameraScriptImpl::SetSkips(int x, int y, int len)
{
	OpalKelly::ScriptValues args;
	args.Add(x);
	args.Add(y);
	args.Add(len);
	m_scriptEngine.RunScriptFunction("SetSkips", args);
}


void
okCCameraScriptImpl::SetImageBufferDepth(int depth)
{
	OpalKelly::ScriptValues args;
	args.Add(depth);
	m_scriptEngine.RunScriptFunction("SetImageBufferDepth", args);
}


int
okCCameraScriptImpl::GetBufferedImageCount()
{
	const OpalKelly::ScriptValues
		rc = m_scriptEngine.RunScriptFunction("GetBufferedImageCount");

	int bufferedCount;
	if (rc.GetCount() != 1 || !rc.Get().GetAsInt(&bufferedCount))
		bufferedCount = 0;

	return bufferedCount;
}


void
okCCameraScriptImpl::EnablePingPong(bool enable)
{
	OpalKelly::ScriptValues args;
	args.Add(enable);
	m_scriptEngine.RunScriptFunction("EnablePingPong", args);
}


okCCamera::ErrorCode
okCCameraScriptImpl::DoCapture(
	const char *func,
	unsigned char *u8Image,
	unsigned len
)
{
	OpalKelly::ScriptValues rc;
	try {
		OpalKelly::ScriptValues args;
		args.Add(static_cast<int>(len));
		rc = m_scriptEngine.RunScriptFunction(func, args);
	}
	catch (const std::exception&) {
		// We have no way to return the error message from here, unfortunately.
		return Failed;
	}

	if (rc.GetCount() != 1) {
		// We expect exactly one return value.
		return Failed;
	}

	int err;
	if (rc.Get().GetAsInt(&err)) {
		if (err > 0 || err < -4) {
			// Invalid error value, replace it with a generic error.
			err = Failed;
		}

		return static_cast<ErrorCode>(err);
	}

	OpalKelly::Buffer buf;
	if (!rc.Get().GetAsBuffer(&buf) || buf.GetSize() != len) {
		return Failed;
	}

	// TODO: Get rid of this extra copy by reusing this buffer.
	memcpy(u8Image, buf.GetData(), len);

	return NoError;
}


okCCamera::ErrorCode
okCCameraScriptImpl::BufferedCaptureV1(unsigned char *u8Image, unsigned len)
{
	return DoCapture("BufferedCaptureV1", u8Image, len);
}


okCCamera::ErrorCode
okCCameraScriptImpl::BufferedCaptureV2(unsigned char *u8Image, unsigned len)
{
	return DoCapture("BufferedCaptureV2", u8Image, len);
}


okCCamera::ErrorCode
okCCameraScriptImpl::SingleCaptureV1(unsigned char *u8Image, unsigned len)
{
	return DoCapture("SingleCaptureV1", u8Image, len);
}
