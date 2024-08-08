//------------------------------------------------------------------------
// okCBitmapListDecoder.cpp
//
//------------------------------------------------------------------------
// Copyright (c) 2020 Opal Kelly Incorporated
//------------------------------------------------------------------------

#include <wx/wxprec.h>

#include <wx/txtstrm.h>

#include "okCBitmapListDecoder.h"
#include "okResources.h"

#define BITMAPLIST_HEADER "BITMAPLIST"


bool
okCBitmapListDecoder::Load(wxInputStream& stream)
{
	wxTextInputStream txt(stream);

	// Read the header.
	wxString header = txt.ReadLine();
	if (header != BITMAPLIST_HEADER) {
		throw new Resources::Exception("Invalid header line.");
	}

	// Read the comments line.
	wxString comments = txt.ReadLine();

	// Read the delay.
	txt >> m_delay;
	if (m_delay <= 0) {
		throw new Resources::Exception(
			"The delay value in the bitmap list should be positive."
		);
	}

	// Read the number of frames.
	txt >> m_nFrames;
	if (m_nFrames <= 0) {
		throw new Resources::Exception(
			"The frames count in the bitmap list should be positive."
		);
	}

	m_images.resize(m_nFrames);
	for (unsigned int i = 0; i < m_nFrames; ++i) {
		// Read the bitmap resouce name.
		wxString name = txt.ReadLine();
		if (name.empty()) {
			throw new Resources::Exception(
				wxString::Format("Failed to read image name for %d frame.", i)
			);
		}

		m_images[i] = Resources::Get().LoadBitmap(name).ConvertToImage();
	}

	wxString lastLine = txt.ReadLine();
	if (!lastLine.empty() || !stream.Eof()) {
		throw new Resources::Exception(
			"The bitmap list contains extra lines."
		);
	}

	m_szAnimation.x = m_images.front().GetWidth();
	m_szAnimation.y = m_images.front().GetHeight();
	m_background = wxNullColour;

	return true;
}


wxAnimationDecoder*
okCBitmapListDecoder::Clone() const
{
	return new okCBitmapListDecoder();
}


wxAnimationType
okCBitmapListDecoder::GetType() const
{
	return static_cast<wxAnimationType>(wxANIMATION_TYPE_ANY + 1);
}


bool
okCBitmapListDecoder::ConvertToImage(unsigned int frame, wxImage *image) const
{
	*image = m_images.at(frame);
	return true;
}


wxSize
okCBitmapListDecoder::GetFrameSize(unsigned int frame) const
{
	return GetAnimationSize();
}


wxPoint
okCBitmapListDecoder::GetFramePosition(unsigned int frame) const
{
	return wxPoint();
}


wxAnimationDisposal
okCBitmapListDecoder::GetDisposalMethod(unsigned int frame) const
{
	return wxANIM_TOBACKGROUND;
}


long
okCBitmapListDecoder::GetDelay(unsigned int WXUNUSED(frame)) const
{
	return m_delay;
}


wxColour
okCBitmapListDecoder::GetTransparentColour(unsigned int frame) const
{
	return wxNullColour;
}


bool okCBitmapListDecoder::DoCanRead(wxInputStream& stream) const
{
	unsigned char buf[sizeof(BITMAPLIST_HEADER)];

	// The size without last \0 char.
	const int charsCount = sizeof(BITMAPLIST_HEADER) - 1;
	if (!stream.Read(buf, charsCount))
		return false;

	return memcmp(buf, BITMAPLIST_HEADER, charsCount) == 0;
}
