#
# This file is the fan-control recipe.
#

SUMMARY = "Simple fan-control application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://fan-control.py \
	"

S = "${WORKDIR}"

do_install() {
	     install -d ${D}/home/root/tools/fan-control
	     install -m 0755 fan-control.py ${D}/home/root/tools/fan-control
}
FILES_${PN} += "/home/root/*"

