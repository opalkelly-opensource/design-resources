//------------------------------------------------------------------------
// okCThreadCamera.cpp
//
// This class performs all communication with the EVB100x camera via the
// FrontPanel API.  Communication is threaded separately to improve
// application stability and responsiveness as well as enforcing a single
// point of contact with the FrontPanel API.
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#include "wx/wxprec.h"

#include <memory> // unique_ptr

#include <wx/stopwatch.h>

#include "okCameraApp.h"
#include "okCThreadCamera.h"
#include "okCCamera.h"
#include "okFrontPanel.h"
#include "okwx.h"


okCThreadCamera::okCThreadCamera(CameraFrame* win) :
	wxThread(wxTHREAD_JOINABLE),
	m_win(win)
{
	Create();

	// This is sort of a hack to set a fixed image size.  We should really allocate
	// this any time we change the x/y skips and use okCCamera::GetFrameBufferSize.
	// Use the largest image size of any of the supported sensors (currently
	// MT9P031 and AR0330) to avoid having to reallocate the buffer later.
	m_u8Image = new unsigned char [2592*1944*2 + 1024];

	Run();
}

okCThreadCamera::~okCThreadCamera()
{
	delete [] m_u8Image;
}


void
okCThreadCamera::Quit()
{
	if (!IsMain()) {
		throw new std::runtime_error("Quit() must be called from the main thread.");
	}
	CallInCameraThread(Action());
}


void
okCThreadCamera::CallInCameraThread(Action&& action)
{
	if (!IsMain()) {
		throw new std::runtime_error("Requests must be posted from the main thread.");
	}
	m_requests.Post(std::move(action));
}


void
okCThreadCamera::SetupSizeBySkips(int skips)
{
	CheckCalledInCameraThread();
	const auto defaultSize = m_cam->GetDefaultSize();
	m_cam->SetSize(defaultSize.m_width, defaultSize.m_height);
	m_cam->SetSkips(skips, skips);
}


void
okCThreadCamera::Disconnect()
{
	CheckCalledInCameraThread();
	m_captureContinuously = false;
	m_cam.reset();
}


void
okCThreadCamera::SingleCapture()
{
	CheckCalledInCameraThread();
	DoSingleCapture();
}


void
okCThreadCamera::StartCapture()
{
	CheckCalledInCameraThread();
	m_captureContinuously = true;
	m_cam->EnablePingPong(true);
	DoBufferedCapture();
}


void
okCThreadCamera::StopCapture()
{
	CheckCalledInCameraThread();
	m_captureContinuously = false;
	GetCamera().EnablePingPong(false);
}


okCCamera&
okCThreadCamera::GetCamera() const
{
	CheckCalledInCameraThread();
	if (!m_cam.get()) {
		throw new std::runtime_error("No camera");
	}
	return *m_cam;
}


wxThreadEvent*
okCThreadCamera::NewEvent(CameraThreadResult result) const
{
	wxThreadEvent* const evt = new wxThreadEvent;
	evt->SetInt(result);
	evt->SetPayload(m_currentCamera);
	return evt;
}


void
okCThreadCamera::PostError(const wxString& error)
{
	wxThreadEvent* const evt = NewEvent(Error);
	evt->SetString(error);
	wxQueueEvent(m_win, evt);
}


void
okCThreadCamera::Connect(const CameraDeviceId& deviceId, const std::string& bitfile)
{
	CheckCalledInCameraThread();
	CameraThreadResult res;
	okCCamera::ErrorCode initRes = okCCamera::NoError;
	std::string msg;
	wxStopWatch sw;
	std::unique_ptr<OpalKelly::FrontPanel> dev(m_win->Open(deviceId.serial.c_str()));
	if (dev == NULL) {
		initRes = okCCamera::Failed;
		msg = "Failed to open the camera device";
	} else {
		m_cam.reset(new okCCamera);
		initRes = m_cam->Initialize(msg, dev.release(), bitfile, deviceId.configuration);
	}
	switch (initRes) {
		case okCCamera::NoError:
			res = SetupGood;
			wxLogStatus(m_win, "Camera initialized in %ldms", sw.Time());
			m_currentCamera = deviceId;
			break;

		default:
			res = SetupFail;

			// No need to keep the device if we failed to initialize it.
			m_cam.reset();
			m_currentCamera.Clear();
	}

	if (!msg.empty()) {
		wxLogWarning("%s", msg);
	}

	wxQueueEvent(m_win, NewEvent(res));
}


/* static */
okCThreadCamera::CameraThreadResult
okCThreadCamera::GetResultFromErrorCode(okCCamera::ErrorCode code)
{
	switch (code) {
		case okCCamera::NoError:
			return CaptureGood;
		case okCCamera::ImageReadoutShort:
			return CaptureShort;
		case okCCamera::Timeout:
			return CaptureTimeout;
		default:
			return CaptureFail;
	}
}


void
okCThreadCamera::CheckCalledInCameraThread() const
{
	if (wxThread::GetCurrentId() != GetId()) {
		throw new std::runtime_error("Camera functions must be called in the camera thread.");
	}
}

void
okCThreadCamera::DoSingleCapture()
{
	wxStopWatch sw;
	okCCamera::ErrorCode code = m_cam->SingleCapture(m_u8Image);
	if (code == okCCamera::NoError) {
		// Millisecond resolution seems to be enough for now, but if we ever
		// make this much faster, TimeInMicro() could be used too.
		wxLogStatus(m_win, "Single image captured in %ldms", sw.Time());
	}

	wxQueueEvent(m_win, NewEvent(GetResultFromErrorCode(code)));
}


void
okCThreadCamera::DoBufferedCapture()
{
	okCCamera::ErrorCode code = m_cam->BufferedCapture(m_u8Image);

	wxThreadEvent* const evt = NewEvent(GetResultFromErrorCode(code));

	if (code == okCCamera::NoError) {
		// Pass the number of missed frames in the event too.
		evt->SetExtraLong(m_cam->m_dev->GetWireOutValue(0x23) & 0xff);
	}

	wxQueueEvent(m_win, evt);
}



wxThread::ExitCode
okCThreadCamera::Entry()
{
	// Loop waiting for requests from the main thread.
	for (;;) {
		Action action;
		wxMessageQueueError rc;
		if (m_captureContinuously) {
			// Check for new requests but don't block.
			rc = m_requests.ReceiveTimeout(0, action);
		} else {
			// Block until we're asked to do something.
			rc = m_requests.Receive(action);
		}

		switch (rc) {
			case wxMSGQUEUE_NO_ERROR:
				try {
					// If no action is specified, it's a special case
					// indicating that we should exit.
					if (!action) {
						m_cam.reset();
						return 0;
					}
					action();
				}
				catch (const std::exception& e) {
					PostError(e.what());
				}
				break;

			case wxMSGQUEUE_TIMEOUT:
				// This can only happen when continuously capturing, so just
				// keep doing this.
				DoBufferedCapture();
				break;

			case wxMSGQUEUE_MISC_ERROR:
				PostError("Failed to read message");
				break;
		}
	}
}
