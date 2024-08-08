//------------------------------------------------------------------------
// okCCamera.h
//
// Class definition for image sensor communication.
//
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#ifndef __okCCamera_H__
#define __okCCamera_H__

#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "okFrontPanel.h"


// Helper defining some constants used in okCCamera API.
struct okCCameraValues
{
	enum TestMode {
			ColorField=0,
			HorizontalGradient=1,
			VerticalGradient=2,
			DiagonalGradient=3,
			Classic=4,
			Walking1s=5,
			MonochromeHorizontalBars=6,
			MonochromeVerticalBars=7,
			VerticalColorBars=8 };
	enum ErrorCode {
		NoError           = 0,
		Failed            = -1,
		Timeout           = -2,
		ImageReadoutShort = -3,
		ImageReadoutError = -4
	};

	struct ExposureValues {
		int def = 0, min = 0, max = 0;
	};

	// Describes the pattern of the Bayer filter used in this pixel order:
	//
	// +---+---+
	// + 1 + 2 +
	// +---+---+
	// + 3 + 4 +
	// +---+---+
	//
	// i.e. for the first value, used by most cameras, the top-left and bottom
	// right pixels are green.
	enum class BayerFilter {
		GRBG,
		BGGR
	};
};


struct okSize
{
	int m_width  = 0;
	int m_height = 0;
};


class okCCamera : public okCCameraValues
{
public:
	okCFrontPanel *m_dev;

private:
	okSize     m_size;
	int        m_nXskip;
	int        m_nYskip;
	int        m_nBytesPerPixel;
	// The HDL Version is pulled as a single Wire Output from the HDL.
	// The lower 8-bits represent the minor version while the upper 8-bits are
	// used to represent the major version (ie Version 2.4 is 0x0204)
	int        m_nHDLVersion;
	int        m_nHDLCapability;
	int        m_nMemSize;
	int        m_nImageBufferDepth;

	ErrorCode SingleCaptureV1(unsigned char *u8Image);
	ErrorCode BufferedCaptureV1(unsigned char *u8Image);
	ErrorCode BufferedCaptureV2(unsigned char *u8Image);

public:
	okCCamera();
	~okCCamera();

	// If a device object is provided, it will be used, otherwise the first
	// available locally connected device is used. The bit file path will be
	// used if it not empty, otherwise the path will be obtained by
	// GetBitfileName(). Finally, if the configuration index is different from
	// -1, it selects a non-default camera configuration (see InfoResult).
	//
	// The "message" argument is filled with the error message on failure but
	// may also contain a warning even if the function returns NoError.
	ErrorCode Initialize(
			std::string& message,
			OpalKelly::FrontPanel* dev = NULL,
			const std::string& bitfilePath = std::string(),
			int configuration = -1
		);
	bool IsOpen();
	void LogicReset();
	// Returns the default size for the camera CMOS sensor.
	okSize GetDefaultSize() const;
	// Returns the vector of supported by the sensor skips values.
	std::vector<int> GetSupportedSkips() const;
	// Returns the vector of supported by the sensor test modes.
	std::vector<TestMode> GetSupportedTestModes() const;
	// Return min, max and the recommended default values for the exposure
	// supported by this camera.
	ExposureValues GetSupportedExposureValues() const;
	// Return the filter to use for the "Nearest" interpolation mode.
	BayerFilter GetBayerFilter() const;

	// Whether SetOffsets() supported by the sensor.
	bool SupportsOffsets() const;
	void SetTestMode(bool enable, TestMode mode=VerticalColorBars);
	void SetGains(int r, int g1, int g2, int b);
	void SetOffsets(int r, int g1, int g2, int b);
	void SetShutterWidth(int shutter);
	void SetSize(int x, int y);
	void SetSkips(int x, int y);
	ErrorCode SetImageBufferDepth(int frames);
	void EnablePingPong(bool enable);
	unsigned GetFrameBufferSize();
	static int GetMinDepth();
	int GetMaxDepthForResolution();
	int GetBufferedImageCount();
	ErrorCode SingleCapture(unsigned char *u8Image);
	ErrorCode BufferedCapture(unsigned char *u8Image);

	// Struct contains some static information about the camera device.
	struct Info {
		Info(
				std::string cameraModel = std::string(),
				std::string bitfileDefaultName = std::string(),
				std::string configuration = std::string()
			) :
			cameraModel{std::move(cameraModel)},
			bitfileDefaultName{std::move(bitfileDefaultName)},
			configuration{std::move(configuration)}
		{
		}

		// This string is usually just the board model name, but can be
		// different from it for SZG devices that can have different cameras
		// attached to them. In any case, it uniquely identifies the given
		// camera model.
		std::string cameraModel;

		// The name of the default bitfile that should be used with this camera
		// model.
		std::string bitfileDefaultName;

		// Description of the configuration for non-default configurations.
		// This is just a free form human-readable string shown to the user in
		// the UI to describe the configuration.
		std::string configuration;
	};

	// Returns the information about the given device or an error message in
	// the other struct field if the device is not a supported camera device.
	struct InfoResult {
		// Error message if not empty. In this case the other fields are not
		// used.
		const std::string error;

		// Information about the primary or default camera configuration. Most
		// cameras have only a single configuration.
		const Info info;

		// Additional configurations supported by the camera, if any. The
		// indices into this vector may be passed to Initialize() to select a
		// non default configuration.
		std::vector<Info> extraConfigs;


		// Implicit ctor creates a valid object.
		InfoResult(Info&& info) : info{info} { }

		// This struct exists just to allow passing it to the ctor below.
		struct Error {
			Error(std::string&& message) : message{message} { }

			std::string message;
		};

		// Ctor used to create an invalid object.
		InfoResult(Error&& err) : error{err.message} { }

		// Allow testing whether the returned value is an error naturally.
		explicit operator bool() const { return error.empty(); }
	};

	static InfoResult GetInfo(OpalKelly::FrontPanel *dev);

	// Get the size from the full size when using the specified skip values.
	static okSize GetSizeWithSkips(okSize fullSize, int xSkips, int ySkips);

private:
	class okCCameraImpl* m_impl;
};


#endif // __okCCamera_H__
