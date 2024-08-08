//------------------------------------------------------------------------
// okCameraApp.h
//
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#ifndef __okCameraApp_H__
#define __okCameraApp_H__

#include <wx/filename.h>
#include "wx/frame.h"
#include <wx/thread.h>

#include "okFrontPanel.h"

#include "okCCamera.h"

#include <memory>
#include <vector>

class okCFPOIPInfo;
class okCFPManager;
class okCViewport;
class okCThreadCamera;
class okSensitiveString;

class wxButton;
class wxStaticBitmap;
class wxStaticText;
class wxCheckBox;
class wxChoice;
class wxSpinCtrl;
class wxToggleButton;
class wxTimer;
class wxTimerEvent;
class wxSpinEvent;
class wxSlider;
class wxGauge;
class wxPanel;
class wxScrolledWindow;

using wxTimerPtr = std::unique_ptr<wxTimer>;
using okCFPOIPInfoPtr = std::unique_ptr<okCFPOIPInfo>;
using okCFPManagerPtr = std::unique_ptr<okCFPManager>;

#ifdef __LINUX__
class MonitorBridge;
using MonitorBridgePtr = std::unique_ptr<MonitorBridge>;
#endif

// wxGenericAnimationCtrl implemented in wxWidgets v3.1.4.
class wxGenericAnimationCtrl;

extern const wxEventType okEVT_VISCAMIMAGE;

// An object of this type allows to uniquely identify a connected device.
struct CameraDeviceId {
	std::string serial;
	int configuration = -1;

	// Reset the object to the initial, uninitialized state.
	void Clear() {
		*this = CameraDeviceId();
	}

	// Only the default-initialized or reset ID is considered to be invalid.
	bool IsValid() const {
		return !serial.empty();
	}

	// Return a string representation of this ID, by appending the
	// configuration index to the serial number if it's valid.
	std::string ToString() const {
		std::string s = serial;
		if (configuration != -1) {
			s += ':';
			s += std::to_string(configuration);
		}

		return s;
	}

	// TODO-C++20: default these operators.
	bool operator==(const CameraDeviceId& other) const {
		return other.serial == serial && other.configuration == configuration;
	}

	bool operator!=(const CameraDeviceId& other) const {
		return !(*this == other);
	}

};

class CameraFrame : public wxFrame
{
public:
	CameraFrame();
	~CameraFrame();

	void Initialize();

	void SetupCamera();

	void OnClose(wxCloseEvent& event);
	void OnFPSTimer(wxTimerEvent& event);

	/// Messages sent from our camera communication thread.
	void OnCameraThread(wxThreadEvent& event);

	// GUI component handlers.
	void OnFPOIP(wxCommandEvent& event);
	void OnDevice(wxCommandEvent& event);
	void OnPipelineReset(wxCommandEvent& event);
	void OnCapture(wxCommandEvent& event);
	void OnDisplayEnable(wxCommandEvent& event);
	void OnCaptureMode(wxCommandEvent& event);
	void OnCaptureSize(wxCommandEvent& event);
	void OnSnapshotMode(wxCommandEvent& event);
	void OnExposure(wxSpinEvent& event);
	void OnAutoDepth(wxCommandEvent& event);
	void OnBufferDepth(wxCommandEvent& event);
	void OnUpdateUIBufferDepth(wxUpdateUIEvent& event);

	// Open the device from the current Front Panel manager.
	std::unique_ptr<OpalKelly::FrontPanel> Open(const char* serial);

	// Handle FrontPanelManager add/remove device events.
	void OnDeviceAdded(const char *serial);
	void OnDeviceRemoved(const char *serial);

private:
	// The helper class shows the activity indicator immediatly after
	// constructing and hides the indicator after the last camera thread
	// action. This class can be used from the main thread only.
	class ActivityIndicatorGuard
	{
	public:
		explicit ActivityIndicatorGuard(CameraFrame* frame);
		~ActivityIndicatorGuard();

	private:
		CameraFrame* m_frame;
	};

	// Return the full path for the given camera stored in the application
	// config (there is no guarantee that the returned path actually exists).
	static wxFileName GetBitfilePath(const okCCamera::Info& cameraInfo);

	// Delete the config record with the bit file path for the given camera.
	static void ResetBitfilePath(const okCCamera::Info& cameraInfo);

	// Show the file dialog to specify bit file path, store it in the config
	// and connect the device.
	void SelectBitfile( const CameraDeviceId& deviceId,
						const okCCamera::Info& cameraInfo,
						const wxFileName& startPath);

	// Start using the specified realm, provided as a okSensitiveString because
	// it can contain passwords, and also start monitoring it.
	void StartUsingRealm(const okSensitiveString& realm);

	// Select the device to use if there is no current device.
	void MakeDeviceActiveIfNecessary(const CameraDeviceId& deviceId);

	// Make the device current and select the item in the choice.
	void MakeDeviceActive(const CameraDeviceId& deviceId);

	// Make the device current.
	void DoSelectDevice(const CameraDeviceId& deviceId);

	// Disconnect the current camera device.
	void Disconnect();

	// Get the "skip" value corresponding to the current value of
	// m_chCaptureSize.
	int GetSkips() const;

	// Set up the correct range for the buffer depth-related controls using the
	// currently configured resolution.
	void SetupBufferDepthControls();

	// Start FPS timer and disable the capture button.
	void StartContinuous();

	// Undo the actions of StartContinuous() and also reset the values of the
	// controls updated during continuous capture.
	void StopContinuous();

	// Must be called after changing the camera buffer depth.
	void UpdateOnBufferDepthChange();

	// Update the devices choice items list.
	void UpdateDevicesChoice();

	// Update the viewport display mode.
	void UpdateDisplayMode();

	// Update the viewport zoom mode.
	void UpdateZoomMode();

	// Show the activity indicator.
	void ShowActivityIndicator();

	// Hide the activity indicator.
	void HideActivityIndicator();

	// Return the index in m_devices using the specified device ID or -1 if not
	// found.
	int FindDeviceById(const CameraDeviceId& deviceId) const;

	// Return information about the current camera. Throws on errors.
	okCCamera::Info GetCurrentCameraInfo() const;

	// Load the settings for the current camera and apply them to the
	// camera controls.
	void LoadCameraSettings();

	// Save the camera settings.
	void SaveCameraSettings();

	// Manager for all the connected devices.
	okCFPManagerPtr   m_okManager;

	// Data describing the last configured FPOIP connection, if any. Notice
	// that this pointer may be valid even if we don't use FPOIP right now, it
	// still keeps the data used the last time, while the current state is
	// indicated by m_usingFPOIP.
	okCFPOIPInfoPtr   m_fpoipServerInfo;

	// True if current manager is the FPOIP one, working with remote devices.
	bool              m_usingFPOIP = false;

	// Information we store about the available devices.
	struct DeviceInfo {
		DeviceInfo(CameraDeviceId deviceId, okCCamera::Info cameraInfo) :
			deviceId{std::move(deviceId)},
			cameraInfo{std::move(cameraInfo)}
		{
		}

		CameraDeviceId deviceId;
		okCCamera::Info cameraInfo;
	};

	// Currently connected devices, with devices supporting multiple
	// configurations appearing multiple times.
	std::vector<DeviceInfo> m_devices;

	okCThreadCamera   *m_thrCamera;

	// The ID of the currently used camera device or invalid if none.
	CameraDeviceId     m_currentCamera;

	// The number of active requests to show the activity indicator.
	int                m_activityCounter = 0;

#ifdef __LINUX__
	// A bridge used to link the manager with the main event loop.
	MonitorBridgePtr  m_monitorBridge;
#endif // __LINUX__

	wxGenericAnimationCtrl *m_animActivityIndicator;

	okCViewport       *m_vpViewPort;
	wxStaticBitmap    *m_bitmapLED;
	wxScrolledWindow  *m_scrolledSidebar;
	wxStaticText      *m_txtRealm;
	wxButton          *m_btnFPOIP;
	wxChoice          *m_chDevice;
	wxStaticText      *m_txtStatus;
	wxPanel           *m_panelCameraControls;
	wxStaticText      *m_txtFrameCount;
	wxStaticText      *m_txtMissedCount;
	wxCheckBox        *m_chkSnapshotMode;
	wxCheckBox        *m_chkDisplayEnable;
	wxButton          *m_btnCapture;
	wxButton          *m_btnPipelineReset;
	wxChoice          *m_chDisplayMode;
	wxChoice          *m_chZoomMode;
	wxChoice          *m_chCapture;
	wxChoice          *m_chCaptureSize;
	wxSpinCtrl        *m_spExposure;
	wxCheckBox        *m_chkAutoDepth;
	wxSlider          *m_slBufferDepth;
	wxGauge           *m_gaugeCurrentDepth;
	wxStaticText      *m_txtCurrentDepthMax;
	wxTimer           *m_timerFPS;
	wxTimerPtr        m_timerActivity;

	bool              m_bCameraSettingsChanged;
	int               m_nFPS;
	bool              m_bDisplayEnable;
	bool              m_bFlashEnable;
	bool              m_bGrayscale;

    DECLARE_EVENT_TABLE()
};


#endif // __okCameraApp_H__
