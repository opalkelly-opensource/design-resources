#
# This file is the syzygy-ecm1900 recipe.
#

SUMMARY = "Simple syzygy-ecm1900 application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://syzygy-ecm1900.cpp \
	   file://syzygy.c \
	   file://syzygy.h \
	   file://json.hpp \
           file://Makefile \
		  "

S = "${WORKDIR}"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 syzygy-ecm1900 ${D}${bindir}
}
