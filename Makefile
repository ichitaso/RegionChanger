DEBUG = 0
FINALPACKAGE = 1
GO_EASY_ON_ME := 1

ARCHS = arm64

TARGET := iphone:clang:15.5:13.0
MIN_IOS_SDK_VERSION = 11.0

THEOS_DEVICE_IP = 192.168.0.8

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

before-package::
	sudo chown -R root:wheel $(THEOS_STAGING_DIR)
	sudo chmod -R 755 $(THEOS_STAGING_DIR)
	sudo chmod 6755 $(THEOS_STAGING_DIR)/Applications/RegionChanger.app/RegionChanger
	sudo chmod 666 $(THEOS_STAGING_DIR)/DEBIAN/control

after-package::
	make clean
	sudo rm -rf .theos/_

after-install::
	install.exec "uicache -p /Applications/RegionChanger.app"
