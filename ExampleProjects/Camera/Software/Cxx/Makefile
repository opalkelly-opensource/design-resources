# Directory used for all binaries under Linux and for the command line tool
# under macOS (the GUI tool uses a bundle there).
BINDIR := bin

COMMON_LIB := okCameraCommon.a
CAMERA_APP := okCameraApp
SNAP_APP_BIN := $(BINDIR)/okSnapApp

COMMON_OBJECTS := \
	i2c_api.o \
	okCCamera.o

CAMERA_OBJECTS := \
	okCameraApp.o \
	okCBitmapListDecoder.o \
	okCThreadCamera.o \
	okCViewport.o

SNAP_OBJECTS := \
	okSnapApp.o

# Compilation flags can be overridden from the command line, but are set
# appropriately depending on whether DEBUG=1 was specified on make command line
# or not by default.
ifeq ($(DEBUG),1)
CXXFLAGS := -g
LDFLAGS := -g
else
CXXFLAGS := -O2
endif

# Always use C++14: we require at least it and we don't want to accidentally
# use features added in later language versions that would break building with
# older compilers.
override CXXFLAGS += -std=c++14

# Set this to the path to a directory containing okFrontPanel.h and
# libokFrontPanel shared library.
okFP_SDK := .

WX_CONFIG := wx-config

ALL_CXXFLAGS := $(CXXFLAGS) $(shell $(WX_CONFIG) --cxxflags) -I$(okFP_SDK) -I./Common
ALL_LDFLAGS := $(LDFLAGS) $(shell $(WX_CONFIG) --libs base,core,xrc,xml,gl,html) -L$(okFP_SDK) -lokFrontPanel

ICON_DIR := okCameraApp/icon

.SUFFIXES: .o .cpp

ifneq ($(DEBUG),1)
ALL_CXXFLAGS += -DNDEBUG
endif

ifeq ($(shell uname),Darwin)
BUNDLE := $(BINDIR)/$(CAMERA_APP).app

CREATE_LIB := libtool -o

ARCHS ?= x86_64
ARCHFLAGS := $(foreach arch,$(ARCHS),-arch $(arch))
ALL_CXXFLAGS += $(ARCHFLAGS)
ALL_LDFLAGS += $(ARCHFLAGS)

CAMERA_APP_BIN := $(BUNDLE)/Contents/MacOS/$(CAMERA_APP)
else
# We never use embedded resources under Mac (they are just included in the
# bundle), but we do embed them in release builds under Linux.
ifneq ($(DEBUG),1)
USE_EMBEDDED_RESOURCES = 1
endif

CREATE_LIB := $(AR) rcs

ALL_LDFLAGS += -lGL

CAMERA_APP_BIN := $(BINDIR)/$(CAMERA_APP)
endif

all: $(CAMERA_APP_BIN) $(SNAP_APP_BIN)

XRC_FILE := okCameraApp/resource.xrc

ifeq ($(USE_EMBEDDED_RESOURCES),1)
WXRC := $(shell $(WX_CONFIG) --utility=wxrc)
CAMERA_OBJECTS += resource.o

GENERATED_RESOURCE_FILE := okCameraApp/resource.cpp

$(GENERATED_RESOURCE_FILE): $(XRC_FILE)
	@if [ -z "$(WXRC)" ]; then \
	    echo wxrc required but not found, please check WX_CONFIG setting; \
	    exit 1; \
	fi
	$(WXRC) -c -o $@ $(XRC_FILE)
endif

$(COMMON_OBJECTS): %.o: Common/%.cpp
	$(CXX) $(ALL_CXXFLAGS) -c $<
$(CAMERA_OBJECTS): %.o: okCameraApp/%.cpp
	$(CXX) $(ALL_CXXFLAGS) -c $<
$(SNAP_OBJECTS): %.o: okSnapApp/%.cpp
	$(CXX) $(ALL_CXXFLAGS) -c $<

$(COMMON_LIB): $(COMMON_OBJECTS)
	$(CREATE_LIB) $@ $^

ifdef BUNDLE
$(BUNDLE)/Contents/MacOS/$(CAMERA_APP): $(COMMON_LIB) $(CAMERA_OBJECTS) $(BUNDLE)
	$(CXX) -o $(BUNDLE)/Contents/MacOS/$(CAMERA_APP) $(CAMERA_OBJECTS) $(COMMON_LIB) $(ALL_LDFLAGS)
	otool -DX $(BUNDLE)/Contents/SharedSupport/libokFrontPanel.dylib
	install_name_tool -id "@executable_path/../SharedSupport/libokFrontPanel.dylib" $(BUNDLE)/Contents/SharedSupport/libokFrontPanel.dylib
	install_name_tool -change libokFrontPanel.dylib "@executable_path/../SharedSupport/libokFrontPanel.dylib" $(BUNDLE)/Contents/MacOS/okCameraApp

$(BUNDLE): okCameraApp/Info.plist
	mkdir -p $(BUNDLE)/Contents
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	mkdir -p $(BUNDLE)/Contents/Resources/logo
	mkdir -p $(BUNDLE)/Contents/SharedSupport
	cp $< $(BUNDLE)/Contents
	cp $(okFP_SDK)/libokFrontPanel.dylib $(BUNDLE)/Contents/SharedSupport
	cp $(XRC_FILE) $(BUNDLE)/Contents/Resources
	cp okCameraApp/okApp.icns $(BUNDLE)/Contents/Resources
	cp -r okCameraApp/logo $(BUNDLE)/Contents/Resources

clean:
	rm -f $(COMMON_OBJECTS) $(COMMON_LIB) $(CAMERA_OBJECTS) $(SNAP_OBJECTS) $(SNAP_APP_BIN)
	rm -rf $(BUNDLE)

# This target may be used to recreate okApp.icns if the PNG images change.
#
# It requires iconutil which is only available under macOS.
okCameraApp/okApp.icns: $(wildcard $(ICON_DIR)/*.png)
	@mkdir -p okApp.iconset
	cp $(ICON_DIR)/icon-16.png   okApp.iconset/icon_16x16.png
	cp $(ICON_DIR)/icon-32.png   okApp.iconset/icon_16x16@2x.png
	cp $(ICON_DIR)/icon-32.png   okApp.iconset/icon_32x32.png
	cp $(ICON_DIR)/icon-64.png   okApp.iconset/icon_32x32@2x.png
	cp $(ICON_DIR)/icon-128.png  okApp.iconset/icon_128x128.png
	cp $(ICON_DIR)/icon-256.png  okApp.iconset/icon_128x128@2x.png
	cp $(ICON_DIR)/icon-256.png  okApp.iconset/icon_256x256.png
	cp $(ICON_DIR)/icon-512.png  okApp.iconset/icon_256x256@2x.png
	cp $(ICON_DIR)/icon-512.png  okApp.iconset/icon_512x512.png
	cp $(ICON_DIR)/icon-1024.png okApp.iconset/icon_512x512@2x.png
	iconutil --convert icns --output $@ okApp.iconset
	@rm -rf okApp.iconset
else
$(BINDIR)/$(CAMERA_APP): $(COMMON_LIB) $(CAMERA_OBJECTS)
	@mkdir -p $(BINDIR)
	$(CXX) -o $@ $(CAMERA_OBJECTS) $(COMMON_LIB) $(ALL_LDFLAGS)

clean:
	$(RM) $(COMMON_OBJECTS) $(COMMON_LIB) $(CAMERA_OBJECTS) $(GENERATED_RESOURCE_FILE) $(SNAP_OBJECTS) $(SNAP_APP_BIN)
	$(RM) $(BINDIR)/$(CAMERA_APP)
	@$(RM) -r $(BINDIR)
endif

# This target can be used to update the MSW icon and requires ImageMagick
# convert program, which can be installed under any platform.
CONVERT := convert

okCameraApp/okApp.ico: $(wildcard $(ICON_DIR)/*.png)
	$(CONVERT) $(addsuffix .png, $(addprefix $(ICON_DIR)/icon-,16 24 32 48 256)) $@

$(SNAP_APP_BIN): $(COMMON_LIB) $(SNAP_OBJECTS)
	@mkdir -p $(BINDIR)
	$(CXX) -o $@ $(SNAP_OBJECTS) $(COMMON_LIB) $(ALL_LDFLAGS)

.PHONY: all clean
