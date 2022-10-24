#
# This file is the device-sensors recipe.
#

SUMMARY = "Simple device-sensors application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://device-sensors.py \
	"

S = "${WORKDIR}"

do_install() {
	     install -d ${D}/home/root/tools/device-sensors
	     install -m 0755 device-sensors.py ${D}/home/root/tools/device-sensors
}
FILES_${PN} += "/home/root/*"

