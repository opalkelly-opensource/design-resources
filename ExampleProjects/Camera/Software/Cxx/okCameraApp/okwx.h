//------------------------------------------------------------------------
// okCBitmapListDecoder.h
//
//------------------------------------------------------------------------
// Copyright (c) 2020 Opal Kelly Incorporated
//------------------------------------------------------------------------

#ifndef __okwx_h__
#define __okwx_h__

#include <wx/string.h>

#include <string>

// These conversion functions are required for compatibility with wx 3.0, which doesn't
// provide conversion argument in ToStdString() and FromUTF8() overload taking std::string.
// When we can require wx 3.2 or later, they could be dropped and replaced with wx methods.
inline std::string wx2std(const wxString& s)
{
	const wxScopedCharBuffer& buf = s.utf8_str();
	return std::string(buf.data(), buf.length());
}


inline wxString std2wx(const std::string& s)
{
	return wxString::FromUTF8(s.c_str(), s.length());
}


#endif // __okwx_h__
