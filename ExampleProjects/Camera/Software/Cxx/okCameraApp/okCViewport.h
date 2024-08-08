//------------------------------------------------------------------------
// okCViewport.h
//
//------------------------------------------------------------------------
// Copyright (c) 2004-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#ifndef __okCViewport_h__
#define __okCViewport_h__

#include "wx/glcanvas.h"
#include <wx/xrc/xmlreshandler.h>

#include "okCCamera.h"

class okCXmlViewportHandler : public wxXmlResourceHandler
{
public:
	okCXmlViewportHandler() = default;
	wxObject* DoCreateResource() override;
	bool CanHandle(wxXmlNode *node) override;
};

class okCViewport : public wxGLCanvas
{
public:
	enum ZoomMode { Fit=0, Stretch=1 };
	enum DisplayMode { RawBayer=0, Nearest=1, RawMono=2 };

	okCViewport(wxWindow *parent, wxWindowID id);
	~okCViewport();

	// Set the zoom mode when the window is bigger than the image shown in it:
	// we may either show the image at its native resolution in the middle of
	// the window or stretch it to cover all the available area.
	void SetZoomMode(ZoomMode zoomMode);

	// Set the algorithm to use for converting raw image data to RGB data shown
	// on screen. "Nearest" is the default.
	void SetDisplayMode(DisplayMode eMode);

	// Set the Bayer filter used in "Nearest" display mode.
	//
	// Unlike the other methods, this one doesn't refresh the window, as it's
	// supposed to be called only once when a new camera is connected.
	void SetBayerFilter(okCCamera::BayerFilter bayerFilter) {
		m_bayerFilter = bayerFilter;
	}

	// Set the size and format of the raw image. This must be called before
	// calling UpdateImage().
	void SetImageFormat(unsigned long u32X, unsigned long u32Y, unsigned long u32BPP);

	// Update the currently shown image.
	void UpdateImage(const unsigned char* u8Image);

	// Clear the currently shown image.
	void ClearImage();

private:
	void OnPaint(wxPaintEvent &evt);
	void OnSize(wxSizeEvent& event);

	// Allocate RGB buffer using the current image size (i.e. m_u32Image[XY])
	// and create OpenGL texture associated with it.
	//
	// Can be called multiple times in case the image size changes.
	void AllocTexture();

	// Update OpenGL view port size, must be called when the window size changes.
	//
	// Notice that the context must be set as current by the caller.
	void UpdateViewport(const wxSize& size);

	// Update m_pRGBData from m_pImageData.
	void BuildImage();


	ZoomMode m_zoomMode;

	DisplayMode     m_eDisplayMode;

	okCCamera::BayerFilter m_bayerFilter = okCCamera::BayerFilter::GRBG;

	// A buffer of size m_u32ImageX*m_u32ImageY*m_u32BPP containing the raw
	// camera data.
	unsigned char  *m_pImageData;

	// A buffer of size m_u32ImageX*m_u32ImageY*3 containing RGB data for each
	// pixel.
	unsigned char  *m_pRGBData;

	// Width and height of the image data and its format in bytes (not bits)
	// per pixel.
	unsigned long  	m_u32ImageX, m_u32ImageY, m_u32BPP;

	// OpenGL stuff: the context itself and texture ID.
	wxGLContext* m_glContext;
	GLuint m_texture;

	// If true, we need to rebuild m_pRGBData from m_pImageData.
	bool m_buildRGB;


	DECLARE_EVENT_TABLE()
};

#endif // __okCViewport_h__
