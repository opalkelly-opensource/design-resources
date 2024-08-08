//------------------------------------------------------------------------
// okCameraApp.cpp
//
// This is the top-level entry-point for the EVB100x GUI application.
//
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#include "wx/wxprec.h"

// We need SVG support only available since wxWidgets 3.1.6.
#if !wxCHECK_VERSION(3,1,6)
#error wxWidgets 3.1.6 or later is required.
#endif

#include <wx/animate.h>
#include <wx/config.h>
#include <wx/display.h>
#include <wx/filedlg.h>
#include <wx/filefn.h>
#include <wx/gauge.h>
#include <wx/persist/toplevel.h>
#include <wx/sizer.h>
#include <wx/slider.h>
#include <wx/spinctrl.h>
#include <wx/statline.h>
#include <wx/stdpaths.h>
#include <wx/valnum.h>
#include <wx/wupdlock.h>
#include <wx/xrc/xh_slidr.h>

#include <exception>
#include <set>

#include "okCameraApp.h"
#include "okCBitmapListDecoder.h"
#include "okCViewport.h"
#include "okCThreadCamera.h"
#include "okResources.h"
#include "okSensitiveString.h"
#include "okwx.h"
#include "i2c_api.h"

#include <wx/generic/animate.h>

// Delay for ShowActivityIndicator().
#define ACTIVITY_INDICATOR_DELAY 500

// Constants for "Image Capture" capture mode.
constexpr const int   IMAGE_CAPTURE_ID = 100;
constexpr const char* IMAGE_CAPTURE_NAME = wxTRANSLATE("Image Capture");

// The names of the key to save the frame geometry by the persistent object.
constexpr const char* PERSIST_FRAME_KIND   = "CameraFrame";

// Names of keys prefixes for corresponding camera controls to save they values
// in the config.
constexpr const char* CONFIG_EXPOSURE     = "Exposure";
constexpr const char* CONFIG_DISPLAY_MODE = "DisplayMode";
constexpr const char* CONFIG_CAPTURE_SIZE = "CaptureSize";
constexpr const char* CONFIG_ZOOM_MODE    = "ZoomMode";
constexpr const char* CONFIG_CAPTURE_MODE = "CaptureMode";
constexpr const char* CONFIG_AUTO_DEPTH   = "AutoDepth";
constexpr const char* CONFIG_BUFFER_DEPTH = "BufferDepth";

#if defined(__LINUX__)
	#include <wx/evtloop.h>
	#include <wx/evtloopsrc.h>

	// A bridge between wxWidgets main event loop and FrontPanelManager.
	//
	// Implements wxEventLoopSourceHandler interface allowing to register it
	// with wxWidgets event loop in order to handle udev notifications without
	// blocking.
	class MonitorBridge : public wxEventLoopSourceHandler
	{
	public:
		// This object must be constructed only once the event loop is running
		// as we need to register the associated file descriptor with it.
		MonitorBridge(const OpalKelly::FrontPanelManager::CallbackInfo& info) :
			m_info(info)
		{
			const wxEventLoopBase *evtloop = wxTheApp ? wxTheApp->GetMainLoop()
													  : NULL;
			wxCHECK_RET( evtloop, "Should have an event loop by now" );

			m_loopSrc = std::unique_ptr<wxEventLoopSource>(
							evtloop->AddSourceForFD(
								m_info.fd,
								this,
								wxEVENT_SOURCE_INPUT
							)
						);
		}

		// Implement methods inherited from wxEventLoopSourceHandler.
		//
		// Only the first of them is really called as we only register the file
		// descriptor for reading, but all must be implemented as they're pure
		// virtual in the base class.
		void OnReadWaiting() override
		{
			(*m_info.callback)(m_info.param);
		}

		void OnWriteWaiting() override { }
		void OnExceptionWaiting() override { }

	private:
		const OpalKelly::FrontPanelManager::CallbackInfo m_info;
		std::unique_ptr<wxEventLoopSource> m_loopSrc;

		wxDECLARE_NO_COPY_CLASS(MonitorBridge);
	};
#endif // __LINUX__

CameraFrame::ActivityIndicatorGuard::ActivityIndicatorGuard(CameraFrame* frame)
	: m_frame(frame)
{
	m_frame->ShowActivityIndicator();
}


CameraFrame::ActivityIndicatorGuard::~ActivityIndicatorGuard()
{
	// Copy the frame pointer because when CallAfter() will be called,
	// the instance of the guard will be already destroyed so we can't
	// capture `this` in lambdas.
	CameraFrame* frame = m_frame;

	// We want to hide the activity indicator once the camera thread finishes
	// handling all the outstanding requests, so we need to schedule doing it
	// there, but we also have to do it in the main frame itself, hence the
	// nested `CallXXX()` calls.
	m_frame->m_thrCamera->CallInCameraThread([frame]() {
		frame->CallAfter([frame]() {
			frame->HideActivityIndicator();
		});
	});
}


// Implement the XRC handler for the slider to add wxSL_MIN_MAX_LABELS style.
// Use our own handler to support wxWidgets v3.0.4 (the style was added to
// wxSliderXmlHandler in v3.1.1).
class okCSliderXmlHandler : public wxSliderXmlHandler
{
public:
	okCSliderXmlHandler()
	{
		if (m_styleNames.Index("wxSL_MIN_MAX_LABELS") == wxNOT_FOUND) {
			XRC_ADD_STYLE(wxSL_MIN_MAX_LABELS);
		}
	}

	bool CanHandle(wxXmlNode *node) override
	{
		return IsOfClass(node, "okCSlider");
	}
};

// The implementation of the Front Panel manager. Its implementation is
// separate from the frame to allow recreating just the manager to use the
// another realm.
class okCFPManager : public OpalKelly::FrontPanelManager
{
public:
	// Note that creating this object doesn't fully initialize it and
	// StartDeviceProcessing() must be called later to actually detect the
	// currently connected devices, see the code in StartUsingRealm().
	okCFPManager(CameraFrame* frame, const std::string& realm) :
		OpalKelly::FrontPanelManager(realm),
		m_frame(frame)
	{
	}

	// Call OnDeviceAdded() for all the currently connected devices and ensure
	// that OnDevice{Added,Removed}() are called for all the future device
	// [dis]connections.
	void StartDeviceProcessing()
	{
		m_processingStarted = true;
		for (const auto& serial : m_pendingDevices) {
			m_frame->OnDeviceAdded(serial.c_str());
		}
		m_pendingDevices.clear();
	}

	// FrontPanelManager pure virtual methods.
	void OnDeviceAdded(const char* serial) override
	{
		// Copy the serial into the string to allow safe lambda capturing.
		const std::string serialStr = serial;
		const auto processAddedDevice = [this, serialStr]() {
			if (m_processingStarted)
				m_frame->OnDeviceAdded(serialStr.c_str());
			else
				m_pendingDevices.insert(serialStr);
		};
		// FrontPanelManager::OnDeviceAdded() can be called from the separate non-main
		// thread so use CallAfter() in this case.
		if (wxIsMainThread())
			processAddedDevice();
		else
			m_frame->CallAfter(processAddedDevice);
	}

	void OnDeviceRemoved(const char* serial) override
	{
		// Copy the serial into the string to allow safe lambda capturing.
		std::string serialStr = serial;
		const auto processRemovedDevice = [this, serialStr]() {
			if (m_processingStarted)
				m_frame->OnDeviceRemoved(serialStr.c_str());
			else
				m_pendingDevices.erase(serialStr);
		};
		// See OnDeviceAdded().
		if (wxIsMainThread())
			processRemovedDevice();
		else
			m_frame->CallAfter(processRemovedDevice);
	}

private:
	CameraFrame* m_frame = NULL;
	bool m_processingStarted = false;
	std::set<std::string> m_pendingDevices;
};

// Simple container for the data we need to connect to a remote FPOIP server.
class okCFPOIPInfo
{
public:
	// This method is used to construct an object of this class: it tries to
	// restore it from wxConfig and fills it with the default values if it
	// couldn't.
	static
	okCFPOIPInfoPtr RestoreFromConfig()
	{
		okCFPOIPInfoPtr info(new okCFPOIPInfo{});

		auto& config = *wxConfig::Get();
		if (config.Exists(CONFIG_FPOIP_ROOT)) {
			info->m_hostname = config.Read(GetFieldPath(CONFIG_FPOIP_HOST));
			info->m_username = config.Read(GetFieldPath(CONFIG_FPOIP_USER));

			// wxConfig doesn't provide overload for uint16_t, so handle this
			// one specially.
			long l;
			if (config.Read(GetFieldPath(CONFIG_FPOIP_PORT), &l) &&
					l >= 0 && l <= UINT16_MAX ) {
				info->m_port = static_cast<std::uint16_t>(l);
			} // else: Value in config absent or invalid, use the default port.
		}

		return info;
	}

	// This should be used to save the object to wxConfig to preserve its
	// contents for the future runs.
	//
	// Note that we intentionally do not save the password here, as we don't
	// want passwords to be stored as plain text in the registry or dot-file.
	void SaveToConfig() const
	{
		auto& config = *wxConfig::Get();

		config.Write(GetFieldPath(CONFIG_FPOIP_HOST), m_hostname);
		config.Write(GetFieldPath(CONFIG_FPOIP_USER), m_username);
		config.Write(GetFieldPath(CONFIG_FPOIP_PORT), m_port);
	}


	// There is only a single object of this class in the program, so neither
	// copying nor moving it is necessary (even if it could be easily allowed).
	okCFPOIPInfo(okCFPOIPInfo const&) = delete;
	okCFPOIPInfo& operator=(okCFPOIPInfo const&) = delete;


	// Show the dialog allowing the user to edit the different fields.
	//
	// Returns true if valid values were entered and the dialog was accepted or
	// false if it was cancelled (the dialog can't be accepted with wrong
	// values).
	bool GetFromUser(wxWindow* parent)
	{
		// Load the dialog from the resources and find the controls we need.
		wxDialog dlg;
		Resources::LoadDialog(&dlg, parent, "dlg_fpoip_server");

		const auto msgError = Resources::Find<wxStaticText>(&dlg, "msg_error");

		const auto textHostname = Resources::Find<wxTextCtrl>(&dlg, "text_hostname");
		const auto textUsername = Resources::Find<wxTextCtrl>(&dlg, "text_username");
		const auto textPassword = Resources::Find<wxTextCtrl>(&dlg, "text_password");
		const auto textPort = Resources::Find<wxTextCtrl>(&dlg, "text_port");

		const auto btnOK = Resources::Find<wxButton>(&dlg, "wxID_OK");
		btnOK->SetDefault();
		textHostname->SetFocus();

		// Ensure that the data is automatically transferred between our fields
		// and the controls.
		textHostname->SetValidator(wxTextValidator(wxFILTER_NONE, &m_hostname));
		textUsername->SetValidator(wxTextValidator(wxFILTER_NONE, &m_username));
		textPassword->SetValidator(wxTextValidator(wxFILTER_NONE, &m_password));
		textPort->SetValidator(wxMakeIntegerValidator(&m_port));

		// Set up global validation.
		btnOK->Bind(
			wxEVT_UPDATE_UI,
			[=](wxUpdateUIEvent& event) {
			wxString error;
			if (textHostname->IsEmpty()) {
				error = "Please enter the host name";
			}
			else if (textUsername->IsEmpty() && !textPassword->IsEmpty()) {
				error = "Please specify the user name";
			}

			if (error != msgError->GetLabelText())
				msgError->SetLabelText(error);

			// Only allow closing the dialog if there are no errors.
			event.Enable(error.empty());
		}
		);

		return dlg.ShowModal() == wxID_OK;
	}


	// Check if the given realm string corresponds to FPoIP.
	static bool IsFPoIPRealm(const std::string& realm)
	{
		return realm.compare(0, 8, "fpoip://") == 0;
	}

	// Build the realm string suitable for use with okCFrontPanelManager.
	okSensitiveString GetRealmString() const
	{
		std::size_t secretBegin = std::string::npos;
		std::size_t secretEnd = std::string::npos;

		std::string realm{ "fpoip://" };
		if (!m_username.empty()) {
			realm += wx2std(m_username);
			if (!m_password.empty()) {
				realm += ':';
				secretBegin = realm.length();
				realm += wx2std(m_password);
				secretEnd = realm.length();
			}
			realm += '@';
		}

		realm += wx2std(m_hostname);
		realm += ':';
		realm += std::to_string(m_port);

		return okSensitiveString{realm, secretBegin, secretEnd};
	}

private:
	static constexpr const char* CONFIG_FPOIP_ROOT = "FPoIP";

	static constexpr const char* CONFIG_FPOIP_HOST = "Host";
	static constexpr const char* CONFIG_FPOIP_USER = "User";
	static constexpr const char* CONFIG_FPOIP_PORT = "Port";

	// Helper returning the config path for the field with the given name.
	static
	wxString GetFieldPath(const char* name)
	{
		return wxString::Format("%s/%s", CONFIG_FPOIP_ROOT, name);
	}

	okCFPOIPInfo() = default;

	wxString m_hostname;
	wxString m_username;
	wxString m_password;
	std::uint16_t m_port = 9999;
};

namespace
{
	// Return the name of the key storing the preferred configuration for the
	// device with the given serial number or -1 if not found.
	inline wxString
	GetConfigurationConfigKey(const char* serial) {
		return wxString::Format("Configuration/%s", serial);
	}

	// Return a camera-specific key name.
	//
	// Right now this function is trivial, as we just use the name of the
	// camera model from the struct, but we could have other fields in it that
	// we'd like to use later.
	inline wxString
	GetCameraKey(const okCCamera::Info& cameraInfo, const wxString& key) {
		return wxString::Format("%s/%s", cameraInfo.cameraModel, key);
	}

	inline wxString
	GetBitfileConfigKey(const okCCamera::Info& cameraInfo)
	{
		return GetCameraKey(cameraInfo, "Bitfile");
	}

	void SetChoiceClientData(wxChoice* choice, const wxString& item, void* data)
	{
		const int idx = choice->FindString(item);
		if (idx == wxNOT_FOUND) {
			throw new std::runtime_error(wx2std(wxString::Format(
				"Failed to find choice item \"%s\".",
				item
			)));
		}
		choice->SetClientData(idx, data);
	}

	int GetControlValue(wxChoice* control) {
		int const sel = control->GetCurrentSelection();
		wxASSERT_MSG( sel != wxNOT_FOUND, "Shouldn't be saving invalid selection" );
		return sel;
	}
	void SetControlValue(wxChoice* control, int value) {
		wxCHECK_RET( value != wxNOT_FOUND, "Shouldn't be restoring invalid selection" );
		return control->SetSelection(value);
	}

	int GetControlValue(wxSpinCtrl* control) { return control->GetValue(); }
	void SetControlValue(wxSpinCtrl* control, int value) { return control->SetValue(value); }

	bool GetControlValue(wxCheckBox* control) { return control->GetValue(); }
	void SetControlValue(wxCheckBox* control, bool value) { return control->SetValue(value); }

	int GetControlValue(wxSlider* control) { return control->GetValue(); }
	void SetControlValue(wxSlider* control, int value)
	{
		// Increase the maximum value of the slider if necessary to not crop
		// the restored value with the current slider max value.
		if (control->GetMax() < value) {
			control->SetMax(value);
		}
		return control->SetValue(value);
	}

	template <typename Control>
	bool ReadValueFromConfig(Control* control, const okCCamera::Info& cameraInfo, const char* prefix)
	{
		wxString const key = GetCameraKey(cameraInfo, prefix);
		if (wxConfig::Get()->Exists(key)) {
			// GetControlValue() used to select the right variant of Read() function.
			const auto value = wxConfig::Get()->Read(key, GetControlValue(control));
			SetControlValue(control, value);
			return true;
		}
		return false;
	}

	template <typename Control>
	void WriteValueToConfig(Control* control, const okCCamera::Info& cameraInfo, const char* prefix)
	{
		wxString key = GetCameraKey(cameraInfo, prefix);
		wxConfig::Get()->Write(key, GetControlValue(control));
	}

	wxString GetTestModeString(okCCamera::TestMode mode)
	{
		switch (mode) {
			case okCCamera::ColorField:
				return _("Test: Color Field");
			case okCCamera::HorizontalGradient:
				return _("Test: Horizontal Gradient");
			case okCCamera::VerticalGradient:
				return _("Test: Vertical Gradient");
			case okCCamera::DiagonalGradient:
				return _("Test: Diagonal");
			case okCCamera::Classic:
				return _("Test: Classic");
			case okCCamera::Walking1s:
				return _("Test: Walking 1s");
			case okCCamera::MonochromeHorizontalBars:
				return _("Test: Monochrome Horizontal Bars");
			case okCCamera::MonochromeVerticalBars:
				return _("Test: Monochrome Vertical Bars");
			case okCCamera::VerticalColorBars:
				return _("Test: Vertical Color Bars");
		};
		return {};
	}
}


class okCameraApp : public wxApp
{
public:
	virtual bool OnInit();
};

DECLARE_APP(okCameraApp)

IMPLEMENT_APP(okCameraApp)


bool
okCameraApp::OnInit()
{
	if (!wxApp::OnInit())
		return false;

	std::string error;
	try {
		SetAppName("CameraApp");
		SetVendorName("Opal Kelly");

		wxImage::AddHandler(new wxPNGHandler);
		Resources::Get().AddHandler(new okCSliderXmlHandler());
		Resources::Get().AddHandler(new okCXmlViewportHandler());
		wxAnimation::AddHandler(new okCBitmapListDecoder());
		Resources::Init();

		CameraFrame *frame = new CameraFrame;

#if defined(_DEBUG)
		wxLogWindow *log = new wxLogWindow(frame, "Debug Log", false, true);
		log->GetFrame()->SetSize(500,200);
		log->Show();
		wxLog::SetActiveTarget(log);
#endif // _DEBUG

		return true;
	} catch (const std::exception& e) {
		error = e.what();
	} catch (...) {
		error = "Unexpected exception occurred.";
	}

	wxLogError(_("Program initialization failed: %s"), error.c_str());
	return false;
}


//------------------------------------------------------------------------
// Main window (CameraFrame)
//------------------------------------------------------------------------
BEGIN_EVENT_TABLE(CameraFrame, wxFrame)
	EVT_CLOSE(CameraFrame::OnClose)
	EVT_TIMER(wxID_ANY, CameraFrame::OnFPSTimer)
END_EVENT_TABLE()


CameraFrame::CameraFrame()
{
	Resources::LoadFrame(this, "frame_main");

#if defined(_WIN32)
	SetIcon(wxICON(appicon));
#endif

	m_timerFPS = new wxTimer(this);
	m_thrCamera = new okCThreadCamera(this);
	Bind(wxEVT_THREAD, &CameraFrame::OnCameraThread, this);

	m_bCameraSettingsChanged = true;
	m_nFPS = 0;

	m_bDisplayEnable = false;
	m_bGrayscale = false;
	m_bFlashEnable = false;

	CreateStatusBar();
	Initialize();

	// We can't do this immediately because we need a running event loop in
	// order to receive notifications under Linux, so call this function
	// slightly later, when the event loop will be already running.
	CallAfter([this]() {
		// Allow specifying the default realm via this environment variable.
		// This is mostly useful for testing.
		auto realm = getenv("okFP_REALM");
		StartUsingRealm(okSensitiveString{realm ? realm : okREALM_LOCAL});
	});

	Show();
}



CameraFrame::~CameraFrame()
{
	// Save the camera settings if we have connected camera.
	if (m_currentCamera.IsValid()) {
		SaveCameraSettings();
	}

	// Wait until the control thread ends.
	m_thrCamera->ClearCameraThreadQueue();
	// Stop the camera thread.
	m_thrCamera->Quit();
	Unbind(wxEVT_THREAD, &CameraFrame::OnCameraThread, this);

	// Wait for the thread termination.
	m_thrCamera->Wait();

	// And delete it.
	delete m_thrCamera;

	if (m_timerFPS)
		delete m_timerFPS;
}



void
CameraFrame::OnCameraThread(wxThreadEvent& evt)
{
	wxString str;

	if (okCThreadCamera::SetupGood == evt.GetInt()) {
		// Show the activity indicator while setting up GUI controls.
		ActivityIndicatorGuard guard(this);

		// Update the list of available sizes.
		m_thrCamera->CallInCameraThread([this]() {
			okCCamera& camera = m_thrCamera->GetCamera();
			const auto defaultSize = camera.GetDefaultSize();
			const auto supportedSkips = camera.GetSupportedSkips();
			const auto supportedTestModes = camera.GetSupportedTestModes();
			const auto exposure = camera.GetSupportedExposureValues();
			CallAfter([this, defaultSize, supportedSkips, supportedTestModes, exposure]() {
				m_chCaptureSize->Clear();
				for (int skips : supportedSkips) {
					const auto currentSize = okCCamera::GetSizeWithSkips(defaultSize, skips, skips);
					const wxString itemText =
						wxString::Format("%d x %d", currentSize.m_width, currentSize.m_height);
					m_chCaptureSize->Append(itemText, wxUIntToPtr(skips));
				}
				if (!supportedSkips.empty())
					m_chCaptureSize->SetSelection(0);

				// Update the list of supported test modes.
				m_chCapture->Clear();
				for (const auto mode : supportedTestModes) {
					const wxString itemText = GetTestModeString(mode);
					m_chCapture->Append(itemText, wxUIntToPtr(mode));
				}
				m_chCapture->Append(wxGetTranslation(IMAGE_CAPTURE_NAME), wxUIntToPtr(IMAGE_CAPTURE_ID));
				m_chCapture->SetSelection(m_chCapture->GetCount() - 1);

				m_spExposure->SetRange(exposure.min, exposure.max);
				m_spExposure->SetValue(exposure.def);

				// Load the camera settings only after controls configuring.
				LoadCameraSettings();
				// Show the activity indicator while setting up the buffer
				// depth-related controls.
				ActivityIndicatorGuard guard(this);

				// Set up the range of buffer depth controls. We can do this only
				// after setting up the sizes choice.
				SetupBufferDepthControls();

				// And now the camera is ready.
				m_txtStatus->SetLabel(wxT("Camera Ready"));

				// Show controls.
				m_panelCameraControls->Show();

				// Relayout the controls inside the scrollable area and recalculate
				// the virtual size.
				m_scrolledSidebar->FitInside();
				Layout();
			});
		});
		return;
	}

	// For all the other events, we're only interested in them if they're for
	// the current device and not for the device that we have already
	// disconnected from -- but events for which we may still receive after
	// disconnecting, as they happen asynchronously.
	const auto deviceId = evt.GetPayload<CameraDeviceId>();
	if (deviceId != m_currentCamera) {
		wxLogDebug(R"(Ignoring late event from "%s", current camera is "%s".)",
				   deviceId.ToString(), m_currentCamera.ToString());
		return;
	}

	if (okCThreadCamera::SetupFail == evt.GetInt()) {
		const int n = FindDeviceById(deviceId);
		if (n != -1) {
			// Setup might have failed because of a bad bit file so reset
			// the bit file path to let the user select another one.
			ResetBitfilePath(m_devices.at(n).cameraInfo);
		}

		// Hide controls.
		m_panelCameraControls->Hide();
		m_scrolledSidebar->FitInside();
		Layout();

		m_currentCamera.Clear();
		m_chDevice->SetSelection(wxNOT_FOUND);
		m_txtStatus->SetLabel(wxT("Camera Setup Failed"));
	} else if (okCThreadCamera::CaptureGood == evt.GetInt()) {
		m_nFPS++;
		if (m_txtStatus->GetLabel() != "Camera Ready")
			m_txtStatus->SetLabel("Camera Ready");

		m_vpViewPort->UpdateImage(m_thrCamera->GetImageData());

		wxString str;
		str.Printf("Missed frames: %ld", evt.GetExtraLong());
		if (m_txtMissedCount->GetLabel() != str) {
			m_txtMissedCount->SetLabel(str);
			// Layout the controls panel to avoid m_txtMissedCount text cropping.
			m_panelCameraControls->Layout();
		}

		// Update camera settings for the next frame if necessary.
		SetupCamera();
	} else if (okCThreadCamera::CaptureShort == evt.GetInt()) {
		m_txtStatus->SetLabel("Capture Readout Short");
	} else if (okCThreadCamera::CaptureTimeout == evt.GetInt()) {
		m_txtStatus->SetLabel("Capture Timeout");
	} else if (okCThreadCamera::CaptureFail == evt.GetInt()) {
		m_txtStatus->SetLabel("Capture Fail");

		StopContinuous();
	} else if (okCThreadCamera::Error == evt.GetInt()) {
		m_txtStatus->SetLabel("Error: " + evt.GetString());
	}
}


void
CameraFrame::SetupCamera()
{
	if (!m_bCameraSettingsChanged)
		return;

	m_bCameraSettingsChanged = false;

	const int skips = GetSkips();

	const int captureMode =
		wxPtrToUInt(m_chCapture->GetClientData(m_chCapture->GetSelection()));

	const int IMAGE_BUFFER_DEPTH_AUTO = -1;
	const int bufferDepth = m_chkAutoDepth->GetValue()
		? IMAGE_BUFFER_DEPTH_AUTO
		: m_slBufferDepth->GetValue();

	const int exposure = m_spExposure->GetValue();
	m_thrCamera->CallInCameraThread([this, exposure, skips, captureMode, bufferDepth]() {
		okCCamera& camera = m_thrCamera->GetCamera();

		const auto bayerFilter = camera.GetBayerFilter();
		const auto size =
			okCCamera::GetSizeWithSkips(camera.GetDefaultSize(), skips, skips);
		CallAfter([this, size, bayerFilter]() {
			m_vpViewPort->SetImageFormat(size.m_width, size.m_height, 1);
			m_vpViewPort->SetBayerFilter(bayerFilter);
		});

		camera.SetShutterWidth(exposure);

		m_thrCamera->SetupSizeBySkips(skips);

		if (IMAGE_CAPTURE_ID == captureMode)
			camera.SetTestMode(false, okCCamera::ColorField);
		else
			camera.SetTestMode(true, (okCCamera::TestMode)captureMode);

		camera.SetImageBufferDepth(bufferDepth);
	});
}


int
CameraFrame::GetSkips() const
{
	return wxPtrToUInt(m_chCaptureSize->GetClientData(m_chCaptureSize->GetSelection()));
}


void
CameraFrame::UpdateOnBufferDepthChange()
{
	if (m_chkAutoDepth->IsChecked()) {
		m_txtCurrentDepthMax->SetLabelText("n/a");

		m_thrCamera->CallInCameraThread([this]() {
			const int maxDepth = m_thrCamera->GetCamera().GetMaxDepthForResolution();
			CallAfter([this, maxDepth]() {
				// Use the maximum depth value for the automatic mode.
				m_gaugeCurrentDepth->SetRange(maxDepth);

				m_panelCameraControls->Layout();
			});
		});
	} else {
		// The gauge shows the fill level of the buffer, up to its depth as it
		// is currently configured (this will be updated whenever the slider
		// value changes).
		const int depth = m_slBufferDepth->GetValue();
		m_gaugeCurrentDepth->SetRange(depth);
		m_txtCurrentDepthMax->SetLabelText(wxString::Format("%d", depth));

		m_panelCameraControls->Layout();
	}
}


void
CameraFrame::SetupBufferDepthControls()
{
	const int skips = GetSkips();
	m_thrCamera->CallInCameraThread([this, skips]() {
		m_thrCamera->SetupSizeBySkips(skips);

		const int maxDepth = m_thrCamera->GetCamera().GetMaxDepthForResolution();
		CallAfter([this, maxDepth]() {
			// The slider allows to select the buffer depth, up to the maximum
			// supported by the device in the current resolution.
			m_slBufferDepth->SetRange(okCCamera::GetMinDepth(), maxDepth);
		});
	});

	UpdateOnBufferDepthChange();
}



void 
CameraFrame::OnCapture(wxCommandEvent& event)
{
	ActivityIndicatorGuard guard(this);
	SetupCamera();

	m_bitmapLED->Show();
	m_thrCamera->CallInCameraThread([this]() {
		m_thrCamera->SingleCapture();

		CallAfter([this]() {
			m_bitmapLED->Hide();
		});
	});
	m_txtStatus->SetLabel("Single Capture...");
}


void
CameraFrame::OnFPSTimer(wxTimerEvent& WXUNUSED(event))
{
	wxString str;
	str.Printf("FPS: %d", m_nFPS);
	m_txtFrameCount->SetLabel(str);
	m_nFPS = 0;

	// Reuse this timer for updating the buffer depth too.
	m_thrCamera->CallInCameraThread([this]() {
		const int currentDepth = m_thrCamera->GetCamera().GetBufferedImageCount();
		CallAfter([this, currentDepth]() {
			m_gaugeCurrentDepth->SetValue(currentDepth);
		});
	});
}


void
CameraFrame::OnFPOIP(wxCommandEvent& event)
{
	// Determine the new realm to use.
	if (m_usingFPOIP) {
		StartUsingRealm(okSensitiveString{okREALM_LOCAL});
	} else {
		if (!m_fpoipServerInfo)
			m_fpoipServerInfo = okCFPOIPInfo::RestoreFromConfig();

		if (!m_fpoipServerInfo->GetFromUser(this)) {
			// The dialog was cancelled, don't do anything.
			return;
		}

		m_fpoipServerInfo->SaveToConfig();

		StartUsingRealm(m_fpoipServerInfo->GetRealmString());
	}
}


void
CameraFrame::OnDevice(wxCommandEvent& event)
{
	const int selection = m_chDevice->GetCurrentSelection();
	if (selection == wxNOT_FOUND)
		return;

	const auto& deviceId = m_devices.at(selection).deviceId;

	if (deviceId == m_currentCamera) {
		m_txtStatus->SetLabel("The device already connected");
		return;
	}

	m_txtStatus->SetLabel(
		wxString::Format("Connecting to %s...", deviceId.ToString())
	);

	// Ensure we apply the settings to the new camera, even if the UI controls
	// retain the same values they had before, which were used with the old one.
	m_bCameraSettingsChanged = true;

	DoSelectDevice(deviceId);
}


void
CameraFrame::OnPipelineReset(wxCommandEvent& event)
{
	ActivityIndicatorGuard guard(this);
	m_thrCamera->CallInCameraThread([this]() {
		m_thrCamera->GetCamera().LogicReset();
	});
}


void
CameraFrame::OnExposure(wxSpinEvent& event)
{
	m_bCameraSettingsChanged = true;
}


void
CameraFrame::OnAutoDepth(wxCommandEvent& event)
{
	m_bCameraSettingsChanged = true;

	ActivityIndicatorGuard guard(this);
	UpdateOnBufferDepthChange();
}


void
CameraFrame::OnBufferDepth(wxCommandEvent& event)
{
	m_bCameraSettingsChanged = true;

	ActivityIndicatorGuard guard(this);
	UpdateOnBufferDepthChange();
}


void
CameraFrame::OnUpdateUIBufferDepth(wxUpdateUIEvent& event)
{
	event.Enable(!m_chkAutoDepth->IsChecked());
}


void
CameraFrame::OnCaptureMode(wxCommandEvent& event)
{
	m_bCameraSettingsChanged = true;
}


void
CameraFrame::UpdateDisplayMode()
{
	m_vpViewPort->SetDisplayMode((okCViewport::DisplayMode)wxPtrToUInt(m_chDisplayMode->GetClientData(m_chDisplayMode->GetCurrentSelection())));
}


void
CameraFrame::UpdateZoomMode()
{
	m_vpViewPort->SetZoomMode(static_cast<okCViewport::ZoomMode>(m_chZoomMode->GetSelection()));
}


void
CameraFrame::OnCaptureSize(wxCommandEvent& event)
{
	m_bCameraSettingsChanged = true;

	ActivityIndicatorGuard guard(this);
	SetupBufferDepthControls();
}


void
CameraFrame::OnDisplayEnable(wxCommandEvent& event)
{
	ActivityIndicatorGuard guard(this);
	m_bDisplayEnable = m_chkDisplayEnable->GetValue();
	if (m_bDisplayEnable) {
		StartContinuous();

		m_thrCamera->CallInCameraThread([this]() {
			m_thrCamera->StartCapture();
		});
		m_txtStatus->SetLabel("Buffered Capture...");
	} else {
		m_thrCamera->CallInCameraThread([this]() {
			m_thrCamera->StopCapture();
		});

		StopContinuous();
	}
}


void
CameraFrame::StartContinuous()
{
	ActivityIndicatorGuard guard(this);
	SetupCamera();

	m_timerFPS->Start(1000);
	m_btnCapture->Disable();

	m_bitmapLED->Show();
}


void
CameraFrame::StopContinuous()
{
	m_bitmapLED->Hide();

	m_timerFPS->Stop();
	if (m_chkDisplayEnable->GetValue())
		m_chkDisplayEnable->SetValue(false);
	m_txtFrameCount->SetLabel("FPS: -");
	m_gaugeCurrentDepth->SetValue(0);
	m_btnCapture->Enable();

	m_panelCameraControls->Layout();
}


void
CameraFrame::OnClose(wxCloseEvent& WXUNUSED(event))
{
	Destroy();
}


std::unique_ptr<OpalKelly::FrontPanel>
CameraFrame::Open(const char* serial)
{
	return std::unique_ptr<OpalKelly::FrontPanel>{m_okManager->Open(serial)};
}


void
CameraFrame::OnDeviceAdded(const char *serial)
{
	m_txtStatus->SetLabel(wxString::Format("Device %s connected", serial));

	std::unique_ptr<OpalKelly::FrontPanel> dev(Open(serial));
	if (dev == NULL) {
		m_txtStatus->SetLabel(wxString::Format("Failed to open %s", serial));
		// There is nothing we can do with this device so don't even add it
		// to m_devices.
		return;
	}

	const auto infoOrError = okCCamera::GetInfo(dev.get());
	if (!infoOrError) {
		// And not much more to be done with a device not recognized as a
		// camera.
		m_txtStatus->SetLabel(
			wxString::Format(
				"Device %s can't be used as a camera\n\n%s",
				serial, infoOrError.error
			)
		);
		m_txtStatus->Wrap(m_txtStatus->GetClientSize().x);
		return;
	}

	// Add a device entry for this device that will be selected at the end of
	// this function.
	CameraDeviceId deviceId{serial};
	m_devices.emplace_back(deviceId, infoOrError.info);

	// Add device entries for the non-default configurations, if any.
	if (!infoOrError.extraConfigs.empty()) {
		int configuration = 0;
		for (const auto& extraConfig: infoOrError.extraConfigs) {
			m_devices.emplace_back(
				CameraDeviceId{serial, configuration++},
				extraConfig
			);
		}

		// Check for the preferred configuration to use for this device.
		long storedConfig;
		if (wxConfig::Get()->Read(GetConfigurationConfigKey(serial), &storedConfig) &&
			 storedConfig >= 0 && storedConfig < configuration) {
			deviceId.configuration = storedConfig;
		} // else: Value is absent or invalid, use the default configuration.
	}

	UpdateDevicesChoice();

	// Use CallAfter() to avoid problems with reentrancy, when
	// OnDeviceRemoved() could be called from inside OnDeviceAdded().
	CallAfter(&CameraFrame::MakeDeviceActiveIfNecessary, deviceId);

	// Ensure we apply the settings to the new camera, even if the UI controls
	// retain the same values they had before, which were used with the old one.
	m_bCameraSettingsChanged = true;
}


void
CameraFrame::OnDeviceRemoved(const char *serial)
{
	// Note that we don't care about the configuration here, we must have this
	// device with the default configuration in our list of devices even if we
	// use a different one and it doesn't matter which element we find, as they
	// all use the same serial.
	const auto n = FindDeviceById(CameraDeviceId{serial, -1});
	if (n == -1) {
		wxLogDebug("Unexpected disconnection for %s which is not connected?");
		return;
	}

	// Has our current camera device been disconnected?
	if (m_currentCamera.serial == serial) {
		Disconnect();
		m_currentCamera.Clear();
		m_chDevice->SetSelection(wxNOT_FOUND);

		m_txtStatus->SetLabel("Camera connection lost");
	} else {
		m_txtStatus->SetLabel(wxString::Format("Device %s disconnected", serial));
	}

	// Erase the device information after calling Disconnect() because it calls
	// SaveCameraSettings() which using the board model from m_devices.
	//
	// Note that there may be more than one element corresponding to this
	// serial for the cameras supporting multiple configurations (but they
	// will all be consecutive because we always add them together).
	auto firstToErase = m_devices.begin() + n;
	auto lastToErase = firstToErase;
	for (++lastToErase; lastToErase != m_devices.end(); ++lastToErase) {
		if (lastToErase->deviceId.serial != serial)
			break;
	}

	m_devices.erase(firstToErase, lastToErase);

	UpdateDevicesChoice();
}


/* static */
wxFileName
CameraFrame::GetBitfilePath(const okCCamera::Info& cameraInfo)
{
	return wxConfig::Get()->Read(GetBitfileConfigKey(cameraInfo));
}


/* static */
void
CameraFrame::ResetBitfilePath(const okCCamera::Info& cameraInfo)
{
	wxConfig::Get()->DeleteEntry(GetBitfileConfigKey(cameraInfo), false);
}


void
CameraFrame::SelectBitfile( const CameraDeviceId& deviceId,
							const okCCamera::Info& cameraInfo,
							const wxFileName& startPath)
{
	const wxString configKey = GetBitfileConfigKey(cameraInfo);
	const wxString wildCard =
		wxString::Format(
			"Bit files (*.bit;*.rbf)|*.bit;*.rbf|All files (%s)|%s",
			wxFileSelectorDefaultWildcardStr,
			wxFileSelectorDefaultWildcardStr
		);

	wxFileDialog dialog(this, _("Choose the bit file"),
						startPath.GetPath(), startPath.GetFullName(),
						wildCard, wxFD_OPEN | wxFD_FILE_MUST_EXIST);

	const int result = dialog.ShowModal();

	const int n = FindDeviceById(deviceId);
	// If the device disconnected - just return.
	if (n == -1) {
		wxLogWarning("Device being configured has been disconnected");
		return;
	}

	const auto& info = m_devices.at(n).cameraInfo;
	if (result == wxID_OK) {
		wxString newPath = dialog.GetPath();

		wxConfig::Get()->Write(configKey, newPath);

		MakeDeviceActive(deviceId);
	} else {
		m_currentCamera.Clear();
		m_chDevice->SetSelection(wxNOT_FOUND);

		m_txtStatus->SetLabel("Camera setup canceled");
	}
}


void
CameraFrame::StartUsingRealm(const okSensitiveString& realm)
{
	try {
		m_btnFPOIP->Disable();

		// Don't replace the current manager because using of the new manager
		// may fail (for example, failed to connect to the FPoIP server). And
		// we want simply keep using the current manager in this case.
		okCFPManagerPtr newManager(new okCFPManager(this, realm.GetPrivateValue()));

		okCFPManager::CallbackInfo callbackInfo;
		// Start monitoring, but the frame will not receive notifications about
		// new devices in CameraFrame::OnDeviceAdded() because okCFPManager
		// defers them (and we don't want them now because the current manager
		// already receives notifications about devices from the current realm).
		// See okCFPManager::StartDeviceProcessing().
		newManager->StartMonitoring(&callbackInfo);

		// We can't capture the unique_ptr<> in C++11 (this requires capture by
		// move), so wrap it in a shared_ptr<> which can be captured by copy.
		auto sharedManager = std::make_shared<okCFPManagerPtr>(std::move(newManager));

		// We need to wait for the current device disconnection if any, so
		// define the lambda function that will setup the manager after
		// disconnection.
		const auto setupManager = [this, realm, callbackInfo, sharedManager]() {
			// Move unique_ptr back out of shared_ptr
			m_okManager = std::move(*sharedManager.get());

#ifdef __LINUX__
			if (callbackInfo.IsUsed())
				m_monitorBridge.reset(new MonitorBridge(callbackInfo));
			else
				m_monitorBridge.reset();
#endif // __LINUX__

			m_usingFPOIP = okCFPOIPInfo::IsFPoIPRealm(realm.GetPrivateValue());

			// Process pending devices and start receiving devices adding and
			// removing notifications.
			m_okManager->StartDeviceProcessing();

			// Update the status and the button label.
			if (m_usingFPOIP) {
				m_txtRealm->SetLabelText(std2wx(realm.GetPublicValue()));
				m_btnFPOIP->SetLabelText(_("Disconnect"));
			} else {
				m_txtRealm->SetLabelText(_("Using local devices"));
				m_btnFPOIP->SetLabelText(_("Connect To FPoIP Server"));
			}

			// Now we can enable the button.
			m_btnFPOIP->Enable();
		};

		// The lambda function that will cleanup the devices info map and
		// the devices choice.
		const auto cleanupCurrentDevices = [this]() {
			if (!m_devices.empty()) {
				m_devices.clear();
				UpdateDevicesChoice();
			}
		};

		// Has connected device?
		if (m_currentCamera.IsValid()) {
			Disconnect();

			// Disconnect() uses the devices map when saving the current camera
			// settings so we can cleanup the map only after disconnecting.
			cleanupCurrentDevices();

			m_currentCamera.Clear();
			m_chDevice->SetSelection(wxNOT_FOUND);

			// Add the action that will be called after the disconnect action.
			m_thrCamera->CallInCameraThread([this, setupManager]() {
				CallAfter([setupManager]() {
					setupManager();
				});
			});
		} else {
			cleanupCurrentDevices();

			// Setup the manager immediately if there are no connected devices.
			setupManager();
		}
	} catch (const std::exception& e) {
		m_btnFPOIP->Enable();

		wxLogError(
			_("Failed to start using realm `%s` with error: %s"),
			realm.GetPublicValue(),
			e.what()
		);
	}
}


void
CameraFrame::MakeDeviceActiveIfNecessary(const CameraDeviceId& deviceId)
{
	// Try to connect if there is no currently connected device.
	if (!m_currentCamera.IsValid()) {
		MakeDeviceActive(deviceId);
	}
}


void
CameraFrame::MakeDeviceActive(const CameraDeviceId& deviceId)
{
	const int n = FindDeviceById(deviceId);
	if (n == -1) {
		wxLogWarning(
			"Device %s was disconnected before it could be selected.",
			deviceId.ToString()
		);
		return;
	}

	m_chDevice->SetSelection(n);

	DoSelectDevice(deviceId);
}


void
CameraFrame::DoSelectDevice(const CameraDeviceId& deviceId)
{
	if (deviceId != m_currentCamera) {
		// Disconnect the previous device if we're connecting another one.
		if (m_currentCamera.IsValid()) {
			Disconnect();
		}
	}

	const int n = FindDeviceById(deviceId);
	if (n == -1) {
		wxLogWarning(
			"Device %s was disconnected before it could be made current.",
			deviceId.ToString()
		);
		return;
	}

	m_currentCamera = deviceId;

	auto const& info = m_devices.at(n).cameraInfo;
	wxFileName path = GetBitfilePath(info);
	if (!path.IsOk()) {
		wxString bitfilesDir;
		if (!wxGetEnv("okCAMERA_BITFILES_DIR", &bitfilesDir)) {
			wxFileName exePath = wxStandardPaths::Get().GetExecutablePath();
			exePath.AppendDir("Bitfiles");
			bitfilesDir = exePath.GetPath();
		}
		path.SetPath(bitfilesDir);
		path.SetFullName(info.bitfileDefaultName);
	}
	// Check for missing bit file.
	if (!path.FileExists()) {
		// Showing modal dialogs while the mouse is captured is not a good
		// idea so use CallAfter().
		CallAfter([this, deviceId, info, path]() {
			SelectBitfile(deviceId, info, path);
		});
		return;
	}

	ActivityIndicatorGuard guard(this);

	// Copy the device ID because we want capture the value, not reference.
	auto deviceIdCopy = deviceId;
	m_thrCamera->CallInCameraThread([this, deviceIdCopy, path]() {
		m_thrCamera->Connect(deviceIdCopy, wx2std(path.GetFullPath()));
	});
}


void
CameraFrame::Disconnect()
{
	m_vpViewPort->ClearImage();

	StopContinuous();

	// Hide controls.
	m_panelCameraControls->Hide();
	m_scrolledSidebar->FitInside();
	Layout();

	// Save the current camera settings.
	SaveCameraSettings();

	// The device we were working with got disconnected, notify the thread
	// about this and abort any current operation.
	m_thrCamera->CallInCameraThread([this]() {
		m_thrCamera->Disconnect();
	});
}


void
CameraFrame::UpdateDevicesChoice()
{
	// Avoid refreshing the control many times and only do it once at the end.
	wxWindowUpdateLocker lock{m_chDevice};

	const wxString selection = m_chDevice->GetStringSelection();

	m_chDevice->Clear();

	for (const auto& device: m_devices) {
		wxString label = std2wx(device.deviceId.serial);

		const auto& configuration = device.cameraInfo.configuration;
		if (!configuration.empty())
			label += wxString::Format(" (%s)", configuration);

		m_chDevice->Append(label);
	}

	// If the previously selected string is still there, make it selected
	// again. Otherwise it means that the selected device was just
	// disconnected, so leave the control without any selection at all.
	m_chDevice->SetStringSelection(selection);
}


void
CameraFrame::ShowActivityIndicator()
{
	if (m_activityCounter == 0) {
		m_timerActivity.reset(new wxTimer());
		m_timerActivity->Bind(wxEVT_TIMER, [this](wxTimerEvent& event) {
			m_animActivityIndicator->Show();
			m_animActivityIndicator->Play();
			m_timerActivity.reset();
		});
		m_timerActivity->Start(ACTIVITY_INDICATOR_DELAY, true /* one shot */);
	}
	++m_activityCounter;
}


void
CameraFrame::HideActivityIndicator()
{
	--m_activityCounter;
	if (m_activityCounter == 0) {
		if (m_timerActivity) {
			m_timerActivity->Stop();
			m_timerActivity.reset();
		}
		m_animActivityIndicator->Hide();
		m_animActivityIndicator->Stop();
	}
}


int
CameraFrame::FindDeviceById(const CameraDeviceId& deviceId) const
{
	// Use simple linear search because we're never going to have more than a
	// few elements in this vector anyhow.
	int n = 0;
	for (const auto& device: m_devices) {
		if (device.deviceId == deviceId)
			return n;

		++n;
	}

	return -1;
}


okCCamera::Info
CameraFrame::GetCurrentCameraInfo() const
{
	const auto n = FindDeviceById(m_currentCamera);
	if (n == -1) {
		throw new std::runtime_error("Failed to get the board model of the current camera");
	}
	return m_devices.at(n).cameraInfo;
}


void
CameraFrame::LoadCameraSettings()
{
	auto const cameraInfo = GetCurrentCameraInfo();
	ReadValueFromConfig(m_spExposure, cameraInfo, CONFIG_EXPOSURE);
	if (ReadValueFromConfig(m_chDisplayMode, cameraInfo, CONFIG_DISPLAY_MODE)) {
		UpdateDisplayMode();
	}
	ReadValueFromConfig(m_chCaptureSize, cameraInfo, CONFIG_CAPTURE_SIZE);
	if (ReadValueFromConfig(m_chZoomMode, cameraInfo, CONFIG_ZOOM_MODE)) {
		UpdateZoomMode();
	}
	ReadValueFromConfig(m_chCapture, cameraInfo, CONFIG_CAPTURE_MODE);
	ReadValueFromConfig(m_chkAutoDepth, cameraInfo, CONFIG_AUTO_DEPTH);
	ReadValueFromConfig(m_slBufferDepth, cameraInfo, CONFIG_BUFFER_DEPTH);
}


void CameraFrame::SaveCameraSettings()
{
	auto const cameraInfo = GetCurrentCameraInfo();
	WriteValueToConfig(m_spExposure, cameraInfo, CONFIG_EXPOSURE);
	WriteValueToConfig(m_chDisplayMode, cameraInfo, CONFIG_DISPLAY_MODE);
	WriteValueToConfig(m_chCaptureSize, cameraInfo, CONFIG_CAPTURE_SIZE);
	WriteValueToConfig(m_chZoomMode, cameraInfo, CONFIG_ZOOM_MODE);
	WriteValueToConfig(m_chCapture, cameraInfo, CONFIG_CAPTURE_MODE);
	WriteValueToConfig(m_chkAutoDepth, cameraInfo, CONFIG_AUTO_DEPTH);
	WriteValueToConfig(m_slBufferDepth, cameraInfo, CONFIG_BUFFER_DEPTH);
}

// Here we setup the window controls.  We try to setup the window in the same
// way as the CamTest FrontPanel example.  Instead of the FrontPanel-specific
// components such as the hex display and the LEDs, we use native widgets that
// are a best-suit.  This makes the code a little shorter so we can concentrate
// on the FrontPanel API.
void
CameraFrame::Initialize()
{
	m_scrolledSidebar = Resources::Find<wxScrolledWindow>(this, "scrolled_sidebar");

	m_animActivityIndicator = Resources::Find<wxGenericAnimationCtrl>(this, "activity_indicator");

	m_bitmapLED = Resources::Find<wxStaticBitmap>(this, "image_led");

	m_txtRealm = Resources::Find<wxStaticText>(this, "text_realm");

	m_btnFPOIP = Resources::Find<wxButton>(this, "btn_fpoip");
	m_btnFPOIP->Bind(wxEVT_BUTTON, &CameraFrame::OnFPOIP, this);

	m_chDevice = Resources::Find<wxChoice>(this, "choice_devices");
	m_chDevice->Bind(wxEVT_CHOICE, &CameraFrame::OnDevice, this);

	m_txtStatus = Resources::Find<wxStaticText>(this, "text_status");

	m_panelCameraControls = Resources::Find<wxPanel>(this, "panel_camera");

	const wxSize bestSize = m_panelCameraControls->GetBestSize();
	const int scrollWidth = wxSystemSettings::GetMetric(wxSYS_VSCROLL_X);
	wxPanel* sidebarContent = Resources::Find<wxPanel>(this, "sidebar_content");
	sidebarContent->SetMinSize(wxSize(bestSize.GetWidth() + scrollWidth, -1));

	m_txtFrameCount = Resources::Find<wxStaticText>(this, "text_fps");
	m_txtMissedCount = Resources::Find<wxStaticText>(this, "text_missed");

	m_btnPipelineReset = Resources::Find<wxButton>(this, "btn_pipeline_reset");
	m_btnPipelineReset->Bind(wxEVT_BUTTON, &CameraFrame::OnPipelineReset, this);

	m_btnCapture = Resources::Find<wxButton>(this, "btn_capture");
	m_btnCapture->Bind(wxEVT_BUTTON, &CameraFrame::OnCapture, this);

	m_chkDisplayEnable = Resources::Find<wxCheckBox>(this, "chk_continuous");
	m_chkDisplayEnable->Bind(wxEVT_CHECKBOX, &CameraFrame::OnDisplayEnable, this);

	m_spExposure = Resources::Find<wxSpinCtrl>(this, "spin_exposure");
	m_spExposure->Bind(wxEVT_SPINCTRL, &CameraFrame::OnExposure, this);

	m_chDisplayMode = Resources::Find<wxChoice>(this, "choice_display_mode");
	SetChoiceClientData(m_chDisplayMode, "Raw Bayer", wxUIntToPtr(okCViewport::RawBayer));
	SetChoiceClientData(m_chDisplayMode, "Nearest", wxUIntToPtr(okCViewport::Nearest));
	SetChoiceClientData(m_chDisplayMode, "Raw Mono", wxUIntToPtr(okCViewport::RawMono));
	m_chDisplayMode->Bind(wxEVT_CHOICE, [this](wxCommandEvent&) {
		UpdateDisplayMode();
	});

	m_chCaptureSize = Resources::Find<wxChoice>(this, "choice_capture_size");
	m_chCaptureSize->Bind(wxEVT_CHOICE, &CameraFrame::OnCaptureSize, this);

	m_chZoomMode = Resources::Find<wxChoice>(this, "choice_zoom_mode");
	SetChoiceClientData(m_chZoomMode, "Fit", wxUIntToPtr(okCViewport::Fit));
	SetChoiceClientData(m_chZoomMode, "Stretch", wxUIntToPtr(okCViewport::Stretch));
	m_chZoomMode->Bind(wxEVT_CHOICE, [this](wxCommandEvent&) {
		UpdateZoomMode();
	});

	m_chCapture = Resources::Find<wxChoice>(this, "choice_capture_mode");
	m_chCapture->Bind(wxEVT_CHOICE, &CameraFrame::OnCaptureMode, this);

	m_chkAutoDepth = Resources::Find<wxCheckBox>(this, "chk_auto_depth");
	m_chkAutoDepth->Bind(wxEVT_CHECKBOX, &CameraFrame::OnAutoDepth, this);

	m_slBufferDepth = Resources::Find<wxSlider>(this, "slider_depth");
	m_slBufferDepth->Bind(wxEVT_SLIDER, &CameraFrame::OnBufferDepth, this);
	m_slBufferDepth->Bind(wxEVT_UPDATE_UI, &CameraFrame::OnUpdateUIBufferDepth, this);

	m_gaugeCurrentDepth = Resources::Find<wxGauge>(this, "gauge_current_depth");
	m_txtCurrentDepthMax = Resources::Find<wxStaticText>(this, "text_current_depth_max");

	m_vpViewPort = Resources::Find<okCViewport>(this, "viewport");

	// Try to restore the previously saved frame geometry: notice that this
	// must be done after loading the frame and the controls because the
	// persistent object uses them.
	bool const sizeSet = wxPersistenceManager::Get().RegisterAndRestore(this);

	if (!sizeSet) {
		int numDisplay = wxDisplay::GetFromWindow(this);
		if (numDisplay == wxNOT_FOUND) {
			// Fall back to the primary one.
			numDisplay = 0;
		}

		// During the first run try to choose a reasonable default size.
		const wxSize sizeScreen = wxDisplay(numDisplay).GetClientArea().GetSize();
		SetClientSize(
			static_cast<int>(sizeScreen.x * 0.8),
			static_cast<int>(sizeScreen.y * 0.6)
		);
	}
}
