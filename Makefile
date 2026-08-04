export THEOS_DEVICE_IP ?= localhost

# ── Auto-detect Theos location (rootless → rootful → ~/theos fallback) ────────
ifeq ($(wildcard /var/jb/opt/theos),/var/jb/opt/theos)
  export THEOS ?= /var/jb/opt/theos
else ifeq ($(wildcard /opt/theos),/opt/theos)
  export THEOS ?= /opt/theos
else
  export THEOS ?= $(HOME)/theos
endif

TARGET := iphone:clang:latest:5.0
ARCHS  := arm arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChrisH4xAppStoreTroller

ChrisH4xAppStoreTroller_FILES               = Tweak.x
ChrisH4xAppStoreTroller_CFLAGS              = -fobjc-arc
ChrisH4xAppStoreTroller_FRAMEWORKS          = UIKit Foundation
ChrisH4xAppStoreTroller_PRIVATE_FRAMEWORKS  = AppSupport MobileContainerManager

# ── Universal install path ────────────────────────────────────────────────────
# Le .dylib atterrit dans un dossier neutre accessible sur ROOTFUL et ROOTLESS.
# Le script postinst détecte le type de jailbreak et crée les symlinks
# dans le bon dossier MobileSubstrate automatiquement.
# → Un seul .deb pour tout le monde, pas besoin de THEOS_PACKAGE_SCHEME.
ChrisH4xAppStoreTroller_INSTALL_PATH = /var/mobile/Library/Application Support/ChrisH4xAppStoreTroller

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 'App Store' MobileStorePurchaseService com.apple.appstored storedownloadd 2>/dev/null; true"
