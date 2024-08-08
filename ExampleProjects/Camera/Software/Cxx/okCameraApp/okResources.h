/**
	Helpers for loading objects from XRC resources.

	The helper functions defined here all throw an exception if they failed to
	load the object, making it impossible to accidentally forget to check for
	the success of the operation and then crash dereferencing a NULL pointer.
*/

#ifndef __okResources_h__
#define __okResources_h__

#include <stdexcept>

#include <wx/log.h>
#include <wx/xrc/xmlres.h>

#include "okwx.h"

// We can either embed the resources into the executable itself or load them
// from a standalone XRC file. Under Windows, where executable is just a single
// file, we prefer to embed them, except when debugging as being able to modify
// the resources without rebuilding is a huge time saver. Under OS X we can
// just include the resources into the application bundle, so we do it like
// this to avoid problems with wxrc and custom build steps.
#ifndef USE_EMBEDDED_RESOURCES
	#if defined(__WXOSX__)
		#define USE_EMBEDDED_RESOURCES 0
	#elif defined(NDEBUG)
		#define USE_EMBEDDED_RESOURCES 1
	#else
		#define USE_EMBEDDED_RESOURCES 0
	#endif
#endif

#if USE_EMBEDDED_RESOURCES
	// This function should be defined in wxrc-generated resource.cpp.
	extern void InitXmlResource();
#else
	#include <wx/filename.h>
	#include <wx/stdpaths.h>
#endif // NDEBUG

/**
	Contains all helper functions for working with resources.
*/
namespace Resources
{

/**
	Exception thrown when we fail to find something in our resources.
 */
class Exception : public std::runtime_error
{
public:
	/**
		Constructor for an exception thrown during resource loading.
	 */
	Exception(const wxString& str)
		: std::runtime_error(wx2std(str))
	{
	}
};


/**
	Return the global wxXmlResource object.

	Unlike wxXmlResource::Get() this function returns a reference and not a
	pointer because it throws if the pointer is NULL and so can safely
	dereference it.
 */
inline wxXmlResource& Get()
{
	wxXmlResource * const xrc = wxXmlResource::Get();
	if ( !xrc ) {
		throw Exception(_("Resources not available."));
	}

	return *xrc;
}


/**
	Load the given resource file.

	This function is only useful when resources are loaded from files
	instead of being embedded inside the program itself. In the latter case,
	they are all loaded at once by Init() below and this function does nothing.

	Throw if the resource file couldn't be loaded.

	\param name
		The base name (i.e. without the path nor \c .xrc extension) of the
		resource.
 */
inline void LoadFile(const char* name)
{
#if USE_EMBEDDED_RESOURCES
	name; // Suppress unused parameter warnings.
#else // !USE_EMBEDDED_RESOURCES
	wxString dir;
	// Allow overriding the directory containing the resources, this is useful
	// when using the program without installing it first.
	if (!wxGetEnv("okCAMERA_RESOURCES_DIR", &dir)) {
		dir = wxStandardPaths::Get().GetResourcesDir();
	}

	if (!wxFileName::DirExists(dir)) {
		throw Exception(wxString::Format(
					"Resources directory \"%s\" doesn't exist.",
					dir
				));
	}

	wxFileName fn(dir, name, "xrc");

	if (!Get().Load(fn.GetFullPath())) {
		// Not translated, this is used in debug only.
		throw Exception(wxString::Format(
					"Resources file not found.",
					fn.GetFullPath()
				));
	}
#endif // USE_EMBEDDED_RESOURCES/!USE_EMBEDDED_RESOURCES
}


/**
	Initialize the resources on application startup.

	Throws if the main resource file couldn't be loaded.
 */
inline void Init()
{
	wxXmlResource& xrc = Get();
	xrc.InitAllHandlers();

#if USE_EMBEDDED_RESOURCES
	InitXmlResource();
#else // !USE_EMBEDDED_RESOURCES
	LoadFile("resource");
#endif // USE_EMBEDDED_RESOURCES/!USE_EMBEDDED_RESOURCES
}


/**
	Load a frame with the given name from the resources.

	\param frame
		The pointer to the frame being created, notice that it shouldn't have
		been created yet.
	\param name
		The name of the corresponding resource.
 */
inline void LoadFrame(wxFrame *frame, const char *name)
{
	if ( !Get().LoadFrame(frame, NULL, name) ) {
		throw Exception(wxString::Format(
				_("Failed to load the frame \"%s\" from the resources."), name
			));
	}
}

/**
	Load a panel with the given name from the resources.

	\param panel
		The pointer to the panel being created, notice that it shouldn't have
		been created yet.
	\param parent
		The parent for the panel being created, must be non-\c NULL.
	\param name
		The name of the corresponding resource.
 */
inline void LoadPanel(wxPanel *panel, wxWindow* parent, const char *name)
{
	if ( !Get().LoadPanel(panel, parent, name) ) {
		throw Exception(wxString::Format(
				_("Failed to load the panel \"%s\" from the resources."), name
			));
	}
}

/**
	Load a dialog with the given name from the resources.

	\param dlg
		The pointer to the dialog being created, notice that it shouldn't have
		been created yet.
	\param parent
		The parent to use for the new dialog.
	\param name
		The name of the corresponding resource.
 */
inline void LoadDialog(wxDialog *dlg, wxWindow* parent, const char *name)
{
	if ( !Get().LoadDialog(dlg, parent, name) ) {
		throw Exception(wxString::Format(
				_("Failed to load the dialog \"%s\" from the resources."), name
			));
	}
}

/**
	Load a bitmap with the given name from the resources.

	Throws if bitmap couldn't be loaded.

	\param name
		The name of the bitmap in the resource.
 */
inline wxBitmap LoadBitmap(const char* name)
{
	wxBitmap const bmp = Get().LoadBitmap(name);
	if ( !bmp.IsOk() ) {
	throw Exception(wxString::Format(
				_("Failed to load the bitmap \"%s\" from the resources."), name
			));
	}

	return bmp;
}

/**
	Load an icon with the given name from the resources.

	Throws if icon couldn't be loaded.

	\param name
		The name of the icon in the resource.
 */
inline wxIcon LoadIcon(const char* name)
{
	wxIcon const icon = Get().LoadIcon(name);
	if ( !icon.IsOk() ) {
		throw Exception(wxString::Format(
				_("Failed to load the icon \"%s\" from the resources."), name
			));
	}

	return icon;
}

/**
	Load arbitrary object from the resources.

	This can be used for any kind of objects, including those for which
	wxXmlResource provides specific methods (such as LoadToolBar()) and others
	for which it does not (e.g. wxHtmlWindow).

	\param parent
		The parent window to use when creating the object being loaded.
	\param name
		The name of the corresponding resource.
 */
template <class T>
inline T *Load(wxWindow *parent, const char *name)
{
	wxString const classname = CLASSINFO(T)->GetClassName();

	wxObject* const obj = Get().LoadObject(parent, name, classname);
	if ( !obj ) {
		throw Exception(wxString::Format(
				_("Failed to load %s \"%s\" from the resources."),
				classname, name
			));
	}

	T* const tobj = dynamic_cast<T*>(obj);
	if ( !tobj ) {
		throw Exception(wxString::Format(
				_("Resource object \"%s\" is not a %s"),
				name, classname
			));
	}

	return tobj;
}

/**
	Load a sub-classed object from the resources.

	This should be used with resource elements using XRC \c subclass attribute.

	Throws if the element couldn't be loaded or was not of the correct type.

	Template parameters:
		- T the base class of the object, i.e. the value of \c class XRC
		attribute.
		- U the real class of the object, i.e. the value of \c subclass XRC
		attribute (must inherit from T).
 */
template <class T, class U>
inline U* LoadSubclassed(wxWindow* parent, char const* name)
{
	T* const tobj = Load<T>(parent, name);

	U* const uobj = dynamic_cast<U*>(tobj);
	if ( !uobj ) {
		throw Exception(wxString::Format(
				_("Resource object \"%s\" is a %s but not a %s"),
				name,
				CLASSINFO(T)->GetClassName(),
				CLASSINFO(U)->GetClassName()
			));
	}

	return uobj;
}

/**
	Return a pointer to the control with the given name inside a parent window
	loaded from the resources.

	\param parent
		The parent window, must not be NULL.
	\param name
		The name, or id, of the corresponding resource.
	\return
		The loaded object, the returned pointer is never NULL.
 */
template <class T>
T *Find(const wxWindow *parent, const char *name)
{
	wxWindow * const win = parent->FindWindow(XRCID(name));
	if ( !win ) {
		throw Exception(wxString::Format(
				_("Control \"%s\" not found in the resources."), name
			));
	}

	T * const ctrl = dynamic_cast<T *>(win);
	if ( !ctrl ) {
		throw Exception(wxString::Format(
				_("Control \"%s\" is not of type %s"),
				name, CLASSINFO(T)->GetClassName()
			));
	}

	return ctrl;
}

} // namespace Resources

#endif // __okResources_h__
