//------------------------------------------------------------------------
// okCThreadCamera.h
//
//------------------------------------------------------------------------
// Copyright (c) 2011-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#ifndef __okCThreadCamera_H__
#define __okCThreadCamera_H__

#ifndef WX_PRECOMP
#include "wx/wx.h"
#endif

#include <functional>
#include <memory>

#include <wx/msgqueue.h>

#include "okCameraApp.h"
#include "okCCamera.h"
#include "okFrontPanel.h"


//------------------------------------------------------------------------
// Camera communication thread
//
// The goal is for this thread to completely encapsulate communications
// with the device.  This way, this thing can run in the background
// and feed image data to the main thread.
//
// Note that two threads cannot access the same FrontPanel device
// simultaneously because their communications with the device would
// step on each other -- especially if one is pulling down image data
// continuously.
//------------------------------------------------------------------------
class okCThreadCamera : public wxThread
{
public:
	enum CameraThreadResult {
		SetupGood,			// Successfully associated with the camera.
		SetupFail,			// Failed to associate with the camera.
		CaptureGood,		// Captured a frame correctly.
		CaptureFail,		// Various errors occurring during capture.
		CaptureShort,		//
		CaptureTimeout,		//
		Error				// Some other generic error.
	};

	using Action = std::function<void()>;

	// Create a new control thread, it will post the events to the associated
	// window.
	explicit okCThreadCamera(CameraFrame* frame);

	virtual ~okCThreadCamera();

	// Discard all pending but not yet processed requests.
	void ClearCameraThreadQueue() { m_requests.Clear(); }

	// Stop processing and exit thread.
	void Quit();

	// Post a new request with the action. This function must be called from
	// the main thread, while the given action will be executed in the camera
	// thread. Stop the camera thread if the action is empty.
	void CallInCameraThread(Action&& action);


	// All the functions below (finishing with GetImageData()) can only be
	// called from the camera thread, i.e. from inside an action passed to
	// PostRequest().

	// Set the the camera size by providing the skips value.
	void SetupSizeBySkips(int skips);
	// Associate with the camera device.
	void Connect(const CameraDeviceId& deviceId, const std::string& bitfile);
	// Disconnect from the current device.
	void Disconnect();
	// Capture a single frame.
	void SingleCapture();
	// Start continuously capturing frames.
	void StartCapture();
	// Stop continuously capturing frames.
	void StopCapture();

	// Get the camera we're currently working with. Throws if the camera is not
	// currently open.
	okCCamera& GetCamera() const;

	// Get the pointer to the image data. This is actually not MT-safe as the
	// buffer could be modified by this thread even while it's being read by
	// the main one, but in practice this doesn't do much harm (we can get
	// images which mix parts of 2 frames) and allows us to avoid creating big
	// temporary buffers for each frame or using extra locks.
	const unsigned char* GetImageData() const { return m_u8Image; }

protected:
	// The thread entry point.
	virtual ExitCode Entry();

	// Helper creating a new (heap-allocated) event carrying the specified
	// notification.
	wxThreadEvent* NewEvent(CameraThreadResult result) const;

	// Post an error event to the main thread.
	void PostError(const wxString& error);

	// Convert okCCamera error code to our result.
	static CameraThreadResult GetResultFromErrorCode(okCCamera::ErrorCode code);

	// Throws if the current thread is not the camera thread.
	void CheckCalledInCameraThread() const;

	void DoSingleCapture();
	void DoBufferedCapture();

private:
	// The frame to send our notifications to and also to use as FrontPanel
	// device manager.
	CameraFrame* const m_win;

	// Queue used for communications from the main thread.
	wxMessageQueue<Action> m_requests;

	// Buffer used for the raw camera data.
	unsigned char *m_u8Image;

	// The device ID of the current camera or invalid if none.
	CameraDeviceId m_currentCamera;

	// The camera we're working with or NULL if no camera is currently
	// connected.
	std::unique_ptr<okCCamera> m_cam;

	bool m_captureContinuously = false;


	wxDECLARE_NO_COPY_CLASS(okCThreadCamera);
};


#endif // __okCThreadCamera_H__
