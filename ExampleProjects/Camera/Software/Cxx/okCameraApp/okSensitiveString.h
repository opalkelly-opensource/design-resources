//------------------------------------------------------------------------
// SensitiveString.h
//
// Helper class representing strings containing sensitive information.
//
//------------------------------------------------------------------------
// Copyright (c) 2020 Opal Kelly Incorporated
//------------------------------------------------------------------------

#ifndef OpalKelly_SensitiveString_h_guard_
#define OpalKelly_SensitiveString_h_guard_

#include <string>

class okSensitiveString
{
public:
	/**
		Constructor takes the string and, optionally, a range to mask in it.

		The range is specified, as usual, by begin/end pair with the latter
		position being one after the end of the sensitive part.
	*/
	explicit okSensitiveString(
			std::string value,
			std::size_t secretBegin = std::string::npos,
			std::size_t secretEnd = std::string::npos
		) :
		m_value(std::move(value)),
		m_secretBegin(secretBegin),
		m_secretEnd(secretEnd)
	{
	}

	// This class is trivially copyable and movable, but not assignable.
	okSensitiveString(const okSensitiveString&) = default;
	okSensitiveString(okSensitiveString&&) = default;
	okSensitiveString& operator=(const okSensitiveString&) = delete;
	okSensitiveString& operator=(okSensitiveString&&) = delete;

	~okSensitiveString() = default;

	/**
		Returns the full string, including the sensitive part, if any.

		This string should not be displayed, stored in log files etc.
	*/
	const std::string& GetPrivateValue() const { return m_value; }

	/**
		Returns the string with the sensitive part redacted.

		If there is no secret part, this is the same as GetPrivateValue().
	*/
	std::string GetPublicValue() const
	{
		if (m_secretBegin == std::string::npos)
			return GetPrivateValue();

		constexpr const char* SECRET_REPLACEMENT = "********";

		return m_value.substr(0, m_secretBegin)
			+ SECRET_REPLACEMENT
			+ m_value.substr(m_secretEnd);
	}

private:
	const std::string m_value;
	const std::size_t m_secretBegin, m_secretEnd;
};

#endif // OpalKelly_SensitiveString_h_guard_
