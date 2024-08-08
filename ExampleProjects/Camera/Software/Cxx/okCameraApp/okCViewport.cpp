//------------------------------------------------------------------------
// okCViewport.cpp
//
// This class is derived from the wxWidgets wxControl class and creates
// a bitmap display control for rendering a raw image capture.
//
//------------------------------------------------------------------------
// Copyright (c) 2004-2012 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

#include "wx/wxprec.h"
#include <wx/dcclient.h>

#include "okCViewport.h"

wxObject* okCXmlViewportHandler::DoCreateResource()
{
	okCViewport* viewport = new okCViewport(m_parentAsWindow, GetID());
	if (HasParam("initialsize")) {
		viewport->SetInitialSize(GetSize("initialsize"));
	}
	return viewport;
}

bool okCXmlViewportHandler::CanHandle(wxXmlNode *node)
{
	return IsOfClass(node, "okCViewport");
}


BEGIN_EVENT_TABLE(okCViewport, wxGLCanvas)
	EVT_PAINT(okCViewport::OnPaint)
	EVT_SIZE(okCViewport::OnSize)
END_EVENT_TABLE()


okCViewport::okCViewport(wxWindow *parent, wxWindowID id)
	: wxGLCanvas(parent, id, NULL, wxDefaultPosition, wxDefaultSize, wxBORDER_NONE)
{
	SetBackgroundStyle(wxBG_STYLE_PAINT);

	m_zoomMode = Fit;
	m_eDisplayMode = Nearest;
	m_pImageData = NULL;
	m_pRGBData = NULL;
	m_texture = 0;

	m_u32ImageX =
	m_u32ImageY =
	m_u32BPP = 0;

	m_buildRGB = false;

	m_glContext = new wxGLContext(this);
}

okCViewport::~okCViewport()
{
	if (m_texture) {
		SetCurrent(*m_glContext);
		glDeleteTextures(1, &m_texture);
	}

	delete m_glContext;

	delete [] m_pRGBData;
	delete [] m_pImageData;
}



void
okCViewport::AllocTexture()
{
	// Ensure that we have a buffer of the correct size.
	delete [] m_pRGBData;
	m_pRGBData = new unsigned char[m_u32ImageX*m_u32ImageY*3];   // 3 = RGB


	// Also (re)allocate the texture.
	SetCurrent(*m_glContext);

	if (m_texture)
		glDeleteTextures(1, &m_texture);
	else // Once-only initialization.
		glEnable(GL_TEXTURE_2D);

	glGenTextures(1, &m_texture);
	glBindTexture(GL_TEXTURE_2D, m_texture);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	glTexImage2D(GL_TEXTURE_2D, 0,
			GL_RGB, m_u32ImageX, m_u32ImageY, 0,
			GL_RGB, GL_UNSIGNED_BYTE, m_pRGBData);

	glBindTexture(GL_TEXTURE_2D, 0);
}


void
okCViewport::SetZoomMode(ZoomMode zoomMode)
{
	m_zoomMode = zoomMode;

	UpdateViewport(GetClientSize());

	Refresh();
}


void
okCViewport::SetDisplayMode(DisplayMode eMode)
{
	m_eDisplayMode = eMode;
	this->Refresh();
}



void
okCViewport::SetImageFormat(unsigned long u32X, unsigned long u32Y, unsigned long u32BPP)
{
	if (u32X != m_u32ImageX || u32Y != m_u32ImageY || u32BPP != m_u32BPP) {
		m_u32ImageX = u32X;
		m_u32ImageY = u32Y;
		m_u32BPP = u32BPP;

		// Reallocate the buffer to fit the new image size.
		delete [] m_pImageData;
		m_pImageData = new unsigned char[u32X*u32Y*u32BPP];

		AllocTexture();

		UpdateViewport(GetClientSize());
	}
}

void
okCViewport::UpdateImage(const unsigned char* u8Image)
{
	memcpy(m_pImageData, u8Image, m_u32ImageX * m_u32ImageY * m_u32BPP);

	m_buildRGB = true;

	this->Refresh();
}


void
okCViewport::ClearImage()
{
	memset(m_pImageData, 0, m_u32ImageX * m_u32ImageY * m_u32BPP);

	m_buildRGB = true;

	this->Refresh();
}


// Proposed viewport settings...
// - Mode: Bayer pixel / Color pixels
// - bpp: 8 / 16
// - Color mode: nearest pixels / interpolation
void
okCViewport::BuildImage()
{
	unsigned char r, g, b;

	// 8-bits per pixel from the camera
	if (1 == m_u32BPP) {
		switch (m_eDisplayMode) {
		case okCViewport::RawBayer:
			{
				unsigned char* p = m_pRGBData;
				for (unsigned y=0; y<m_u32ImageY; y++) {
					for (unsigned x=0; x<m_u32ImageX; x++) {
						// Use exact pixels as Bayer pattern
						if ((x%2 == 1) && (y%2 == 0)) {  // Red
							r = m_pImageData[x + y*m_u32ImageX];
							g = 0;
							b = 0;
						} else if ((x%2 == 0) && (y%2 == 1)) { // Blue
							r = 0;
							g = 0;
							b = m_pImageData[x + y*m_u32ImageX];
						} else {                               // Green
							r = 0;
							g = m_pImageData[x + y*m_u32ImageX] * 0.75;
							b = 0;
						}

						*p++ = r;
						*p++ = g;
						*p++ = b;
					}
				}
			}
			break;

		case okCViewport::RawMono:
			{
				unsigned char* p = m_pRGBData;
				for (unsigned y=0; y<m_u32ImageY; y++) {
					for (unsigned x=0; x<m_u32ImageX; x++) {
						r = m_pImageData[x + y*m_u32ImageX];
						g = m_pImageData[x + y*m_u32ImageX];
						b = m_pImageData[x + y*m_u32ImageX];

						*p++ = r;
						*p++ = g;
						*p++ = b;
					}
				}
			}
			break;

		case okCViewport::Nearest:
			switch (m_bayerFilter) {
			case okCCamera::BayerFilter::GRBG:
				{
					// Process pixels by 2*2 squares with the red and blue colour
					// components of all pixels in the same square being the same and
					// the green component being the colour of the raw green pixel in
					// the same row, i.e.
					//
					//	+---+---+       +---+---+
					//	+ g + r +       + c + c +
					//	+---+---+ ----> +---+---+
					//	+ b + h +       + d + d +
					//	+---+---+       +---+---+
					//
					// where c=RGB(r,g,b) and d=RGB(r,h,b)

					unsigned char const* srcThisRow = m_pImageData;
					unsigned char* dstThisRow = m_pRGBData;

					unsigned char h;

					// We suppose that the image size is even in both directions for
					// simplicity, this is always the case in our use.
					for (unsigned y=0; y<m_u32ImageY/2; y++) {
						unsigned char const* srcNextRow = srcThisRow + m_u32ImageX;
						unsigned char* dstNextRow = dstThisRow + 3*m_u32ImageX;

						for (unsigned x=0; x<m_u32ImageX/2; x++) {

							g = *srcThisRow++;
							r = *srcThisRow++;
							b = *srcNextRow++;
							h = *srcNextRow++;

							*dstThisRow++ = r;
							*dstThisRow++ = g;
							*dstThisRow++ = b;

							*dstThisRow++ = r;
							*dstThisRow++ = g;
							*dstThisRow++ = b;

							*dstNextRow++ = r;
							*dstNextRow++ = h;
							*dstNextRow++ = b;

							*dstNextRow++ = r;
							*dstNextRow++ = h;
							*dstNextRow++ = b;
						}

						// Skip the already processed rows.
						srcThisRow = srcNextRow;
						dstThisRow = dstNextRow;
					}
				}
				break;

			case okCCamera::BayerFilter::BGGR:
				{
					// Process pixels by 2*2 squares with the red and blue colour
					// components of all pixels in the same square being the same and
					// the green component being the colour of the raw green pixel in
					// the same row, i.e.
					//
					//	+---+---+       +---+---+
					//	+ b + g +       + c + c +
					//	+---+---+ ----> +---+---+
					//	+ h + r +       + d + d +
					//	+---+---+       +---+---+
					//
					// Here h = g
					//
					// where c=RGB(r,g,b) and d=RGB(r,h,b)

					unsigned char const* srcThisRow = m_pImageData;
					unsigned char* dstThisRow = m_pRGBData;

					unsigned char h;

					// We suppose that the image size is even in both directions for
					// simplicity, this is always the case in our use.
					for (unsigned y = 0; y < m_u32ImageY / 2; y++) {
						unsigned char const* srcNextRow = srcThisRow + m_u32ImageX;
						unsigned char* dstNextRow = dstThisRow + 3 * m_u32ImageX;

						for (unsigned x = 0; x < m_u32ImageX / 2; x++) {

							b = *srcThisRow++;
							g = *srcThisRow++;
							h = *srcNextRow++;
							r = *srcNextRow++;


							*dstThisRow++ = r;
							*dstThisRow++ = g;
							*dstThisRow++ = b;

							*dstThisRow++ = r;
							*dstThisRow++ = g;
							*dstThisRow++ = b;

							*dstNextRow++ = r;
							*dstNextRow++ = h;
							*dstNextRow++ = b;

							*dstNextRow++ = r;
							*dstNextRow++ = h;
							*dstNextRow++ = b;
						}

						// Skip the already processed rows.
						srcThisRow = srcNextRow;
						dstThisRow = dstNextRow;
					}
				}
				break;
			}
			break;
		}



	}

	// 16-bits per pixel from the camera
	else if (2 == m_u32BPP) {
		unsigned char* p = m_pRGBData;
		for (unsigned y=0; y<m_u32ImageY; y++) {
			for (unsigned x=0; x<m_u32ImageX; x++, p++) {
				if (1) {
					unsigned long pix = m_u32BPP * (2*x + m_u32ImageX*2*y);
					r = (m_pImageData[pix+3]<<4)               | (m_pImageData[pix+2]>>4);                // Red
					g = (m_pImageData[pix+1]<<4)               | (m_pImageData[pix  ]>>4);                // Green
					b = (m_pImageData[pix+1+m_u32BPP*m_u32ImageX]<<4)   | (m_pImageData[pix+m_u32BPP*m_u32ImageX]>>4);      // Blue
				} else {
					unsigned long pix = 2 * (2*(x)+1 + m_u32ImageX*(2*(y)+1));              // Center green
					double v1 = (m_pImageData[pix-5184+1]<<4) | (m_pImageData[pix-5184]>>4);  // Red-top
					double v2 = (m_pImageData[pix+5184+1]<<4) | (m_pImageData[pix+5184]>>4);  // Red-bottom
					r = (unsigned char) ((v1 + v2)/2.0);

					g = (m_pImageData[pix+1]<<4) | (m_pImageData[pix]>>4);

					v1 = (m_pImageData[pix+2+1]<<4) | (m_pImageData[pix+2]>>4);        // Blue-left
					v2 = (m_pImageData[pix-2+1]<<4) | (m_pImageData[pix-2]>>4);        // Blue-right
					b = (unsigned char) ((v1 + v2)/2.0);
				}
				*p++ = r;
				*p++ = g;
				*p++ = b;
			}
		}
	}
}



void
okCViewport::UpdateViewport(const wxSize& sizeLogical)
{
	// Physical size may be different when pixel scaling is used.
	const wxSize size = sizeLogical * GetContentScaleFactor();

	glViewport(0, 0, size.x, size.y);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	// Center the unit square in the middle of the view port if requested.
	GLdouble xofs,
			 yofs;
	if (m_zoomMode == Fit && m_u32ImageX && m_u32ImageY) {
		xofs = (((GLdouble)size.x / m_u32ImageX) - 1.)/2.;
		yofs = (((GLdouble)size.y / m_u32ImageY) - 1.)/2.;
	}
	else {
		if (m_u32ImageX && m_u32ImageY) {
			// Fit image to the screen preserving the image aspect ratio.
			const auto screenRatio = static_cast<GLdouble>(size.x) / size.y;
			const auto imageRatio = static_cast<GLdouble>(m_u32ImageX) / m_u32ImageY;
			if (screenRatio < imageRatio) {
				xofs = 0.;
				yofs = (imageRatio / screenRatio - 1.) / 2.;
			} else {
				yofs = 0.;
				xofs = (screenRatio / imageRatio - 1.) / 2.;
			}
		} else {
			xofs =
			yofs = 0.;
		}
	}

	glOrtho(-xofs, 1. + xofs, -yofs, 1. + yofs, -1, 1);
}

void
okCViewport::OnSize(wxSizeEvent& event)
{
	if (IsShownOnScreen()) {
		SetCurrent(*m_glContext);

		UpdateViewport(event.GetSize());

		Refresh();
	}

	event.Skip();
}


void
okCViewport::OnPaint(wxPaintEvent &evt)
{
	wxPaintDC dc(this);

	SetCurrent(*m_glContext);

	// Always clear the background. If there is no texture we still must paint
	// the window with something. And if the texture is set we must clear the
	// buffer to overwrite the previously painted image (which could be bigger
	// than this one).
	glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);

	if (m_texture) {
		glBindTexture(GL_TEXTURE_2D, m_texture);

		// Update the texture if necessary.
		if (m_buildRGB) {
			m_buildRGB = false;
			BuildImage();

			glTexSubImage2D(GL_TEXTURE_2D, 0,
					0, 0, m_u32ImageX, m_u32ImageY,
					GL_RGB, GL_UNSIGNED_BYTE, m_pRGBData);
		}

		// Actually drawing is trivial as we just need to send the coordinates of
		// the 4 vertices and the corresponding texture coordinates to OpenGL.
		//
		// Notice that the vertical texture coordinates are flipped relatively to
		// the OpenGL ones, i.e. we exchange 0 and 1, as the y axis direction are
		// different for them. We could avoid this by exchanging the order of "top"
		// and "bottom" parameters in glOrtho() call above, but this seems more
		// explicit and hence preferable.
		glBegin(GL_QUADS);
			glTexCoord2f(0, 1);
			glVertex2f(0, 0);

			glTexCoord2f(0, 0);
			glVertex2f(0, 1);

			glTexCoord2f(1, 0);
			glVertex2f(1, 1);

			glTexCoord2f(1, 1);
			glVertex2f(1, 0);
		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
	}


	SwapBuffers();
}
