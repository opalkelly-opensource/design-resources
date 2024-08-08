//------------------------------------------------------------------------
// okCBitmapListDecoder.h
//
//------------------------------------------------------------------------
// Copyright (c) 2020 Opal Kelly Incorporated
//------------------------------------------------------------------------

#ifndef __okCBitmapListDecoder_h__
#define __okCBitmapListDecoder_h__

#include <wx/animate.h>

#include <vector>

/**
	The animation decoder from the simple text file which contains the list
	of names of wxBitmap resources.

	The file format:
BITMAPLIST
The comments line.
delayValueinMs(int)
framesCount(int)
frameResourceName[0]
frameResourceName[1]
...
frameResourceName[framesCount-1]
EOF

	Example:
BITMAPLIST
An example of an animation list file:
20
2
frame1
frame2
*/
class okCBitmapListDecoder : public wxAnimationDecoder
{
public:
	okCBitmapListDecoder() = default;

	bool Load(wxInputStream& stream) override;
	wxAnimationDecoder* Clone() const override;
	wxAnimationType GetType() const override;

	// Convert given frame to wxImage.
	bool ConvertToImage(unsigned int frame, wxImage *image) const override;

	// Frame specific data getters.

	// Not all frames may be of the same size; e.g. GIF allows to
	// specify that between two frames only a smaller portion of the
	// entire animation has changed.
	wxSize GetFrameSize(unsigned int frame) const override;

	// The position of this frame in case it's not as big as m_szAnimation
	// or wxPoint(0,0) otherwise.
	wxPoint GetFramePosition(unsigned int frame) const override;

	// What should be done after displaying this frame.
	wxAnimationDisposal GetDisposalMethod(unsigned int frame) const override;

	// The number of milliseconds this frame should be displayed.
	// if returns -1 then the frame must be displayed forever.
	long GetDelay(unsigned int WXUNUSED(frame)) const override;

	// The transparent colour for this frame if any or wxNullColour.
	wxColour GetTransparentColour(unsigned int frame) const override;

protected:
	// Checks the signature of the data in the given stream and returns true if it
	// appears to be a valid animation format recognized by the animation decoder;
	// this function should modify the stream current position without taking care
	// of restoring it since CanRead() will do it.
	bool DoCanRead(wxInputStream& stream) const override;

private:
	// The delay between frames.
	int m_delay = 0;
	// The vector of images.
	std::vector<wxImage> m_images;
};

#endif // __okCBitmapListDecoder_h__
