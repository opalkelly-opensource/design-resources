#
# This file is the set-clock-ecm1900 recipe.
#

SUMMARY = "Simple set-clock-ecm1900 application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://set-clock-ecm1900.cpp \
	   file://ECM1900-Si5341-Regs.h \
           file://Makefile \
		  "

S = "${WORKDIR}"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install -m 0755 set-clock-ecm1900 ${D}${bindir}
	     install -d ${D}/home/root/tools/set-clock-ecm1900
	     install -m 0755 set-clock-ecm1900.cpp ${D}/home/root/tools/set-clock-ecm1900
	     install -m 0755 ECM1900-Si5341-Regs.h ${D}/home/root/tools/set-clock-ecm1900
	     install -m 0755 Makefile ${D}/home/root/tools/set-clock-ecm1900
}
FILES_${PN} += "/home/root/*"
