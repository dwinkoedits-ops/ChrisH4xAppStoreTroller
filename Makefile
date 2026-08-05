# Décommente cette ligne si tu veux forcer la compilation Rootless par défaut
# THEOS_PACKAGE_SCHEME = rootless

ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:12.0
INSTALL_TARGET_PROCESSES = AppStore Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChrisH4xAppStoreTroller

ChrisH4xAppStoreTroller_FILES = Tweak.x
ChrisH4xAppStoreTroller_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
