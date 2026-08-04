TARGET := iphone:clang:latest:5.0
ARCHS := arm arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ChrisH4xAppStoreTrollerPrefs
ChrisH4xAppStoreTrollerPrefs_FILES = CHXPreferencesController.m
ChrisH4xAppStoreTrollerPrefs_INSTALL_PATH = /Library/PreferenceLoader/Preferences
ChrisH4xAppStoreTrollerPrefs_FRAMEWORKS = UIKit Foundation
ChrisH4xAppStoreTrollerPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
