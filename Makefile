DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64

TARGET := iphone:clang:16.2:15.0
MIN_IOS_SDK_VERSION = 11.0

THEOS_DEVICE_IP = 192.168.0.11

APPLICATION_NAME = RegionChanger
$(APPLICATION_NAME)_FILES = main.m RootViewController.m
$(APPLICATION_NAME)_FRAMEWORKS = UIKit CoreGraphics Foundation CoreFoundation SafariServices IOKit
$(APPLICATION_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(APPLICATION_NAME)_CFLAGS = -fobjc-arc
$(APPLICATION_NAME)_CODESIGN_FLAGS = -Sent.xml

SUBPROJECTS += postrm

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/application.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	mv -f $(THEOS_STAGING_DIR)/tmp/postrm ./layout/DEBIAN/postrm
	rm -rf $(THEOS_STAGING_DIR)/tmp

after-package::
	rm -f ./layout/DEBIAN/postrm
