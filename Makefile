export THEOS_PACKAGE_SCHEME = rootful
ARCHS = armv7 armv7s
# On baisse le target pour correspondre aux appareils 32 bits (iOS 10 maximum en général)
TARGET := iphone:clang:latest:10.0
INSTALL_TARGET_PROCESSES = AppStore Preferences SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChrisH4xAppStoreTroller

ChrisH4xAppStoreTroller_FILES = Tweak.x
ChrisH4xAppStoreTroller_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
